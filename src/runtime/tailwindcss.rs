use super::Runtime;
use crate::utils::download::get_architecture;
use crate::utils::error::{Result, RvmError};
use crate::utils::profile::{reload_profile, remove_runtime_from_path, set_default_runtime};
use crate::utils::ui::{display_error, display_step, display_success};
use crate::utils::version::{
    apply_version_to_current_session, get_runtime_home, is_version_installed,
    list_installed_versions, remove_version, resolve_installed_version,
};
use reqwest::blocking;
use serde::Deserialize;

/// TailwindCSS runtime manager
pub struct TailwindCssRuntime;

#[derive(Deserialize)]
struct GitHubRelease {
    tag_name: String,
    prerelease: bool,
}

impl TailwindCssRuntime {
    /// Parse the GitHub releases API response
    fn parse_api_response(json_data: &serde_json::Value) -> Result<Vec<GitHubRelease>> {
        let releases: Vec<GitHubRelease> = serde_json::from_value(json_data.clone())?;
        Ok(releases)
    }

    /// Get the executable filename for the current architecture
    fn get_executable_filename(&self, arch: &str) -> Result<String> {
        let tailwind_arch = match arch {
            "x64" => "linux-x64",
            "arm64" => "linux-arm64",
            _ => return Err(RvmError::UnsupportedArchitecture(arch.to_string())),
        };
        Ok(format!("tailwindcss-{}", tailwind_arch))
    }
}

impl Runtime for TailwindCssRuntime {
    fn add(&self, version: Option<&str>) -> Result<()> {
        let version_str = version.unwrap_or("latest");
        display_step(&format!("Adding TailwindCSS version: {}", version_str));

        // Step 1: Parse and resolve version
        display_step("Resolving version from GitHub releases API");
        let resolved_version = self.resolve_version(version_str)?;
        display_success(&format!("Resolved to version: {}", resolved_version));

        // Step 2: Check if already installed
        if is_version_installed("tailwindcss", &resolved_version)? {
            return Err(RvmError::VersionAlreadyInstalled(resolved_version));
        }

        // Step 3: Download the standalone executable
        let arch = get_architecture()?;
        let executable_filename = self.get_executable_filename(&arch)?;
        let download_url = format!(
            "https://github.com/tailwindlabs/tailwindcss/releases/download/{}/{}",
            resolved_version, executable_filename
        );

        display_step(&format!("Downloading TailwindCSS {} executable", resolved_version));

        // Create the runtime directory structure
        let runtime_home = get_runtime_home("tailwindcss")?;
        let version_dir = runtime_home.join(&resolved_version).join("bin");
        std::fs::create_dir_all(&version_dir)?;

        // Download the executable directly
        let client = blocking::Client::new();
        let response = client.get(&download_url).send()?;

        if !response.status().is_success() {
            return Err(RvmError::HttpError(format!(
                "Failed to download TailwindCSS {}: {}",
                resolved_version, response.status()
            )));
        }

        let executable_path = version_dir.join("tailwindcss");
        let executable_bytes = response.bytes()?;
        std::fs::write(&executable_path, executable_bytes)?;

        // Make executable
        #[cfg(unix)]
        {
            use std::os::unix::fs::PermissionsExt;
            let mut perms = std::fs::metadata(&executable_path)?.permissions();
            perms.set_mode(0o755); // rwxr-xr-x
            std::fs::set_permissions(&executable_path, perms)?;
        }

        display_success(&format!("Downloaded TailwindCSS {} executable", resolved_version));

        // Step 4: Set as default
        set_default_runtime("tailwindcss", &resolved_version)?;

        // Step 5: Automatically reload profile
        reload_profile()?;

        display_success(&format!("TailwindCSS {} installation completed successfully!", resolved_version));
        Ok(())
    }

    fn remove(&self, version: Option<&str>) -> Result<()> {
        match version {
            Some(v) => {
                display_step(&format!("Removing TailwindCSS version: {}", v));

                // Check if version is installed
                if !is_version_installed("tailwindcss", v)? {
                    display_error(&format!("TailwindCSS {} is not installed", v));
                    return Err(RvmError::VersionNotFound(v.to_string()));
                }

                // Remove from PATH in profile
                remove_runtime_from_path("tailwindcss", v)?;

                // Remove from filesystem
                remove_version("tailwindcss", v)?;

                // Reload profile to apply changes
                reload_profile()?;

                display_success(&format!("TailwindCSS {} removed successfully", v));
            }
            None => {
                display_step("Removing all TailwindCSS versions");

                // Get list of installed versions
                let installed_versions = list_installed_versions("tailwindcss")?;

                if installed_versions.is_empty() {
                    display_success("No TailwindCSS versions are installed");
                    return Ok(());
                }

                display_step(&format!("Found {} TailwindCSS versions to remove", installed_versions.len()));

                // Remove each version
                for version in &installed_versions {
                    display_step(&format!("Removing TailwindCSS {}", version));
                    remove_runtime_from_path("tailwindcss", version)?;
                    remove_version("tailwindcss", version)?;
                }

                // Clean up the entire tailwindcss directory if it's empty
                let runtime_home = get_runtime_home("tailwindcss")?;
                if runtime_home.exists() {
                    match std::fs::read_dir(&runtime_home) {
                        Ok(mut entries) => {
                            if entries.next().is_none() {
                                display_step("Cleaning up empty TailwindCSS directory");
                                std::fs::remove_dir(&runtime_home)?;
                                display_success("Removed empty TailwindCSS directory");
                            }
                        }
                        Err(_) => {} // Directory doesn't exist or can't read, skip cleanup
                    }
                }

                // Reload profile to apply changes
                reload_profile()?;

                display_success(&format!("Removed all {} TailwindCSS versions successfully", installed_versions.len()));
            }
        }
        Ok(())
    }

