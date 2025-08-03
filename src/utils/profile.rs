use crate::utils::error::{Result, RvmError};
use crate::utils::version::get_runtime_home;
use std::fs::{self, OpenOptions};
use std::io::{BufRead, BufReader, Write};
use std::path::PathBuf;

/// Get the user's .profile file path
pub fn get_profile_file() -> Result<PathBuf> {
    let home = std::env::var("HOME")
        .map_err(|_| RvmError::HomeDirectoryNotFound)?;
    Ok(PathBuf::from(home).join(".profile"))
}

/// Check if a runtime's PATH is already in .profile
pub fn is_runtime_in_path(runtime_name: &str, version: &str) -> Result<bool> {
    let profile_path = get_profile_file()?;
    
    if !profile_path.exists() {
        return Ok(false);
    }
    
    let file = fs::File::open(&profile_path)?;
    let reader = BufReader::new(file);
    
    let runtime_home = get_runtime_home(runtime_name)?;
    let bin_path = runtime_home.join(version).join("bin");
    let path_string = bin_path.to_string_lossy();
    
    for line in reader.lines() {
        let line = line?;
        if line.contains(path_string.as_ref()) {
            return Ok(true);
        }
    }
    
    Ok(false)
}

/// Add runtime PATH to .profile
pub fn add_runtime_to_path(runtime_name: &str, version: &str) -> Result<()> {
    // Check if already in PATH
    if is_runtime_in_path(runtime_name, version)? {
        return Ok(());
    }
    
    let profile_path = get_profile_file()?;
    let runtime_home = get_runtime_home(runtime_name)?;
    let bin_path = runtime_home.join(version).join("bin");
    
    // Create the PATH export line
    let path_line = format!(
        "\n# Added by rvm for {} {}\nexport PATH=\"{}:$PATH\"\n",
        runtime_name,
        version,
        bin_path.to_string_lossy()
    );
    
    // Append to .profile
    let mut file = OpenOptions::new()
        .create(true)
        .append(true)
        .open(&profile_path)?;
    
    file.write_all(path_line.as_bytes())?;
    
    println!("Added {} {} to PATH in ~/.profile", runtime_name, version);
    
    Ok(())
}

/// Remove specific runtime version from PATH in .profile
pub fn remove_runtime_from_path(runtime_name: &str, version: &str) -> Result<()> {
    let profile_path = get_profile_file()?;
    
    if !profile_path.exists() {
        return Ok(());
    }
    
    let runtime_home = get_runtime_home(runtime_name)?;
    let bin_path = runtime_home.join(version).join("bin");
    let path_string = bin_path.to_string_lossy();
    
    // Read all lines
    let file = fs::File::open(&profile_path)?;
    let reader = BufReader::new(file);
    let mut lines: Vec<String> = Vec::new();
    let mut skip_next = false;
    
    for line in reader.lines() {
        let line = line?;
        
        // Skip the comment line added by rvm
        if line.contains(&format!("# Added by rvm for {} {}", runtime_name, version)) {
            skip_next = true;
            continue;
        }
        
        // Skip the export line if it contains our path
        if skip_next && line.contains(path_string.as_ref()) {
            skip_next = false;
            continue;
        }
        
        skip_next = false;
        lines.push(line);
    }
    
    // Write back the filtered lines
    fs::write(&profile_path, lines.join("\n"))?;
    
    println!("Removed {} {} from PATH in ~/.profile", runtime_name, version);
    
    Ok(())
}

/// Set a runtime version as the default (remove others, add this one)
pub fn set_default_runtime(runtime_name: &str, version: &str) -> Result<()> {
    // First, remove any existing PATH entries for this runtime
    remove_all_runtime_paths(runtime_name)?;
    
    // Then add the new version
    add_runtime_to_path(runtime_name, version)?;
    
    println!("Set {} {} as default runtime", runtime_name, version);
    
    Ok(())
}

/// Remove all PATH entries for a runtime (when uninstalling completely)
pub fn remove_all_runtime_paths(runtime_name: &str) -> Result<()> {
    let profile_path = get_profile_file()?;
    
    if !profile_path.exists() {
        return Ok(());
    }
    
    let runtime_home = get_runtime_home(runtime_name)?;
    let runtime_path_prefix = runtime_home.to_string_lossy();
    
    // Read all lines
    let file = fs::File::open(&profile_path)?;
    let reader = BufReader::new(file);
    let mut lines: Vec<String> = Vec::new();
    let mut skip_next = false;
    
    for line in reader.lines() {
        let line = line?;
        
        // Skip comment lines added by rvm for this runtime
        if line.contains(&format!("# Added by rvm for {}", runtime_name)) {
            skip_next = true;
            continue;
        }
        
        // Skip export lines that contain this runtime's path
        if skip_next && line.contains(runtime_path_prefix.as_ref()) {
            skip_next = false;
            continue;
        }
        
        // Also check if any line contains this runtime's path (without skip_next)
        if line.contains(runtime_path_prefix.as_ref()) {
            continue;
        }
        
        skip_next = false;
        lines.push(line);
    }
    
    // Write back the filtered lines
    fs::write(&profile_path, lines.join("\n"))?;
    
    println!("Removed all {} PATH entries from ~/.profile", runtime_name);
    
    Ok(())
}

/// Automatically reload profile for the user
pub fn reload_profile() -> Result<()> {
    use std::process::Command;
    
    let profile_path = get_profile_file()?;
    
    if !profile_path.exists() {
        println!("No profile file found to reload");
        return Ok(());
    }
    
    // Try to source the profile in the current shell
    // Note: This won't affect the parent shell, but will set environment for child processes
    let output = Command::new("bash")
        .arg("-c")
        .arg(format!("source {}", profile_path.to_string_lossy()))
        .output()
        .map_err(|e| RvmError::CommandExecutionFailed(e.to_string()))?;
    
    if output.status.success() {
        println!("✅ Profile reloaded successfully");
        println!("💡 Runtime is now available in new shell sessions");
    } else {
        println!("⚠️  Couldn't automatically reload profile");
        println!("📝 To use the runtime immediately, run:");
        println!("   source ~/.profile");
        println!("Or restart your terminal/desktop session.");
    }
    
    Ok(())
}