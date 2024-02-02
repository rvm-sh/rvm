#!/bin/sh

# Define a list of installed pnpm versions
installed_versions="8.14.0 8.14.3 8.15.0 8.15.1"

# Placeholder for latest and default versions of pnpm
LATEST_PNPM_VERSION="8.15.1"
DEFAULT_PNPM_VERSION="8.14.3"

# Function to handle pnpm commands
pnpm() {
    local specified_version=""
    local version_to_use=""
    local version_command="$1"
    shift  # Shift here to correctly process remaining arguments

    # Extracting the version if specified
    if echo "$version_command" | grep -q "@"; then
        specified_version=$(echo "$version_command" | cut -d'@' -f2)
        # Check if specified version is in the list of installed versions
        if echo "$installed_versions" | grep -qw "$specified_version"; then
            version_to_use=$specified_version
        else
            echo "Specified version $specified_version is not installed."
            return 1
        fi
    elif [ "$version_command" = "pnpm@latest" ]; then
        version_to_use=$LATEST_PNPM_VERSION
    else
        version_to_use=$DEFAULT_PNPM_VERSION
        set -- "$version_command" "$@"  # Prepend version_command back to arguments if not specifying a version
    fi

    local pnpm_executable="${HOME}/.pnpm/v${version_to_use}/pnpm"
    echo "Selected version: $version_to_use"
    echo "Executing: $pnpm_executable with arguments: $@"

    if [ ! -f "$pnpm_executable" ]; then
        echo "Executable for pnpm version $version_to_use not found."
        return 1
    fi

    # Execute the pnpm command with the specified version
    $pnpm_executable "$@"
}




#when adding an uninstall all function, remember to remove also the shared folder in ./local/share that stores teh shared packages/modules