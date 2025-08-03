use crate::utils::error::{Result, RvmError};
use crate::utils::version::get_runtime_home;
use reqwest::blocking;
use std::fs;
use std::os::unix::fs::PermissionsExt;
use std::path::PathBuf;
use tar::Archive;
use xz2::read::XzDecoder;
use flate2::read::GzDecoder;

/// Get the system architecture in the format expected by runtime distributors
pub fn get_architecture() -> Result<&'static str> {
    match std::env::consts::ARCH {
        "x86_64" => Ok("x64"),
        "aarch64" => Ok("arm64"),
        arch => Err(RvmError::UnsupportedArchitecture(arch.to_string())),
    }
}

/// Make a binary file executable
pub fn make_executable(binary_path: &PathBuf) -> Result<()> {
    if binary_path.exists() {
        let mut perms = fs::metadata(binary_path)?.permissions();
        perms.set_mode(0o755);
        fs::set_permissions(binary_path, perms)?;
    }
    Ok(())
}

/// Download and extract a runtime archive
pub fn download_and_extract(
    download_url: &str,
    runtime_name: &str,
    version: &str,
    binary_paths: &[&str], // Relative paths to binaries that need to be executable
) -> Result<()> {
    println!("Downloading {} {} from {}", runtime_name, version, download_url);
    
    // Download to memory
    let response = blocking::get(download_url)?;
    if !response.status().is_success() {
        return Err(RvmError::DownloadFailed(download_url.to_string()));
    }
    
    let bytes = response.bytes()?;
    
    // Create runtime directory if it doesn't exist
    let runtime_home = get_runtime_home(runtime_name)?;
    fs::create_dir_all(&runtime_home)?;
    
    // Extract to temporary directory first
    let temp_dir = runtime_home.join("temp");
    fs::create_dir_all(&temp_dir)?;
    
    // Handle different archive types
    if download_url.ends_with(".tar.xz") {
        let decoder = XzDecoder::new(bytes.as_ref());
        let mut archive = Archive::new(decoder);
        archive.unpack(&temp_dir)?;
    } else if download_url.ends_with(".tar.gz") {
        let decoder = GzDecoder::new(bytes.as_ref());
        let mut archive = Archive::new(decoder);
        archive.unpack(&temp_dir)?;
    } else {
        return Err(RvmError::ExtractionFailed("Unsupported archive format".to_string()));
    }
    
    // Find the extracted directory and rename it to version
    let extracted_dir = fs::read_dir(&temp_dir)?
        .next()
        .ok_or_else(|| RvmError::ExtractionFailed("No extracted directory found".to_string()))??
        .path();
    
    let target_dir = runtime_home.join(version);
    fs::rename(extracted_dir, &target_dir)?;
    
    // Clean up temp directory
    fs::remove_dir_all(&temp_dir)?;
    
    // Make specified binaries executable
    for binary_path in binary_paths {
        let full_path = target_dir.join(binary_path);
        make_executable(&full_path)?;
    }
    
    println!("Successfully installed {} {}", runtime_name, version);
    Ok(())
}