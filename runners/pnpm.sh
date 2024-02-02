#!/bin/sh

# Define the default and latest versions of pnpm
DEFAULT_PNPM_VERSION="8.15.1"
ENABLE_AUTOCHECK="true"  # Control auto version check

INSTALLED_VERSIONS="8.14.0 8.14.3 8.15.0 8.15.1"

# Function to handle pnpm commands
pnpm() {
    # Check if auto version check is enabled
    if [ "$ENABLE_AUTOCHECK" = "true" ]; then
        # Proceed with version check
        if [ -f "package.json" ]; then
            # Check for jq
            if ! command -v jq &> /dev/null; then
                echo "jq not found, please install jq to use autocheck or disable autocheck."
                use_pnpm_version "$DEFAULT_PNPM_VERSION" "$@"
                return
            fi
            
            # Extract the pnpm version from package.json
            local pnpm_version_specified=$(jq -r '.engines.pnpm // empty' package.json)

            if [ -z "$pnpm_version_specified" ]; then
                echo "No pnpm version specified in package.json. Using the default version."
                use_pnpm_version "$DEFAULT_PNPM_VERSION" "$@"
                return
            fi

            # Determine the pnpm version to use
            local version_to_use=$(determine_pnpm_version "$pnpm_version_specified")
            use_pnpm_version "$version_to_use" "$@"
            return
        else
            echo "package.json not found. Using the default pnpm version."
        fi
    fi

    # Fallback or if autocheck is disabled
    use_pnpm_version "$DEFAULT_PNPM_VERSION" "$@"
}

# Function to use a specific pnpm version
use_pnpm_version() {
    local version="$1"
    if [ "$version" = "not_found" ]; then
        echo "No matching version found for specified criteria. Exiting without defaulting to the default version."
        return 1
    fi

    shift  # Remove version from the arguments
    local pnpm_executable="${HOME}/.pnpm/v${version}/pnpm"

    if [ -f "$pnpm_executable" ]; then
        echo "Using pnpm version: $version"
        $pnpm_executable "$@"
    else
        echo "pnpm version $version not found. Please install this version before running the command."
        return 1
    fi
}

# Function to determine the pnpm version to use based on the specification
determine_pnpm_version() {
    local version_spec="$1"
    local base_version=""
    local determined_version=""
    
    # Directly specified version number (e.g., "8.14.0")
    if echo "$version_spec" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
        echo "$version_spec"
        return
    fi

    # Greater than (e.g., ">8.14.0")
    if echo "$version_spec" | grep -qE '^>[0-9]+\.[0-9]+\.[0-9]+$'; then
        base_version=$(echo "$version_spec" | cut -c2-)
        determined_version=$(find_higher_version "$base_version")
    
    # Greater than or equal to (e.g., ">=8.14.0")
    elif echo "$version_spec" | grep -qE '^>=[0-9]+\.[0-9]+\.[0-9]+$'; then
        base_version=$(echo "$version_spec" | cut -c3-)
        determined_version=$(find_higher_or_equal_version "$base_version")
    
    # Specified only major and minor version (e.g., "8.14")
    elif echo "$version_spec" | grep -qE '^[0-9]+\.[0-9]+$'; then
        determined_version=$(find_highest_patch_for_minor "$version_spec")

    # Specified greater than major and minor version (e.g., ">8.14")
    elif echo "$version_spec" | grep -qE '^>[0-9]+\.[0-9]+$'; then
        base_version=$(echo "$version_spec" | cut -c2-)
        determined_version=$(find_highest_patch_for_minor "$base_version")
    
    # Specified greater than major and minor version (e.g., ">8.14")
    elif echo "$version_spec" | grep -qE '^>=[0-9]+\.[0-9]+$'; then
        base_version=$(echo "$version_spec" | cut -c3-)
        determined_version=$(find_highest_patch_for_minor "$base_version")

    # Specified only major version (e.g., "8")
    elif echo "$version_spec" | grep -qE '^[0-9]+$'; then
        determined_version=$(find_highest_patch_for_major "$version_spec")

    # Specified greater than major version (e.g., ">8")
    elif echo "$version_spec" | grep -qE '^>[0-9]+$'; then
        base_version=$(echo "$version_spec" | cut -c2-)
        determined_version=$(find_highest_patch_for_major "$base_version")

    # Specified greater than major version (e.g., ">=8")
    elif echo "$version_spec" | grep -qE '^>=[0-9]+$'; then
        base_version=$(echo "$version_spec" | cut -c3-)
        determined_version=$(find_highest_patch_for_major "$base_version")

    else
        # If none of the above, use default
        echo determined_version="$DEFAULT_PNPM_VERSION"
        return
    fi

    if [ -z "$determined_version" ] || [ "$determined_version" = "No matching versions found for criteria specified" ]; then
        echo "not_found"
        return 1
    else
        echo "$determined_version"
    fi
}

