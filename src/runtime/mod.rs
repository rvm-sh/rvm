use crate::utils::error::{Result, RvmError};
use std::fs;

// Import runtime modules
pub mod node;

/// Runtime trait that all runtime managers must implement
pub trait Runtime {
    // Installation & Removal Functions
    fn install(&self, version: Option<&str>) -> Result<()>;
    fn remove(&self, version: Option<&str>) -> Result<()>;
    fn update(&self) -> Result<()>;
    fn prune(&self, keep_version: &str) -> Result<()>;
    
    // Version Management Functions
    fn set_default(&self, version: &str) -> Result<()>;
    fn use_version(&self, version: &str) -> Result<()>;
    
    // Information & Discovery Functions
    fn list_installed(&self) -> Result<Vec<String>>;
    fn list_available(&self) -> Result<Vec<String>>;
    fn get_current_version(&self) -> Result<Option<String>>;
    
    // Metadata Functions (Internal Use Only)
    fn name(&self) -> &str;
    fn binary_name(&self) -> &str;
}

/// Auto-discover supported runtimes by scanning runtime module files
pub fn list_supported_runtimes() -> Result<Vec<String>> {
    let mut runtimes = Vec::new();
    
    // Read the src/runtime directory
    let runtime_dir = std::path::Path::new("src/runtime");
    if runtime_dir.exists() {
        for entry in fs::read_dir(runtime_dir)? {
            let entry = entry?;
            let path = entry.path();
            
            if path.is_file() && path.extension().map_or(false, |ext| ext == "rs") {
                if let Some(file_name) = path.file_stem() {
                    let name = file_name.to_string_lossy();
                    // Skip mod.rs
                    if name != "mod" {
                        runtimes.push(name.to_string());
                    }
                }
            }
        }
    }
    
    runtimes.sort();
    Ok(runtimes)
}

/// Create a runtime instance by name
pub fn get_runtime(name: &str) -> Result<Box<dyn Runtime>> {
    match name {
        "node" => Ok(Box::new(node::NodeRuntime)),
        _ => Err(RvmError::UnsupportedRuntime(name.to_string())),
    }
}