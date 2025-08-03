use super::Runtime;
use crate::utils::download::{download_and_extract, get_architecture};
use crate::utils::error::{Result, RvmError};
use crate::utils::profile::{add_runtime_to_path, reload_profile, set_default_runtime, remove_runtime_from_path};
use crate::utils::ui::{display_step, display_success, display_error};
use crate::utils::version::{is_version_installed, get_runtime_home, remove_version, list_installed_versions, resolve_installed_version, apply_version_to_current_session};
use reqwest::blocking;
use serde::Deserialize;
use std::os::unix::fs::PermissionsExt;

/// Node.js runtime manager
pub struct NodeRuntime;

#[derive(Deserialize)]
struct NodeRelease {
    version: String,
    date: String,
    files: Vec<String>,
    npm: Option<String>,
    lts: serde_json::Value, // Can be false or a string
}

impl NodeRuntime {
    /// Parse the API response into Node.js specific release data
    fn parse_api_response(json_data: &serde_json::Value) -> Result<Vec<NodeRelease>> {
        let releases: Vec<NodeRelease> = serde_json::from_value(json_data.clone())?;
        Ok(releases)
    }
    
}

impl Runtime for NodeRuntime {
    fn add(&self, version: Option<&str>) -> Result<()> {
        let version_str = version.unwrap_or("latest");
        display_step(&format!("Adding Node.js version: {}", version_str));

        // Step 1: Parse and resolve version
        display_step("Resolving version from Node.js API");
        let resolved_version = self.resolve_version(version_str)?;
        display_success(&format!("Resolved to version: {}", resolved_version));

        // Step 2: Check if already installed (has built-in messaging)
        if is_version_installed("node", &resolved_version)? {
            return Err(RvmError::VersionAlreadyInstalled(resolved_version));
        }

        // Step 3: Download and extract (has built-in messaging)
        let arch = get_architecture()?;
        let filename = format!("node-{}-linux-{}.tar.xz", resolved_version, arch);
        let download_url = format!("https://nodejs.org/dist/{}/{}", resolved_version, filename);

        download_and_extract(
            &download_url,
            "node",
            &resolved_version,
            &["bin/node", "bin/npm"], // Make node and npm executable
        )?;

        // Step 4: Set as default (has built-in messaging)
        set_default_runtime("node", &resolved_version)?;

        // Step 5: Automatically reload profile (has built-in messaging)
        reload_profile()?;

        display_success(&format!("Node.js {} installation completed successfully!", resolved_version));
        Ok(())
    }

    fn remove(&self, version: Option<&str>) -> Result<()> {
        match version {
            Some(v) => {
                display_step(&format!("Removing Node.js version: {}", v));
                
                // Check if version is installed
                if !is_version_installed("node", v)? {
                    display_error(&format!("Node.js {} is not installed", v));
                    return Err(RvmError::VersionNotFound(v.to_string()));
                }
                
                // Remove from PATH in profile
                remove_runtime_from_path("node", v)?;
                
                // Remove from filesystem (has built-in messaging)
                remove_version("node", v)?;
                
                // Reload profile to apply changes
                reload_profile()?;
                
                display_success(&format!("Node.js {} removed successfully", v));
            }
            None => {
                display_step("Removing all Node.js versions");
                
                // Get list of installed versions
                let installed_versions = list_installed_versions("node")?;
                
                if installed_versions.is_empty() {
                    display_success("No Node.js versions are installed");
                    return Ok(());
                }
                
                display_step(&format!("Found {} Node.js versions to remove", installed_versions.len()));
                
                // Remove each version
                for version in &installed_versions {
                    display_step(&format!("Removing Node.js {}", version));
                    remove_runtime_from_path("node", version)?;
                    remove_version("node", version)?;
                }
                
                // Clean up the entire node directory if it's empty
                let runtime_home = get_runtime_home("node")?;
                if runtime_home.exists() {
                    match std::fs::read_dir(&runtime_home) {
                        Ok(mut entries) => {
                            if entries.next().is_none() {
                                display_step("Cleaning up empty Node.js directory");
                                std::fs::remove_dir(&runtime_home)?;
                                display_success("Removed empty Node.js directory");
                            }
                        }
                        Err(_) => {} // Directory doesn't exist or can't read, skip cleanup
                    }
                }
                
                // Reload profile to apply changes
                reload_profile()?;
                
                display_success(&format!("Removed all {} Node.js versions successfully", installed_versions.len()));
            }
        }
        Ok(())
    }

