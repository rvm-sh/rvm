use crate::utils::error::{Result, RvmError};
use std::collections::BTreeMap;
use std::path::PathBuf;

/// Get the runtime's home directory (e.g., ~/.node, ~/.python)
pub fn get_runtime_home(runtime_name: &str) -> Result<PathBuf> {
    let home = std::env::var("HOME").map_err(|_| RvmError::HomeDirectoryNotFound)?;
    Ok(PathBuf::from(home).join(format!(".{}", runtime_name)))
}

/// Check if a specific version is already installed
pub fn is_version_installed(runtime_name: &str, version: &str) -> Result<bool> {
    let runtime_home = get_runtime_home(runtime_name)?;
    let version_dir = runtime_home.join(version);
    Ok(version_dir.exists())
}

#[derive(Debug, Clone)]
pub struct VersionInfo {
    pub version: String,
    pub channel: String,
    pub major_minor: String,
}

/// Remove the 'v' prefix from version for display purposes
pub fn clean_version_for_display(version: &str) -> String {
    version.strip_prefix('v').unwrap_or(version).to_string()
}

/// Extract major.minor from version string (e.g., "v20.11.0" -> "20.11")
pub fn extract_major_minor(version: &str) -> Option<String> {
    let version_clean = version.strip_prefix('v').unwrap_or(version);
    
    let parts: Vec<&str> = version_clean.split('.').collect();
    if parts.len() >= 2 {
        Some(format!("{}.{}", parts[0], parts[1]))
    } else {
        None
    }
}

/// Detect release channel from version string and additional metadata
pub fn detect_channel(version: &str, is_lts: bool) -> String {
    let version_lower = version.to_lowercase();
    
    if is_lts {
        return "LTS".to_string();
    }
    
    if version_lower.contains("alpha") {
        "Alpha".to_string()
    } else if version_lower.contains("beta") {
        "Beta".to_string()
    } else if version_lower.contains("rc") {
        "RC".to_string()
    } else if version_lower.contains("nightly") {
        "Nightly".to_string()
    } else {
        "Stable".to_string()
    }
}

/// Compare two version strings for sorting (e.g., "v20.11.0" vs "v20.10.5")
pub fn compare_versions(a: &str, b: &str) -> std::cmp::Ordering {
    let clean_a = a.strip_prefix('v').unwrap_or(a);
    let clean_b = b.strip_prefix('v').unwrap_or(b);
    
    let parts_a: Vec<u32> = clean_a.split('.').filter_map(|s| s.parse().ok()).collect();
    let parts_b: Vec<u32> = clean_b.split('.').filter_map(|s| s.parse().ok()).collect();
    
    // Compare major, minor, patch in order
    for (part_a, part_b) in parts_a.iter().zip(parts_b.iter()) {
        match part_a.cmp(part_b) {
            std::cmp::Ordering::Equal => continue,
            other => return other,
        }
    }
    
    // If all compared parts are equal, the longer version is considered greater
    parts_a.len().cmp(&parts_b.len())
}

/// Format a list of versions with smart line wrapping and truncation
fn format_version_list(versions: &[String], max_line_length: usize) -> String {
    if versions.is_empty() {
        return String::new();
    }
    
    let mut lines = Vec::new();
    let mut current_line = String::new();
    
    for (i, version) in versions.iter().enumerate() {
        let separator = if i == 0 { "" } else { ", " };
        let addition = format!("{}{}", separator, version);
        
        // Check if adding this version would exceed the line length
        if !current_line.is_empty() && current_line.len() + addition.len() > max_line_length {
            lines.push(current_line);
            current_line = version.clone();
        } else {
            current_line.push_str(&addition);
        }
    }
    
    if !current_line.is_empty() {
        lines.push(current_line);
    }
    
    // Indent continuation lines for better readability
    if lines.len() > 1 {
        for line in lines.iter_mut().skip(1) {
            *line = format!("      {}", line); // 6 spaces for alignment
        }
    }
    
    lines.join("\n")
}

/// Extract major version from version string (e.g., "20.11.0" -> "20")
fn extract_major_version(version: &str) -> Option<u32> {
    let version_clean = version.strip_prefix('v').unwrap_or(version);
    version_clean.split('.').next()?.parse().ok()
}