find_higher_version() {
    local major_version=$(echo "$1" | cut -d'.' -f1)
    local minor_version=$(echo "$1" | cut -d'.' -f2)
    local patch_version=$(echo "$1" | cut -d'.' -f3)

    # Filter by major version
    local matching_major_versions=$(filter_major_versions "$major_version")
    if [ -z "$matching_major_versions" ]; then
        echo "No matching versions found for criteria specified"
        return 1 # Exit the function early
    fi

    # Filter by minor version
    local matching_minor_versions=$(filter_minor_versions "$minor_version" "$matching_major_versions")
    if [ -z "$matching_minor_versions" ]; then
        echo "No matching versions found for criteria specified"
        return 1 # Exit the function early
    fi

    # Filter for higher patch versions
    local matching_patch_versions=$(filter_higher_patch_versions "$patch_version" "$matching_minor_versions")
    if [ -z "$matching_patch_versions" ]; then
        echo "No matching versions found for criteria specified"
        return 1 # Exit the function early
    fi

    highest_version=$(get_highest_version "$matching_patch_versions")

    echo "$highest_version"

}

find_higher_or_equal_version() {
    local major_version=$(echo "$1" | cut -d'.' -f1)
    local minor_version=$(echo "$1" | cut -d'.' -f2)
    local patch_version=$(echo "$1" | cut -d'.' -f3)

    # Filter by major version
    local matching_major_versions=$(filter_major_versions "$major_version")
    if [ -z "$matching_major_versions" ]; then
        echo "No matching versions found for criteria specified"
        return 1 # Exit the function early
    fi

    # Filter by minor version
    local matching_minor_versions=$(filter_minor_versions "$minor_version" "$matching_major_versions")
    if [ -z "$matching_minor_versions" ]; then
        echo "No matching versions found for criteria specified"
        return 1 # Exit the function early
    fi

    # Filter for higher patch versions
    local matching_patch_versions=$(filter_equal_or_higher_patch_versions "$patch_version" "$matching_minor_versions")
    if [ -z "$matching_patch_versions" ]; then
        echo "No matching versions found for criteria specified"
        return 1 # Exit the function early
    fi

    highest_version=$(get_highest_version "$matching_patch_versions")

    echo "$highest_version"

}

find_highest_patch_for_minor() {
    local major_version=$(echo "$1" | cut -d'.' -f1)
    local minor_version=$(echo "$1" | cut -d'.' -f2)

    # Filter by major version
    local matching_major_versions=$(filter_major_versions "$major_version")
    if [ -z "$matching_major_versions" ]; then
        echo "No matching versions found for criteria specified"
        return 1 # Exit the function early
    fi

    # Filter by minor version
    local matching_minor_versions=$(filter_minor_versions "$minor_version" "$matching_major_versions")
    if [ -z "$matching_minor_versions" ]; then
        echo "No matching versions found for criteria specified"
        return 1 # Exit the function early
    fi

    highest_version=$(get_highest_version "$matching_minor_versions")

    echo "$highest_version"

}

find_highest_patch_for_major() {
    local major_version=$(echo "$1" | cut -d'.' -f1)

    # Filter by major version
    local matching_major_versions=$(filter_major_versions "$major_version")
    if [ -z "$matching_major_versions" ]; then
        echo "No matching versions found for criteria specified"
        return 1 # Exit the function early
    fi

    highest_version=$(get_highest_version "$matching_major_versions")

    echo "$highest_version"

}

## Take in a list and a filter number 
filter_major_versions() {
    local major_version="$1"
    local filtered_versions=""

    for version in $INSTALLED_VERSIONS; do
        if [ "$(echo "$version" | cut -d'.' -f1)" = "$major_version" ]; then
            filtered_versions="$filtered_versions $version"
        fi
    done

    echo "$filtered_versions"
}

## Take in a list and a filter number
# Function to filter versions by minor version number
filter_minor_versions() {
    local minor_version="$1"
    shift # Remove the minor version from the arguments
    local versions="$@" # All remaining arguments are considered versions
    local filtered_versions=""

    for version in $versions; do
        # Extract the minor version part and compare
        if [ "$(echo "$version" | cut -d'.' -f2)" = "$minor_version" ]; then
            filtered_versions="$filtered_versions $version"
        fi
    done

    echo "$filtered_versions"
}

# Function to filter for patch versions strictly higher than a given base patch version
filter_higher_patch_versions() {
    local base_patch="$1"
    shift # Remove the minor version from the arguments
    local filtered_major_versions="$@" # All remaining arguments are considered versions
    local higher_patches=""

    for version in $filtered_major_versions; do
        # Extract the patch number
        local patch=$(echo "$version" | cut -d'.' -f3)
        if [ "$patch" -gt "$base_patch" ]; then
            higher_patches="$higher_patches $version"
        fi
    done

    echo "$higher_patches"
}

# Function to filter for patch versions equal to or higher than a given base patch version
filter_equal_or_higher_patch_versions() {
    local base_patch="$1"
    shift # Remove the minor version from the arguments
    local filtered_minor_versions="$@" # All remaining arguments are considered versions
    local equal_or_higher_patches=""

    for version in $filtered_minor_versions; do
        # Extract the patch number
        local patch=$(echo "$version" | cut -d'.' -f3)
        if [ "$patch" -ge "$base_patch" ]; then
            equal_or_higher_patches="$equal_or_higher_patches $version"
        fi
    done

    echo "$equal_or_higher_patches"
}

get_highest_version() {
    # Assuming versions are passed as a space-separated string
    versions="$@"
    
    # Sort versions and return the highest one
    printf "%s\n" $versions | sed 's/\./-/g' | sort -t '-' -k 1,1n -k 2,2n -k 3,3n | sed 's/-/\./g' | tail -n 1
}