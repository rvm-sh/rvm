#!/bin/sh

# Define the default and latest versions of bun
DEFAULT_BUN_VERSION="1.0.25"
ENABLE_AUTOCHECK="true"  # Control auto version check

INSTALLED_VERSIONS="1.0.25"

# Function to handle bun commands
bun() {
    # Check if auto version check is enabled
    if [ "$ENABLE_AUTOCHECK" = "true" ]; then
        # Proceed with version check
        if [ -f "package.json" ]; then
            # Check for jq
            if ! command -v jq > /dev/null 2>&1; then
                echo "jq not found, please install jq to use autocheck or disable autocheck."
                use_bun_version "$DEFAULT_BUN_VERSION" "$@"
                return
            fi
            
            # Extract the bun version from package.json
            local bun_version_specified
            bun_version_specified=$(jq -r '.engines.bun // empty' package.json)

            if [ -z "$bun_version_specified" ]; then
                echo "No bun version specified in package.json. Using the default version."
                use_bun_version "$DEFAULT_BUN_VERSION" "$@"
                return
            fi

            # Determine the bun version to use
            local version_to_use
            version_to_use=$(determine_bun_version "$bun_version_specified")
            use_bun_version "$version_to_use" "$@"
            return
        else
            echo "package.json not found. Using the default bun version."
        fi
    fi

    # Fallback or if autocheck is disabled
    use_bun_version "$DEFAULT_BUN_VERSION" "$@"
}

# Function to use a specific bun version
use_bun_version() {
    local version="$1"
    if [ "$version" = "not_found" ]; then
        echo "No matching version found for specified criteria. Exiting without defaulting to the default version."
        return 1
    fi

    shift  # Remove version from the arguments
    local bun_executable="${HOME}/.bun/v${version}/bun"

    if [ -f "$bun_executable" ]; then
        echo "Using bun version: $version"
        $bun_executable "$@"
    else
        echo "bun version $version not found. Please install this version before running the command."
        return 1
    fi
}

# Function to determine the bun version to use based on the specification
determine_bun_version() {
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
        echo determined_version="$DEFAULT_BUN_VERSION"
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
    local major_version
    local minor_version
    local patch_version
    major_version=$(echo "$1" | cut -d'.' -f1)
    minor_version=$(echo "$1" | cut -d'.' -f2)
    patch_version=$(echo "$1" | cut -d'.' -f3)

    # Filter by major version
    local matching_major_versions
    matching_major_versions="$(filter_major_versions "$major_version")"
    if [ -z "$matching_major_versions" ]; then
        echo "No matching versions found for criteria specified"
        return 1 # Exit the function early
    fi

    # Filter by minor version
    local matching_minor_versions
    matching_minor_versions="$(filter_minor_versions "$minor_version" "$matching_major_versions")"
    if [ -z "$matching_minor_versions" ]; then
        echo "No matching versions found for criteria specified"
        return 1 # Exit the function early
    fi

    # Filter for higher patch versions
    local matching_patch_versions
    matching_patch_versions="$(filter_higher_patch_versions "$patch_version" "$matching_minor_versions")"
    if [ -z "$matching_patch_versions" ]; then
        echo "No matching versions found for criteria specified"
        return 1 # Exit the function early
    fi

    local highest_version
    highest_version="$(get_highest_version "$matching_patch_versions")"

    echo "$highest_version"

}

find_higher_or_equal_version() {
    local major_version
    local minor_version
    local patch_version
    major_version="$(echo "$1" | cut -d'.' -f1)"
    minor_version=$(echo "$1" | cut -d'.' -f2)
    patch_version=$(echo "$1" | cut -d'.' -f3)

    # Filter by major version
    local matching_major_versions
    matching_major_versions=$(filter_major_versions "$major_version")
    if [ -z "$matching_major_versions" ]; then
        echo "No matching versions found for criteria specified"
        return 1 # Exit the function early
    fi

    # Filter by minor version
    local matching_minor_versions
    matching_minor_versions=$(filter_minor_versions "$minor_version" "$matching_major_versions")
    if [ -z "$matching_minor_versions" ]; then
        echo "No matching versions found for criteria specified"
        return 1 # Exit the function early
    fi

    # Filter for higher patch versions
    local matching_patch_versions
    matching_patch_versions=$(filter_equal_or_higher_patch_versions "$patch_version" "$matching_minor_versions")
    if [ -z "$matching_patch_versions" ]; then
        echo "No matching versions found for criteria specified"
        return 1 # Exit the function early
    fi

    local highest_version
    highest_version=$(get_highest_version "$matching_patch_versions")

    echo "$highest_version"

}

find_highest_patch_for_minor() {
    local major_version
    local minor_version
    major_version=$(echo "$1" | cut -d'.' -f1)
    minor_version=$(echo "$1" | cut -d'.' -f2)

    # Filter by major version
    local matching_major_versions
    matching_major_versions=$(filter_major_versions "$major_version")
    if [ -z "$matching_major_versions" ]; then
        echo "No matching versions found for criteria specified"
        return 1 # Exit the function early
    fi

    # Filter by minor version
    local matching_minor_versions
    matching_minor_versions=$(filter_minor_versions "$minor_version" "$matching_major_versions")
    if [ -z "$matching_minor_versions" ]; then
        echo "No matching versions found for criteria specified"
        return 1 # Exit the function early
    fi

    local highest_version
    highest_version=$(get_highest_version "$matching_minor_versions")

    echo "$highest_version"

}

find_highest_patch_for_major() {
    local major_version
    major_version=$(echo "$1" | cut -d'.' -f1)

    # Filter by major version
    local matching_major_versions
    matching_major_versions=$(filter_major_versions "$major_version")
    if [ -z "$matching_major_versions" ]; then
        echo "No matching versions found for criteria specified"
        return 1 # Exit the function early
    fi

    local highest_version
    highest_version=$(get_highest_version "$matching_major_versions")

    echo "$highest_version"

}

## Take in a list and a filter number 
filter_major_versions() {
    local major_version
    local filtered_versions

    major_version="$1"

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
    local minor_version
    minor_version="$1"
    shift # Remove the minor version from the arguments
    local versions
    versions="$*"
    local filtered_versions

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
    shift # Remove the base patch version from the arguments
    local versions="$*" # Concatenate all remaining arguments into a single string
    local higher_patches=""

    for version in $versions; do
        # Extract the patch number
        local patch
        patch=$(echo "$version" | cut -d'.' -f3)
        if [ "$patch" -gt "$base_patch" ]; then
            higher_patches="$higher_patches $version"
        fi
    done

    echo "$higher_patches"
}


# Function to filter for patch versions equal to or higher than a given base patch version
filter_equal_or_higher_patch_versions() {
    local base_patch="$1"
    shift # Remove the base patch version from the arguments
    local versions="$*" # Concatenate all remaining arguments into a single string
    local equal_or_higher_patches=""

    for version in $versions; do
        # Extract the patch number
        local patch
        patch=$(echo "$version" | cut -d'.' -f3)
        if [ "$patch" -ge "$base_patch" ]; then
            equal_or_higher_patches="$equal_or_higher_patches $version"
        fi
    done

    echo "$equal_or_higher_patches"
}


get_highest_version() {
    # Concatenate all arguments into a single space-separated string
    local versions="$*"
    
    # Sort versions and return the highest one
    printf "%s\n" "$versions" | sed 's/\./-/g' | sort -t '-' -k 1,1n -k 2,2n -k 3,3n | sed 's/-/\./g' | tail -n 1
}
