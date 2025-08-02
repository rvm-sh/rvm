# STRUCTURE
This file aims to document the actual functions that each runtime manager will have as well as other important implementation details. The aim is to ensure that I keep this standardised across runtimes so that future additions/changes are easier to make

## CLI Command Mapping

| CLI Command | Function |
|-------------|----------|
| `rvm add <runtime> [version]` | `runtime.install(version)` |
| `rvm remove <runtime> [version]` | `runtime.remove(version)` |
| `rvm update <runtime>` | `runtime.update()` |
| `rvm prune <runtime> <version>` | `runtime.prune(version)` |
| `rvm set <runtime> <version>` | `runtime.set_default(version)` |
| `rvm use <runtime> <version>` | `runtime.use_version(version)` |
| `rvm list <runtime>` | `runtime.list_installed()`|
| `rvm list available <runtime>` | `runtime.list_available()` |
| `rvm list runtimes` | `list_supported_runtimes()` |

## File structure
Each runtime has its own named dot folder in the user's HOME (`home/<user>/`) folder.
```
.
├── .<runtime>
├── .<runtime>
├── .<runtime>
├── .<runtime>
    ├── v<version>
    ├── v<version>
    └── v<version>
```

## Runtime Trait Interface

All runtimes must implement the following standardized interface:

### Installation & Removal Functions
- `install(version: Option<&str>) -> Result<()>` - Install specific version or latest
- `remove(version: Option<&str>) -> Result<()>` - Remove specific version or all versions
- `update() -> Result<()>` - Install latest version, set as default
- `prune(keep_version: &str) -> Result<()>` - Remove versions older than specified

### Version Management Functions
- `set_default(version: &str) -> Result<()>` - Set persistent default version
- `use_version(version: &str) -> Result<()>` - Use version for current session (env vars)

### Information & Discovery Functions
- `list_installed() -> Result<Vec<String>>` - Show what's currently installed
- `list_available() -> Result<Vec<String>>` - Show what can be installed (from remote)
- `get_current_version() -> Result<Option<String>>` - What version is currently active

### Metadata Functions (Internal Use Only)
- `name() -> &str` - Runtime name for identification ("node", "deno", "cpython")
- `binary_name() -> &str` - Executable name for running commands ("node", "python")

## Global Functions (Non-Runtime Specific)
- `list_supported_runtimes() -> Vec<String>` - Auto-discover available runtimes from filesystem