    fn update(&self) -> Result<()> {
        display_step("Updating Node.js to latest version");
        
        // Get the latest version from the API
        let latest_version = self.resolve_version("latest")?;
        display_success(&format!("Latest Node.js version is: {}", latest_version));
        
        // Check if it's already installed
        if is_version_installed("node", &latest_version)? {
            display_success(&format!("Node.js {} is already installed", latest_version));
            
            // Set it as default if it's not already
            display_step("Ensuring latest version is set as default");
            set_default_runtime("node", &latest_version)?;
            reload_profile()?;
            
            display_success("Node.js is already up to date");
            return Ok(());
        }
        
        // Install the latest version using the add function
        display_step(&format!("Installing Node.js {}", latest_version));
        self.add(Some("latest"))?;
        
        display_success(&format!("Successfully updated Node.js to {}", latest_version));
        Ok(())
    }

    fn prune(&self, keep_version: &str) -> Result<()> {
        display_step(&format!("Pruning Node.js versions (keeping {})", keep_version));
        
        // Resolve the version to keep (e.g., "18" -> "v18.20.0")
        let resolved_keep_version = resolve_installed_version("node", keep_version)?;
        display_success(&format!("Will keep Node.js version: {}", resolved_keep_version));
        
        // Get list of all installed versions
        let installed_versions = list_installed_versions("node")?;
        
        if installed_versions.is_empty() {
            display_success("No Node.js versions are installed");
            return Ok(());
        }
        
        // Filter out the version to keep
        let versions_to_remove: Vec<String> = installed_versions
            .into_iter()
            .filter(|v| *v != resolved_keep_version)
            .collect();
        
        if versions_to_remove.is_empty() {
            display_success(&format!("Only {} is installed, nothing to prune", resolved_keep_version));
            return Ok(());
        }
        
        display_step(&format!("Found {} Node.js versions to remove", versions_to_remove.len()));
        
        // Remove each version except the one to keep
        for version in &versions_to_remove {
            display_step(&format!("Removing Node.js {}", version));
            
            // Remove from PATH in profile
            remove_runtime_from_path("node", version)?;
            
            // Remove from filesystem
            remove_version("node", version)?;
        }
        
        // Ensure the version to keep is set as default
        display_step(&format!("Setting {} as default", resolved_keep_version));
        set_default_runtime("node", &resolved_keep_version)?;
        
        // Reload profile to apply changes
        reload_profile()?;
        
        display_success(&format!("Pruned {} Node.js versions, kept {}", versions_to_remove.len(), resolved_keep_version));
        Ok(())
    }

    fn set_default(&self, version: &str) -> Result<()> {
        display_step(&format!("Setting Node.js {} as default", version));
        
        // Resolve version first (e.g., "18" -> "v18.20.0")
        let resolved_version = resolve_installed_version("node", version)?;
        display_success(&format!("Resolved to installed version: {}", resolved_version));
        
        // Set as default (has built-in messaging)
        set_default_runtime("node", &resolved_version)?;
        
        // Reload profile (has built-in messaging)
        reload_profile()?;
        
        // Force reload current environment
        display_step("Applying changes to current session");
        apply_version_to_current_session("node", &resolved_version, "node")?;
        
        display_success(&format!("Node.js {} is now the default version", resolved_version));
        Ok(())
    }

