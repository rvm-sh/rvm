use super::Runtime;
use crate::utils::download::{download_and_extract, get_architecture};
use crate::utils::error::{Result, RvmError};
use crate::utils::profile::{reload_profile, remove_runtime_from_path, set_default_runtime};
use crate::utils::ui::{display_error, display_step, display_success};
use crate::utils::version::{
    apply_version_to_current_session, get_runtime_home, is_version_installed,
    list_installed_versions, remove_version, resolve_installed_version,
};
use reqwest::blocking;
use scraper::{Html, Selector};
use serde::Deserialize;

/// Go runtime manager
pub struct GoRuntime;

#[derive(Deserialize)]
struct GoRelease {
    version: String,
    stable: bool,
}

impl GoRuntime {
    /// Parse the API response into Go specific release data
    fn parse_api_response(json_data: &serde_json::Value) -> Result<Vec<GoRelease>> {
        let releases: Vec<GoRelease> = serde_json::from_value(json_data.clone())?;
        Ok(releases)
    }
}

impl Runtime for GoRuntime {
    fn add(&self, version: Option<&str>) -> Result<()> {
        let version_str = version.unwrap_or("latest");
        display_step(&format!("Adding Go version: {}", version_str));

        // Step 1: Parse and resolve version
        display_step("Resolving version from Go API");
        let resolved_version = self.resolve_version(version_str)?;
        display_success(&format!("Resolved to version: {}", resolved_version));

        // Step 2: Check if already installed (has built-in messaging)
        if is_version_installed("go", &resolved_version)? {
            return Err(RvmError::VersionAlreadyInstalled(resolved_version));
        }

        // Step 3: Download and extract (has built-in messaging)
        let arch = get_architecture()?;
        let go_arch = match arch {
            "x64" => "amd64",
            "arm64" => "arm64",
            _ => return Err(RvmError::UnsupportedArchitecture(arch.to_string())),
        };

        let filename = format!("{}.linux-{}.tar.gz", resolved_version, go_arch);
        let download_url = format!("https://go.dev/dl/{}", filename);

        // Convert from go1.23.11 to v1.23.11 for storage
        let storage_version = resolved_version
            .strip_prefix("go")
            .unwrap_or(&resolved_version);
        let storage_version = format!("v{}", storage_version);

        download_and_extract(
            &download_url,
            "go",
            &storage_version,
            &["bin/go", "bin/gofmt"], // Make go and gofmt executable
        )?;

        // Step 4: Set as default (has built-in messaging)
        set_default_runtime("go", &storage_version)?;

        // Step 5: Automatically reload profile (has built-in messaging)
        reload_profile()?;

        display_success(&format!(
            "Go {} installation completed successfully!",
            storage_version
        ));
        Ok(())
    }

    fn remove(&self, version: Option<&str>) -> Result<()> {
        match version {
            Some(v) => {
                display_step(&format!("Removing Go version: {}", v));

                // Check if version is installed
                if !is_version_installed("go", v)? {
                    display_error(&format!("Go {} is not installed", v));
                    return Err(RvmError::VersionNotFound(v.to_string()));
                }

                // Remove from PATH in profile
                remove_runtime_from_path("go", v)?;

                // Remove from filesystem (has built-in messaging)
                remove_version("go", v)?;

                // Reload profile to apply changes
                reload_profile()?;

                display_success(&format!("Go {} removed successfully", v));
            }
            None => {
                display_step("Removing all Go versions");

                // Get list of installed versions
                let installed_versions = list_installed_versions("go")?;

                if installed_versions.is_empty() {
                    display_success("No Go versions are installed");
                    return Ok(());
                }

                display_step(&format!(
                    "Found {} Go versions to remove",
                    installed_versions.len()
                ));

                // Remove each version
                for version in &installed_versions {
                    display_step(&format!("Removing Go {}", version));
                    remove_runtime_from_path("go", version)?;
                    remove_version("go", version)?;
                }

                // Clean up the entire go directory if it's empty
                let runtime_home = get_runtime_home("go")?;
                if runtime_home.exists() {
                    match std::fs::read_dir(&runtime_home) {
                        Ok(mut entries) => {
                            if entries.next().is_none() {
                                display_step("Cleaning up empty Go directory");
                                std::fs::remove_dir(&runtime_home)?;
                                display_success("Removed empty Go directory");
                            }
                        }
                        Err(_) => {} // Directory doesn't exist or can't read, skip cleanup
                    }
                }

                // Reload profile to apply changes
                reload_profile()?;

                display_success(&format!(
                    "Removed all {} Go versions successfully",
                    installed_versions.len()
                ));
            }
        }
        Ok(())
    }