/// Group versions by release channel and format for display
/// Returns formatted strings organized by channel (LTS, Stable, Beta, etc.)
/// Hierarchy: top 4 major versions → top 4 major.minor per major → top 4 patches per major.minor
pub fn group_versions_by_channel(version_infos: Vec<VersionInfo>) -> Vec<String> {
    use std::collections::HashMap;
    
    // Group by channel, then by major, then by major.minor
    let mut channel_groups: BTreeMap<String, BTreeMap<u32, BTreeMap<String, Vec<String>>>> = BTreeMap::new();
    
    for version_info in version_infos {
        if let Some(major) = extract_major_version(&version_info.version) {
            channel_groups
                .entry(version_info.channel.clone())
                .or_insert_with(BTreeMap::new)
                .entry(major)
                .or_insert_with(BTreeMap::new)
                .entry(version_info.major_minor)
                .or_insert_with(Vec::new)
                .push(clean_version_for_display(&version_info.version));
        }
    }
    
    let mut result = Vec::new();
    const MAX_MAJORS: usize = 4;
    const MAX_MAJOR_MINORS: usize = 4;
    const MAX_PATCHES: usize = 4;
    const MAX_LINE_LENGTH: usize = 100;
    
    // Define channel priority for display order
    let channel_priority = vec!["LTS", "Stable", "Beta", "RC", "Alpha", "Nightly"];
    
    for channel in channel_priority {
        if let Some(major_groups) = channel_groups.remove(channel) {
            if major_groups.is_empty() {
                continue;
            }
            
            result.push(format!("=== {} Versions ===", channel));
            
            let total_majors = major_groups.len();
            let mut truncated = false;
            
            // Take top 4 major versions (newest first)
            let limited_majors: Vec<_> = major_groups.into_iter().rev().take(MAX_MAJORS).collect();
            
            if total_majors > MAX_MAJORS {
                truncated = true;
            }
            
            for (_major, major_minor_groups) in limited_majors {
                let total_major_minors = major_minor_groups.len();
                
                if total_major_minors > MAX_MAJOR_MINORS {
                    truncated = true;
                }
                
                // Take top 4 major.minor versions (newest first)
                let limited_major_minors: Vec<_> = major_minor_groups.into_iter().rev().take(MAX_MAJOR_MINORS).collect();
                
                for (major_minor, mut versions) in limited_major_minors {
                    // Sort versions within each group in descending order
                    versions.sort_by(|a, b| compare_versions(b, a));
                    
                    let total_patches = versions.len();
                    if total_patches > MAX_PATCHES {
                        truncated = true;
                    }
                    
                    // Take top 4 patch versions
                    let limited_versions: Vec<_> = versions.into_iter().take(MAX_PATCHES).collect();
                    
                    // Add channel marker to versions if not LTS/Stable
                    let formatted_versions: Vec<String> = if channel == "LTS" || channel == "Stable" {
                        limited_versions
                    } else {
                        limited_versions.into_iter().map(|v| format!("{} ({})", v, channel)).collect()
                    };
                    
                    let versions_str = format_version_list(&formatted_versions, MAX_LINE_LENGTH);
                    result.push(format!("{}: {}", major_minor, versions_str));
                }
            }
            
            // Add truncation notice if we truncated anything
            if truncated {
                result.push("... displaying top 4 versions, all other versions truncated".to_string());
            }
            
            result.push(String::new()); // Add empty line between channels
        }
    }
    
    // Add any remaining channels that weren't in the priority list
    for (channel, major_groups) in channel_groups {
        if major_groups.is_empty() {
            continue;
        }
        
        result.push(format!("=== {} Versions ===", channel));
        
        let total_majors = major_groups.len();
        let mut truncated = false;
        
        let limited_majors: Vec<_> = major_groups.into_iter().rev().take(MAX_MAJORS).collect();
        
        if total_majors > MAX_MAJORS {
            truncated = true;
        }
        
        for (_major, major_minor_groups) in limited_majors {
            let total_major_minors = major_minor_groups.len();
            
            if total_major_minors > MAX_MAJOR_MINORS {
                truncated = true;
            }
            
            let limited_major_minors: Vec<_> = major_minor_groups.into_iter().rev().take(MAX_MAJOR_MINORS).collect();
            
            for (major_minor, mut versions) in limited_major_minors {
                versions.sort_by(|a, b| compare_versions(b, a));
                
                let total_patches = versions.len();
                if total_patches > MAX_PATCHES {
                    truncated = true;
                }
                
                let limited_versions: Vec<_> = versions.into_iter().take(MAX_PATCHES).collect();
                let versions_str = format_version_list(&limited_versions, MAX_LINE_LENGTH);
                result.push(format!("{}: {}", major_minor, versions_str));
            }
        }
        
        if truncated {
            result.push("... displaying top 4 versions, all other versions truncated".to_string());
        }
        
        result.push(String::new());
    }
    
    // Remove trailing empty line
    if result.last() == Some(&String::new()) {
        result.pop();
    }
    
    result
}

