#!/bin/sh

# Placeholder for latest and default versions of pnpm
LATEST_PNPM_VERSION="8.15.1"
DEFAULT_PNPM_VERSION="8.15.1"

# Function to handle pnpm commands
pnpm() {
    echo "Debug: Running pnpm version $version_to_use at $pnpm_executable"

    # Execute the pnpm command with the specified version
    "$pnpm_executable" "$@"

    
    local full_command=$1
    local specified_version=""
    local actual_command=""

    # Check if a specific version is requested
    if echo "$full_command" | grep -q "@"; then
        specified_version=$(echo "$full_command" | cut -d'@' -f2)
        actual_command=$(echo "$full_command" | cut -d'@' -f1)
    else
        specified_version=$DEFAULT_PNPM_VERSION
        actual_command=$full_command
    fi

    shift  # Remove the first argument

    # Determine which version to use
    local version_to_use=${specified_version:-$DEFAULT_PNPM_VERSION}

    # Path to the pnpm executable for the chosen version
    local pnpm_executable="${HOME}/.pnpm/${version_to_use}/pnpm"

    if [ ! -f "$pnpm_executable" ]; then
        echo "pnpm version $version_to_use not found."
        return 1
    fi

    # Execute the pnpm command with the specified version
    "$pnpm_executable" "$actual_command" "$@"
}


#when adding an uninstall all function, remember to remove also the shared folder in ./local/share that stores teh shared packages/modules