    fn use_version(&self, version: &str) -> Result<()> {
        display_step(&format!("Switching to Node.js {} for current session", version));
        
        // Resolve version first (e.g., "18" -> "v18.20.0")
        let resolved_version = resolve_installed_version("node", version)?;
        display_success(&format!("Resolved to installed version: {}", resolved_version));
        
        // Apply version to current session
        display_step("Applying changes to current session");
        apply_version_to_current_session("node", &resolved_version, "node")?;
        
        display_success(&format!("Node.js {} is now active in current session", resolved_version));
        println!("💡 This change is temporary. To make it permanent, run:");
        println!("   rvm set node {}", version);
        Ok(())
    }

    fn list_installed(&self) -> Result<Vec<String>> {
        list_installed_versions("node")
    }

    fn list_available(&self) -> Result<Vec<String>> {
        use crate::utils::version::{VersionInfo, detect_channel, extract_major_minor, group_versions_by_channel};
        
        let json_data = self.fetch_available_versions()?;
        let releases = Self::parse_api_response(&json_data)?;
        
        // Convert releases to VersionInfo with channel detection
        let mut version_infos = Vec::new();
        for release in releases {
            if let Some(major_minor) = extract_major_minor(&release.version) {
                let is_lts = !release.lts.is_boolean() || release.lts.as_bool() != Some(false);
                let channel = detect_channel(&release.version, is_lts);
                
                version_infos.push(VersionInfo {
                    version: release.version,
                    channel,
                    major_minor,
                });
            }
        }
        
        // Group by channel and format for display
        let grouped_versions = group_versions_by_channel(version_infos);
        Ok(grouped_versions)
    }


    fn fetch_available_versions(&self) -> Result<serde_json::Value> {
        let response = blocking::get("https://nodejs.org/dist/index.json")?;
        let json_data: serde_json::Value = response.json()?;
        Ok(json_data)
    }

    fn resolve_version(&self, version_input: &str) -> Result<String> {
        let json_data = self.fetch_available_versions()?;
        let available_versions = Self::parse_api_response(&json_data)?;

        match version_input {
            "latest" => {
                // Get the latest stable version (first in the list)
                available_versions
                    .first()
                    .map(|r| r.version.clone())
                    .ok_or_else(|| RvmError::VersionNotFound("latest".to_string()))
            }
            "lts" => {
                // Get the latest LTS version
                available_versions
                    .iter()
                    .find(|r| !r.lts.is_boolean() || r.lts.as_bool() != Some(false))
                    .map(|r| r.version.clone())
                    .ok_or_else(|| RvmError::VersionNotFound("lts".to_string()))
            }
            v if v.chars().all(|c| c.is_ascii_digit()) => {
                // Major version only (e.g., "20")
                let target_major = format!("v{}", v);
                available_versions
                    .iter()
                    .find(|r| r.version.starts_with(&target_major))
                    .map(|r| r.version.clone())
                    .ok_or_else(|| RvmError::VersionNotFound(v.to_string()))
            }
            v if v.matches('.').count() == 1 => {
                // Major.minor version (e.g., "20.11")
                let target_prefix = if v.starts_with('v') {
                    v.to_string()
                } else {
                    format!("v{}", v)
                };
                available_versions
                    .iter()
                    .find(|r| r.version.starts_with(&target_prefix))
                    .map(|r| r.version.clone())
                    .ok_or_else(|| RvmError::VersionNotFound(v.to_string()))
            }
            v => {
                // Specific version (e.g., "20.11.0" or "20.11.0-beta.1")
                let target_version = if v.starts_with('v') {
                    v.to_string()
                } else {
                    format!("v{}", v)
                };
                available_versions
                    .iter()
                    .find(|r| r.version == target_version)
                    .map(|r| r.version.clone())
                    .ok_or_else(|| RvmError::VersionNotFound(v.to_string()))
            }
        }
    }
}
