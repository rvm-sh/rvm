use crate::utils::error::{Result, RvmError};
use crate::utils::version::get_runtime_home;
use crate::utils::ui::{display_step, display_success, display_error};
use reqwest::blocking;
use std::fs;
use std::io::{Read, Write};
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

/// Display download progress
fn display_download_progress(downloaded: u64, total: Option<u64>) {
    if let Some(total) = total {
        let percentage = (downloaded as f64 / total as f64 * 100.0) as u8;
        let bars = percentage / 2; // 50 bars for 100%
        let progress_bar = "█".repeat(bars as usize) + &"░".repeat(50 - bars as usize);
        print!("\r📥 Downloading: [{}] {}% ({:.1}MB/{:.1}MB)", 
               progress_bar, percentage, downloaded as f64 / 1024.0 / 1024.0, total as f64 / 1024.0 / 1024.0);
        std::io::stdout().flush().unwrap();
    } else {
        print!("\r📥 Downloading: {:.1}MB", downloaded as f64 / 1024.0 / 1024.0);
        std::io::stdout().flush().unwrap();
    }
}

/// Download and extract a runtime archive with progress indicators
pub fn download_and_extract(
    download_url: &str,
    runtime_name: &str,
    version: &str,
    binary_paths: &[&str], // Relative paths to binaries that need to be executable
) -> Result<()> {
    display_step(&format!("Starting download of {} {}", runtime_name, version));
    
    // Download with progress
    let response = blocking::get(download_url)?;
    if !response.status().is_success() {
        display_error(&format!("Download failed: HTTP {}", response.status()));
        return Err(RvmError::DownloadFailed(download_url.to_string()));
    }
    
    let total_size = response.content_length();
    display_step(&format!("Download started from {}", download_url));
    
    let mut downloaded = 0u64;
    let mut bytes = Vec::new();
    let mut response = response;
    
    // Read in chunks to show progress
    let mut buffer = [0; 8192];
    loop {
        match response.read(&mut buffer) {
            Ok(0) => break, // End of stream
            Ok(n) => {
                bytes.extend_from_slice(&buffer[..n]);
                downloaded += n as u64;
                display_download_progress(downloaded, total_size);
            }
            Err(e) => {
                display_error(&format!("Download failed: {}", e));
                return Err(RvmError::DownloadFailed(e.to_string()));
            }
        }
    }
    
    println!(); // New line after progress bar
    display_success(&format!("Downloaded {:.1}MB successfully", downloaded as f64 / 1024.0 / 1024.0));
    
    // Create runtime directory if it doesn't exist
    display_step("Creating installation directory");
    let runtime_home = get_runtime_home(runtime_name)?;
    fs::create_dir_all(&runtime_home)?;
    
    // Extract to temporary directory first
    display_step("Preparing extraction");
    let temp_dir = runtime_home.join("temp");
    fs::create_dir_all(&temp_dir)?;
    
    // Handle different archive types
    display_step("Extracting archive");
    if download_url.ends_with(".tar.xz") {
        let decoder = XzDecoder::new(bytes.as_slice());
        let mut archive = Archive::new(decoder);
        archive.unpack(&temp_dir)?;
    } else if download_url.ends_with(".tar.gz") {
        let decoder = GzDecoder::new(bytes.as_slice());
        let mut archive = Archive::new(decoder);
        archive.unpack(&temp_dir)?;
    } else {
        display_error("Unsupported archive format");
        return Err(RvmError::ExtractionFailed("Unsupported archive format".to_string()));
    }
    display_success("Archive extracted successfully");
    
    // Find the extracted directory and rename it to version
    display_step("Organizing installation files");
    let extracted_dir = fs::read_dir(&temp_dir)?
        .next()
        .ok_or_else(|| RvmError::ExtractionFailed("No extracted directory found".to_string()))??
        .path();
    
    let target_dir = runtime_home.join(version);
    fs::rename(extracted_dir, &target_dir)?;
    
    // Clean up temp directory
    fs::remove_dir_all(&temp_dir)?;
    display_success("Installation files organized");
    
    // Make specified binaries executable
    display_step("Setting up executable permissions");
    for binary_path in binary_paths {
        let full_path = target_dir.join(binary_path);
        make_executable(&full_path)?;
    }
    display_success("Executable permissions configured");
    
    display_success(&format!("Successfully installed {} {}", runtime_name, version));
    Ok(())
}