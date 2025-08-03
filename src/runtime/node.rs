use super::Runtime;
use crate::utils::download::{download_and_extract, get_architecture};
use crate::utils::error::{Result, RvmError};
use crate::utils::profile::{add_runtime_to_path, reload_profile};
use crate::utils::version::is_version_installed;
use reqwest::blocking;
use serde::Deserialize;

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
    fn install(&self, version: Option<&str>) -> Result<()> {
        let version_str = version.unwrap_or("latest");
        println!("Installing Node.js version: {}", version_str);

        // Step 1: Parse and resolve version
        let resolved_version = self.resolve_version(version_str)?;

        // Step 2: Check if already installed
        if is_version_installed("node", &resolved_version)? {
            return Err(RvmError::VersionAlreadyInstalled(resolved_version));
        }

        // Step 3: Download and extract
        let arch = get_architecture()?;
        let filename = format!("node-{}-linux-{}.tar.xz", resolved_version, arch);
        let download_url = format!("https://nodejs.org/dist/{}/{}", resolved_version, filename);

        download_and_extract(
            &download_url,
            "node",
            &resolved_version,
            &["bin/node", "bin/npm"], // Make node and npm executable
        )?;

        // Step 4: Add to PATH in .profile
        add_runtime_to_path("node", &resolved_version)?;

        // Step 5: Automatically reload profile
        reload_profile()?;

        println!("✅ Node.js {} installation completed", resolved_version);

        Ok(())
    }

    fn remove(&self, version: Option<&str>) -> Result<()> {
        match version {
            Some(v) => println!("Removing Node.js version: {}", v),
            None => println!("Removing all Node.js versions"),
        }
        // TODO: Implement actual Node.js removal
        Ok(())
    }

    fn update(&self) -> Result<()> {
        println!("Updating Node.js to latest version");
        // TODO: Implement actual Node.js update
        Ok(())
    }

    fn prune(&self, keep_version: &str) -> Result<()> {
        println!("Pruning Node.js versions older than: {}", keep_version);
        // TODO: Implement actual Node.js pruning
        Ok(())
    }

    fn set_default(&self, version: &str) -> Result<()> {
        println!("Setting Node.js {} as default", version);
        // TODO: Implement actual default setting
        Ok(())
    }

    fn use_version(&self, version: &str) -> Result<()> {
        println!("Using Node.js {} for current session", version);
        // TODO: Implement actual version switching
        Ok(())
    }

    fn list_installed(&self) -> Result<Vec<String>> {
        use crate::utils::version::get_runtime_home;
        use std::fs;
        
        let node_home = get_runtime_home("node")?;
        let mut installed_versions = Vec::new();
        
        if node_home.exists() {
            for entry in fs::read_dir(&node_home)? {
                let entry = entry?;
                let path = entry.path();
                
                if path.is_dir() {
                    if let Some(version_name) = path.file_name() {
                        let version_str = version_name.to_string_lossy().to_string();
                        // Check if it's a valid Node.js installation by looking for the node binary
                        let node_binary = path.join("bin").join("node");
                        if node_binary.exists() {
                            installed_versions.push(version_str);
                        }
                    }
                }
            }
        }
        
        // Sort versions (newest first, similar to how Node.js API returns them)
        installed_versions.sort_by(|a, b| b.cmp(a));
        
        Ok(installed_versions)
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

    fn get_current_version(&self) -> Result<Option<String>> {
        println!("Getting current Node.js version");
        // TODO: Implement actual current version detection
        Ok(Some("20.11.0".to_string()))
    }

    fn name(&self) -> &str {
        "node"
    }

    fn binary_name(&self) -> &str {
        "node"
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