    fn update(&self) -> Result<()> {
        display_step("Updating TailwindCSS to latest version");

        // Get the latest version from the API
        let latest_version = self.resolve_version("latest")?;
        display_success(&format!("Latest TailwindCSS version is: {}", latest_version));

        // Check if it's already installed
        if is_version_installed("tailwindcss", &latest_version)? {
            display_success(&format!("TailwindCSS {} is already installed", latest_version));

            // Set it as default if it's not already
            display_step("Ensuring latest version is set as default");
            set_default_runtime("tailwindcss", &latest_version)?;
            reload_profile()?;

            display_success("TailwindCSS is already up to date");
            return Ok(());
        }

        // Install the latest version using the add function
        display_step(&format!("Installing TailwindCSS {}", latest_version));
        self.add(Some("latest"))?;

        display_success(&format!("Successfully updated TailwindCSS to {}", latest_version));
        Ok(())
    }

    fn prune(&self, keep_version: &str) -> Result<()> {
        display_step(&format!("Pruning TailwindCSS versions (keeping {})", keep_version));

        // Resolve the version to keep
        let resolved_keep_version = resolve_installed_version("tailwindcss", keep_version)?;
        display_success(&format!("Will keep TailwindCSS version: {}", resolved_keep_version));

        // Get list of all installed versions
        let installed_versions = list_installed_versions("tailwindcss")?;

        if installed_versions.is_empty() {
            display_success("No TailwindCSS versions are installed");
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

        display_step(&format!("Found {} TailwindCSS versions to remove", versions_to_remove.len()));

        // Remove each version except the one to keep
        for version in &versions_to_remove {
            display_step(&format!("Removing TailwindCSS {}", version));

            // Remove from PATH in profile
            remove_runtime_from_path("tailwindcss", version)?;

            // Remove from filesystem
            remove_version("tailwindcss", version)?;
        }

        // Ensure the version to keep is set as default
        display_step(&format!("Setting {} as default", resolved_keep_version));
        set_default_runtime("tailwindcss", &resolved_keep_version)?;

        // Reload profile to apply changes
        reload_profile()?;

        display_success(&format!("Pruned {} TailwindCSS versions, kept {}", versions_to_remove.len(), resolved_keep_version));
        Ok(())
    }

    fn set_default(&self, version: &str) -> Result<()> {
        display_step(&format!("Setting TailwindCSS {} as default", version));

        // Resolve version first
        let resolved_version = resolve_installed_version("tailwindcss", version)?;
        display_success(&format!("Resolved to installed version: {}", resolved_version));

        // Set as default
        set_default_runtime("tailwindcss", &resolved_version)?;

        // Reload profile
        reload_profile()?;

        // Force reload current environment
        display_step("Applying changes to current session");
        apply_version_to_current_session("tailwindcss", &resolved_version, "tailwindcss")?;

        display_success(&format!("TailwindCSS {} is now the default version", resolved_version));
        Ok(())
    }

    fn use_version(&self, version: &str) -> Result<()> {
        display_step(&format!("Switching to TailwindCSS {} for current session", version));

        // Resolve version first
        let resolved_version = resolve_installed_version("tailwindcss", version)?;
        display_success(&format!("Resolved to installed version: {}", resolved_version));

        // Apply version to current session
        display_step("Applying changes to current session");
        apply_version_to_current_session("tailwindcss", &resolved_version, "tailwindcss")?;

        display_success(&format!("TailwindCSS {} is now active in current session", resolved_version));
        println!("This change is temporary. To make it permanent, run:");
        println!("   rvm set tailwindcss {}", version);
        Ok(())
    }

    fn list_installed(&self) -> Result<Vec<String>> {
        list_installed_versions("tailwindcss")
    }

    fn list_available(&self) -> Result<Vec<String>> {
        let json_data = self.fetch_available_versions()?;
        let releases = Self::parse_api_response(&json_data)?;

        display_step("Organizing versions for display");

        let mut result = Vec::new();

        // Separate stable and pre-release versions
        let mut stable_versions = Vec::new();
        let mut prerelease_versions = Vec::new();

        for release in releases {
            let version = &release.tag_name;

            if release.prerelease {
                prerelease_versions.push(version.clone());
            } else {
                stable_versions.push(version.clone());
            }
        }

        // Display stable versions
        if !stable_versions.is_empty() {
            result.push("=== Stable Versions ===".to_string());

            // Group by major.minor for better display
            let mut major_minor_groups: std::collections::BTreeMap<String, Vec<String>> =
                std::collections::BTreeMap::new();

            for version in &stable_versions {
                let version_clean = version.strip_prefix('v').unwrap_or(&version);
                let parts: Vec<&str> = version_clean.split('.').collect();
                if parts.len() >= 2 {
                    let major_minor = format!("{}.{}", parts[0], parts[1]);
                    major_minor_groups
                        .entry(major_minor)
                        .or_insert_with(Vec::new)
                        .push(version.clone());
                }
            }

            // Sort and display top groups
            let mut sorted_groups: Vec<(String, Vec<String>)> = major_minor_groups.into_iter().collect();
            sorted_groups.sort_by(|a, b| {
                let parse_major_minor = |s: &str| -> (u32, u32) {
                    let parts: Vec<&str> = s.split('.').collect();
                    let major = parts.get(0).and_then(|s| s.parse().ok()).unwrap_or(0);
                    let minor = parts.get(1).and_then(|s| s.parse().ok()).unwrap_or(0);
                    (major, minor)
                };
                let version_a = parse_major_minor(&a.0);
                let version_b = parse_major_minor(&b.0);
                version_b.cmp(&version_a) // Reverse order for newest first
            });

            // Display top 4 major.minor groups
            let mut count = 0;
            for (major_minor, mut versions) in sorted_groups {
                if count >= 4 {
                    break;
                }

                // Sort versions within the group (newest first)
                versions.sort_by(|a, b| {
                    let parse_patch = |v: &str| -> u32 {
                        let version_clean = v.strip_prefix('v').unwrap_or(v);
                        let parts: Vec<&str> = version_clean.split('.').collect();
                        parts.get(2).and_then(|s| s.parse().ok()).unwrap_or(0)
                    };
                    parse_patch(b).cmp(&parse_patch(a))
                });

                let versions_str = versions.join(", ");
                result.push(format!("{}: {}", major_minor, versions_str));
                count += 1;
            }

            result.push("... displaying top 4 versions, all other versions truncated".to_string());
            result.push(String::new()); // Empty line
        }

        // Display pre-release versions if any
        if !prerelease_versions.is_empty() {
            result.push("=== Pre-release Versions ===".to_string());

            // Show only the latest few pre-releases
            let limited_prereleases: Vec<String> = prerelease_versions.into_iter().take(5).collect();
            for version in limited_prereleases {
                result.push(format!("{} (Pre-release)", version));
            }

            result.push("... showing latest 5 pre-release versions".to_string());
        }

        display_success("Successfully retrieved and organized TailwindCSS versions");
        Ok(result)
    }

    fn fetch_available_versions(&self) -> Result<serde_json::Value> {
        display_step("Fetching TailwindCSS versions from GitHub releases API");

        let url = "https://api.github.com/repos/tailwindlabs/tailwindcss/releases";
        let client = blocking::Client::new();
        let response = client
            .get(url)
            .header("User-Agent", "rvm-rust/1.0.0")
            .send()?;

        if !response.status().is_success() {
            return Err(RvmError::HttpError(format!(
                "Failed to fetch TailwindCSS releases: {}",
                response.status()
            )));
        }

        let json_data: serde_json::Value = response.json()?;
        Ok(json_data)
    }

    fn resolve_version(&self, version_input: &str) -> Result<String> {
        let json_data = self.fetch_available_versions()?;
        let available_versions = Self::parse_api_response(&json_data)?;

        match version_input {
            "latest" => {
                // Get the latest stable version (first non-prerelease in the list)
                available_versions
                    .iter()
                    .find(|r| !r.prerelease)
                    .map(|r| r.tag_name.clone())
                    .ok_or_else(|| RvmError::VersionNotFound("latest".to_string()))
            }
            v if v.chars().all(|c| c.is_ascii_digit()) => {
                // Major version only (e.g., "3")
                let target_major = format!("v{}", v);
                available_versions
                    .iter()
                    .find(|r| r.tag_name.starts_with(&target_major) && !r.prerelease)
                    .map(|r| r.tag_name.clone())
                    .ok_or_else(|| RvmError::VersionNotFound(v.to_string()))
            }
            v if v.matches('.').count() == 1 => {
                // Major.minor version (e.g., "3.4")
                let target_prefix = if v.starts_with('v') {
                    v.to_string()
                } else {
                    format!("v{}", v)
                };
                available_versions
                    .iter()
                    .find(|r| r.tag_name.starts_with(&target_prefix) && !r.prerelease)
                    .map(|r| r.tag_name.clone())
                    .ok_or_else(|| RvmError::VersionNotFound(v.to_string()))
            }
            v => {
                // Specific version (e.g., "3.4.0" or "v3.4.0")
                let target_version = if v.starts_with('v') {
                    v.to_string()
                } else {
                    format!("v{}", v)
                };
                available_versions
                    .iter()
                    .find(|r| r.tag_name == target_version)
                    .map(|r| r.tag_name.clone())
                    .ok_or_else(|| RvmError::VersionNotFound(v.to_string()))
            }
        }
    }
}