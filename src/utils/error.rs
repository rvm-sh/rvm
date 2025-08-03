use thiserror::Error;

#[derive(Error, Debug)]
pub enum RvmError {
    // Runtime-related errors
    #[error("Unsupported runtime: {0}")]
    UnsupportedRuntime(String),
    
    #[error("Runtime {runtime} version {version} is already installed")]
    RuntimeAlreadyInstalled { runtime: String, version: String },
    
    #[error("Runtime {runtime} version {version} is not installed")]
    RuntimeNotInstalled { runtime: String, version: String },
    
    #[error("No versions of runtime {0} are installed")]
    NoVersionsInstalled(String),

    // Version-related errors
    #[error("Invalid version format: {0}")]
    InvalidVersionFormat(String),
    
    #[error("Version {version} is not available for runtime {runtime}")]
    VersionNotAvailable { runtime: String, version: String },
    
    #[error("Version {0} not found")]
    VersionNotFound(String),
    
    #[error("Version {0} is already installed")]
    VersionAlreadyInstalled(String),
    
    #[error("Unable to determine latest version for runtime {0}")]
    LatestVersionUnavailable(String),

    // Network-related errors
    #[error("Failed to reach download endpoint: {0}")]
    NetworkError(String),
    
    #[error("Download failed: {0}")]
    DownloadFailed(String),
    
    #[error("Failed to fetch available versions: {0}")]
    VersionFetchFailed(String),
    
    #[error("API rate limit exceeded. Please try again later")]
    RateLimitExceeded,

    // Filesystem-related errors
    #[error("Permission denied: {0}")]
    PermissionDenied(String),
    
    #[error("Insufficient disk space")]
    InsufficientDiskSpace,
    
    #[error("Failed to create directory: {0}")]
    DirectoryCreationFailed(String),
    
    #[error("Failed to extract archive: {0}")]
    ExtractionFailed(String),
    
    #[error("File not found: {0}")]
    FileNotFound(String),
    
    #[error("Corrupted installation: {0}")]
    CorruptedInstallation(String),

    // Process-related errors
    #[error("Binary not found: {0}")]
    BinaryNotFound(String),
    
    #[error("Command execution failed: {0}")]
    CommandExecutionFailed(String),
    
    #[error("Failed to verify installation: {0}")]
    InstallationVerificationFailed(String),

    // Configuration-related errors
    #[error("Failed to update shell profile: {0}")]
    ShellProfileUpdateFailed(String),
    
    #[error("Failed to set environment variables: {0}")]
    EnvironmentSetupFailed(String),
    
    #[error("Configuration file error: {0}")]
    ConfigurationError(String),

    // CLI/Input-related errors
    #[error("Invalid command arguments: {0}")]
    InvalidArguments(String),
    
    #[error("Missing required argument: {0}")]
    MissingArgument(String),

    // Watch-related errors
    #[error("File watcher setup failed: {0}")]
    WatcherSetupFailed(String),
    
    #[error("Watch command execution failed: {0}")]
    WatchCommandFailed(String),

    // IO and system errors
    #[error("IO error: {0}")]
    IoError(#[from] std::io::Error),
    
    #[error("JSON parsing error: {0}")]
    JsonError(#[from] serde_json::Error),
    
    #[error("File watcher error: {0}")]
    NotifyError(#[from] notify::Error),
    
    #[error("HTTP request error: {0}")]
    HttpError(String),
    
    #[error("Reqwest error: {0}")]
    ReqwestError(#[from] reqwest::Error),
    
    #[error("Unsupported architecture: {0}")]
    UnsupportedArchitecture(String),
    
    #[error("Home directory not found")]
    HomeDirectoryNotFound,

    // Generic errors
    #[error("Internal error: {0}")]
    InternalError(String),
    
    #[error("Operation cancelled by user")]
    UserCancelled,
}

pub type Result<T> = std::result::Result<T, RvmError>;