    fn update(&self) -> Result<()> {
        display_step("Updating Go to latest version");

        // Get the latest version from the API
        let latest_version = self.resolve_version("latest")?;
        display_success(&format!("Latest Go version is: {}", latest_version));

        // Check if it's already installed
        if is_version_installed("go", &latest_version)? {
            display_success(&format!("Go {} is already installed", latest_version));

            // Set it as default if it's not already
            display_step("Ensuring latest version is set as default");
            set_default_runtime("go", &latest_version)?;
            reload_profile()?;

            display_success("Go is already up to date");
            return Ok(());
        }

        // Install the latest version using the add function
        display_step(&format!("Installing Go {}", latest_version));
        self.add(Some("latest"))?;

        display_success(&format!("Successfully updated Go to {}", latest_version));
        Ok(())
    }

    fn prune(&self, keep_version: &str) -> Result<()> {
        display_step(&format!("Pruning Go versions (keeping {})", keep_version));

        // Resolve the version to keep (e.g., "1.21" -> "go1.21.5")
        let resolved_keep_version = resolve_installed_version("go", keep_version)?;
        display_success(&format!("Will keep Go version: {}", resolved_keep_version));

        // Get list of all installed versions
        let installed_versions = list_installed_versions("go")?;

        if installed_versions.is_empty() {
            display_success("No Go versions are installed");
            return Ok(());
        }

        // Filter out the version to keep
        let versions_to_remove: Vec<String> = installed_versions
            .into_iter()
            .filter(|v| *v != resolved_keep_version)
            .collect();

        if versions_to_remove.is_empty() {
            display_success(&format!(
                "Only {} is installed, nothing to prune",
                resolved_keep_version
            ));
            return Ok(());
        }

        display_step(&format!(
            "Found {} Go versions to remove",
            versions_to_remove.len()
        ));

        // Remove each version except the one to keep
        for version in &versions_to_remove {
            display_step(&format!("Removing Go {}", version));

            // Remove from PATH in profile
            remove_runtime_from_path("go", version)?;

            // Remove from filesystem
            remove_version("go", version)?;
        }

        // Ensure the version to keep is set as default
        display_step(&format!("Setting {} as default", resolved_keep_version));
        set_default_runtime("go", &resolved_keep_version)?;

        // Reload profile to apply changes
        reload_profile()?;

        display_success(&format!(
            "Pruned {} Go versions, kept {}",
            versions_to_remove.len(),
            resolved_keep_version
        ));
        Ok(())
    }

    fn set_default(&self, version: &str) -> Result<()> {
        display_step(&format!("Setting Go {} as default", version));

        // Resolve version first (e.g., "1.21" -> "go1.21.5")
        let resolved_version = resolve_installed_version("go", version)?;
        display_success(&format!(
            "Resolved to installed version: {}",
            resolved_version
        ));

        // Set as default (has built-in messaging)
        set_default_runtime("go", &resolved_version)?;

        // Reload profile (has built-in messaging)
        reload_profile()?;

        // Force reload current environment
        display_step("Applying changes to current session");
        apply_version_to_current_session("go", &resolved_version, "go")?;

        display_success(&format!(
            "Go {} is now the default version",
            resolved_version
        ));
        Ok(())
    }

    fn use_version(&self, version: &str) -> Result<()> {
        display_step(&format!("Switching to Go {} for current session", version));

        // Resolve version first (e.g., "1.21" -> "go1.21.5")
        let resolved_version = resolve_installed_version("go", version)?;
        display_success(&format!(
            "Resolved to installed version: {}",
            resolved_version
        ));

        // Apply version to current session
        display_step("Applying changes to current session");
        apply_version_to_current_session("go", &resolved_version, "go")?;

        display_success(&format!(
            "Go {} is now active in current session",
            resolved_version
        ));
        println!("💡 This change is temporary. To make it permanent, run:");
        println!("   rvm set go {}", version);
        Ok(())
    }

    fn list_installed(&self) -> Result<Vec<String>> {
        list_installed_versions("go")
    }

    fn list_available(&self) -> Result<Vec<String>> {
        let json_data = self.fetch_available_versions()?;
        let releases = Self::parse_api_response(&json_data)?;
        
        display_step("Organizing versions for display");

        let mut result = Vec::new();

        // Separate stable and non-stable versions
        let mut stable_versions = Vec::new();
        let mut rc_beta_versions = Vec::new();

        for release in releases {
            let version = &release.version;
            // Convert go1.24.5 to v1.24.5 for display
            let display_version = if version.starts_with("go") {
                format!("v{}", &version[2..])
            } else {
                version.clone()
            };

            if release.stable {
                stable_versions.push(display_version);
            } else {
                rc_beta_versions.push(display_version);
            }
        }

        // Group stable versions by major.minor
        if !stable_versions.is_empty() {
            result.push("=== Stable Versions ===".to_string());

            let mut major_minor_groups: std::collections::BTreeMap<String, Vec<String>> =
                std::collections::BTreeMap::new();
            for version in &stable_versions {
                let version_clean = version.strip_prefix('v').unwrap_or(&version);
                let parts: Vec<&str> = version_clean.split('.').collect();
                if parts.len() >= 2 {
                    let major_minor = format!("{}.{}", parts[0], parts[1]);
                    let clean_version = version.strip_prefix('v').unwrap_or(version).to_string();
                    major_minor_groups
                        .entry(major_minor)
                        .or_insert_with(Vec::new)
                        .push(clean_version);
                }
            }

            // Convert to Vec and sort by semantic version (not lexical)
            let mut sorted_groups: Vec<(String, Vec<String>)> =
                major_minor_groups.into_iter().collect();
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
                        let parts: Vec<&str> = v.split('.').collect();
                        parts.get(2).and_then(|s| s.parse().ok()).unwrap_or(0)
                    };
                    parse_patch(b).cmp(&parse_patch(a))
                });

                let versions_str = versions.join(", ");
                result.push(format!("{}: {}", major_minor, versions_str));
                count += 1;
            }

            // Add truncation message for stable versions
            result.push("... displaying top 4 versions, all other versions truncated".to_string());

            result.push(String::new()); // Empty line
        }

        // Find the latest stable major.minor for filtering RC/Beta versions
        let latest_stable_major_minor = if !stable_versions.is_empty() {
            let version_clean = stable_versions[0]
                .strip_prefix('v')
                .unwrap_or(&stable_versions[0]);
            let parts: Vec<&str> = version_clean.split('.').collect();
            if parts.len() >= 2 {
                Some((
                    parts[0].parse::<u32>().unwrap_or(0),
                    parts[1].parse::<u32>().unwrap_or(0),
                ))
            } else {
                None
            }
        } else {
            None
        };

        // Group RC/Beta versions (only show if newer than latest stable)
        if !rc_beta_versions.is_empty() {
            let mut rc_groups: std::collections::BTreeMap<String, Vec<String>> =
                std::collections::BTreeMap::new();
            let mut beta_groups: std::collections::BTreeMap<String, Vec<String>> =
                std::collections::BTreeMap::new();

            for version in rc_beta_versions {
                let version_clean = version.strip_prefix('v').unwrap_or(&version);
                let clean_version = version.strip_prefix('v').unwrap_or(&version).to_string();

                // Parse the major.minor of this RC/Beta version
                let version_major_minor = if version_clean.contains("rc") {
                    let parts: Vec<&str> = version_clean.split("rc").collect();
                    if let Some(base) = parts.first() {
                        let base_parts: Vec<&str> = base.split('.').collect();
                        if base_parts.len() >= 2 {
                            Some((
                                base_parts[0].parse::<u32>().unwrap_or(0),
                                base_parts[1].parse::<u32>().unwrap_or(0),
                            ))
                        } else {
                            None
                        }
                    } else {
                        None
                    }
                } else if version_clean.contains("beta") {
                    let parts: Vec<&str> = version_clean.split("beta").collect();
                    if let Some(base) = parts.first() {
                        let base_parts: Vec<&str> = base.split('.').collect();
                        if base_parts.len() >= 2 {
                            Some((
                                base_parts[0].parse::<u32>().unwrap_or(0),
                                base_parts[1].parse::<u32>().unwrap_or(0),
                            ))
                        } else {
                            None
                        }
                    } else {
                        None
                    }
                } else {
                    None
                };

                // Only include if this RC/Beta version is newer than the latest stable
                let should_include =
                    if let (Some((rc_major, rc_minor)), Some((stable_major, stable_minor))) =
                        (version_major_minor, latest_stable_major_minor)
                    {
                        rc_major > stable_major
                            || (rc_major == stable_major && rc_minor > stable_minor)
                    } else {
                        false // If we can't parse, don't include
                    };

                if should_include {
                    if version_clean.contains("rc") {
                        let parts: Vec<&str> = version_clean.split("rc").collect();
                        if let Some(base) = parts.first() {
                            let base_parts: Vec<&str> = base.split('.').collect();
                            if base_parts.len() >= 2 {
                                let major_minor = format!("{}.{}", base_parts[0], base_parts[1]);
                                rc_groups
                                    .entry(major_minor)
                                    .or_insert_with(Vec::new)
                                    .push(clean_version);
                            }
                        }
                    } else if version_clean.contains("beta") {
                        let parts: Vec<&str> = version_clean.split("beta").collect();
                        if let Some(base) = parts.first() {
                            let base_parts: Vec<&str> = base.split('.').collect();
                            if base_parts.len() >= 2 {
                                let major_minor = format!("{}.{}", base_parts[0], base_parts[1]);
                                beta_groups
                                    .entry(major_minor)
                                    .or_insert_with(Vec::new)
                                    .push(clean_version);
                            }
                        }
                    }
                }
            }

            // Only display RC/Beta section if we have versions to show
            if !rc_groups.is_empty() || !beta_groups.is_empty() {
                result.push("=== Beta/RC Versions ===".to_string());

                // Display RC versions
                for (major_minor, mut versions) in rc_groups.into_iter().rev() {
                    versions.sort();
                    let versions_str = versions
                        .into_iter()
                        .map(|v| format!("{} (RC)", v))
                        .collect::<Vec<_>>()
                        .join(", ");
                    result.push(format!("{}: {}", major_minor, versions_str));
                }

                // Display Beta versions
                for (major_minor, mut versions) in beta_groups.into_iter().rev() {
                    versions.sort();
                    let versions_str = versions
                        .into_iter()
                        .map(|v| format!("{} (Beta)", v))
                        .collect::<Vec<_>>()
                        .join(", ");
                    result.push(format!("{}: {}", major_minor, versions_str));
                }

                // Add message for beta/RC versions
                result.push("Only shows latest rc/beta versions, where available".to_string());
            }
        }

        display_success("Successfully retrieved and organized Go versions");
        Ok(result)
    }

    fn fetch_available_versions(&self) -> Result<serde_json::Value> {
        // Step 1: Download the page
        display_step("Fetching Go versions from go.dev/dl/");
        let url = "https://go.dev/dl/";
        let client = blocking::Client::new();
        let response = client
            .get(url)
            .header("User-Agent", "rvm-rust/1.0.0")
            .send()?;

        if !response.status().is_success() {
            return Err(RvmError::HttpError(format!(
                "Failed to fetch Go downloads page: {}",
                response.status()
            )));
        }

        let html = response.text()?;
        display_step("Parsing version information");
        let document = Html::parse_document(&html);

        // Step 2: Parse all the ids - look for div elements with Go version ids
        let div_selector = Selector::parse("div[id^='go']").unwrap();
        let mut all_versions = Vec::new();

        for element in document.select(&div_selector) {
            if let Some(id) = element.value().attr("id") {
                if id.starts_with("go")
                    && id.len() > 2
                    && id.chars().nth(2).map_or(false, |c| c.is_ascii_digit())
                {
                    all_versions.push(id.to_string());
                }
            }
        }

        display_step("Categorizing Go releases");

        // Step 3: Sort versions into stable, rc, and beta categories
        let mut stable_versions = Vec::new();
        let mut rc_versions = Vec::new();
        let mut beta_versions = Vec::new();

        for version in all_versions {
            if version.contains("rc") {
                rc_versions.push(version);
            } else if version.contains("beta") {
                beta_versions.push(version);
            } else {
                stable_versions.push(version);
            }
        }

        // Sort each category by semantic version (newest first)
        let sort_versions = |versions: &mut Vec<String>| {
            versions.sort_by(|a, b| {
                let parse_version = |v: &str| -> (u32, u32, u32, u32) {
                    let without_go = v.strip_prefix("go").unwrap_or(v);
                    let (base_version, rc_beta_num) = if let Some(rc_pos) = without_go.find("rc") {
                        let num = without_go[rc_pos + 2..].parse().unwrap_or(0);
                        (&without_go[..rc_pos], num)
                    } else if let Some(beta_pos) = without_go.find("beta") {
                        let num = without_go[beta_pos + 4..].parse().unwrap_or(0);
                        (&without_go[..beta_pos], num)
                    } else {
                        (without_go, 0)
                    };

                    let parts: Vec<&str> = base_version.split('.').collect();
                    let major = parts.get(0).and_then(|s| s.parse().ok()).unwrap_or(0);
                    let minor = parts.get(1).and_then(|s| s.parse().ok()).unwrap_or(0);
                    let patch = parts.get(2).and_then(|s| s.parse().ok()).unwrap_or(0);
                    (major, minor, patch, rc_beta_num)
                };

                let version_a = parse_version(a);
                let version_b = parse_version(b);
                version_b.cmp(&version_a) // Reverse order for newest first
            });
        };

        display_step("Sorting versions by release type");
        
        sort_versions(&mut stable_versions);
        sort_versions(&mut rc_versions);
        sort_versions(&mut beta_versions);

        // Return all versions for processing in list_available()
        let mut result_versions = Vec::new();

        // Add all stable versions
        for version in stable_versions {
            result_versions.push(serde_json::json!({
                "version": version,
                "stable": true
            }));
        }

        // Add all RC versions
        for version in rc_versions {
            result_versions.push(serde_json::json!({
                "version": version,
                "stable": false
            }));
        }

        // Add all Beta versions
        for version in beta_versions {
            result_versions.push(serde_json::json!({
                "version": version,
                "stable": false
            }));
        }

        Ok(serde_json::Value::Array(result_versions))
    }

    fn resolve_version(&self, version_input: &str) -> Result<String> {
        let json_data = self.fetch_available_versions()?;
        let available_versions = Self::parse_api_response(&json_data)?;

        match version_input {
            "latest" => {
                // Get the latest stable version (first stable in the list)
                available_versions
                    .iter()
                    .find(|r| r.stable)
                    .map(|r| r.version.clone())
                    .ok_or_else(|| RvmError::VersionNotFound("latest".to_string()))
            }
            v if v.chars().all(|c| c.is_ascii_digit()) => {
                // Major version only (e.g., "1")
                let target_major = format!("go{}", v);
                available_versions
                    .iter()
                    .find(|r| r.version.starts_with(&target_major) && r.stable)
                    .map(|r| r.version.clone())
                    .ok_or_else(|| RvmError::VersionNotFound(v.to_string()))
            }
            v if v.matches('.').count() == 1 => {
                // Major.minor version (e.g., "1.21")
                let target_prefix = format!("go{}", v);
                available_versions
                    .iter()
                    .find(|r| r.version.starts_with(&target_prefix) && r.stable)
                    .map(|r| r.version.clone())
                    .ok_or_else(|| RvmError::VersionNotFound(v.to_string()))
            }
            v => {
                // Specific version (e.g., "1.21.5" or "go1.21.5")
                let target_version = if v.starts_with("go") {
                    v.to_string()
                } else {
                    format!("go{}", v)
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
