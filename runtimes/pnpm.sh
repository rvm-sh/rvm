#!/bin/sh

download() {
  if command -v curl > /dev/null 2>&1; then
    curl -fsSL "$1"
  else
    wget -qO- "$1"
  fi
}

install() {
    # Check for at least one argument
    if [ -z "$1" ]; then
        help_install
        return 1
    fi


    # Determine os and arch
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    case "$os" in
        darwin) os="macos" ;;
        linux) os="linux" ;;
        *) 
            echo "Sorry, your distribution is not supported by pnpm" 
            return 1
            ;;
    esac
    echo "OS detected: ${os}"

    local arch=$(uname -m)
    echo "Arch detected: ${arch}"
    case "${arch}" in
        x86_64 | amd64) arch="x64" ;;
        aarch64 | arm64) arch="arm64" ;;
        *)
            echo "Sorry, your architecture is not supported by pnpm"
            return 1
            ;;
    esac

    # determine the version to install
    local requested_version="$1"
    local major_version_requested="$2"

    if [[ $requested_version == latest ]]; then
        if [[ $major_version_requested -ne 0 ]]; then
            read -r install_version link <<< $(get_latest_major_version "$major_version_requested" "$os" "$arch")

        else
            read -r install_version link <<< $(get_latest_pnpm_version "$os" "$arch")
        fi

        if [ -z "$install_version" ] || [ -z "$link" ]; then
            echo "Failed to find the latest pnpm version for $os $arch"
            return 1
        fi
        echo "Latest version requested. Installing pnpm ${install_version}"
    elif [[ $requested_version =~ ^[0-9]+$ ]]; then
        read -r install_version link <<< $(get_latest_major_version $major_version_requested $os $arch)

        if [ -z "$install_version" ] || [ -z "$link" ]; then
            echo "Failed to find the latest pnpm version for $os $arch"
            return 1
        fi

    elif [[ $requested_version == next ]]; then
        read -r install_version link <<< $(get_next_major_version $major_version_requested $os $arch)

        if [ -z "$install_version" ] || [ -z "$link" ]; then
            echo "Failed to find the latest pnpm version for $os $arch"
            return 1
        fi

    elif [[ $requested_version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        version="${requested_version}"
        link="https://github.com/pnpm/pnpm/releases/download/v${requested_version}/pnpm-${os}-${arch}"
        echo "$version $link"
        return 0


    else
        echo "Invalid version specification: $requested_version"
        return 1
    fi

    install_specific_version $install_version $link
}

get_latest_pnpm_version() {
    local os="$1"
    local arch="$2"

    version_json="$(download "https://registry.npmjs.org/@pnpm/exe")" || abort "Download Error!"
    version="$(printf '%s' "${version_json}" | tr '{' '\n' | awk -F '"' '/latest/ { print $4 }')"
    link="https://github.com/pnpm/pnpm/releases/download/v${version}/pnpm-${os}-${arch}"

    echo "$version $link"
    return 0
}


get_latest_major_version(){
    local major_version="$1"
    local os="$2"
    local arch="$3"

    if [ "$major_version" -lt 6 ]; then
        echo "Installing the latest major version for PNPM is only supported for pnpm 6 onwards"
        return 1
    fi

    version_json="$(download "https://registry.npmjs.org/@pnpm/exe")" || abort "Download Error!"
    version="$(printf '%s' "${version_json}" | tr '{' '\n' | awk -v major="$major_version" -F '"' '$0 ~ "latest-" major { print $4 }')"
    link="https://github.com/pnpm/pnpm/releases/download/v${version}/pnpm-${os}-${arch}"

    echo "$version $link"
    return 0
}

get_next_major_version() {
    local major_version="$1"
    local os="$2"
    local arch="$3"

    if [ "$major_version" -lt 6 ]; then
        echo "Installing next versions for PNPM is only supported for pnpm 6 onwards"
        return 1
    fi

    version_json="$(download "https://registry.npmjs.org/@pnpm/exe")" || abort "Download Error!"
    version="$(printf '%s' "${version_json}" | tr '{' '\n' | awk -v major="$major_version" -F '"' '$0 ~ "next-" major { print $4 }')"
    link="https://github.com/pnpm/pnpm/releases/download/v${version}/pnpm-${os}-${arch}"

    echo "$version $link"
    return 0

}


# this is the final function call for install
# where we already determined the exact version we want
install_specific_version() {
    install_version=$1 
    link=$2

    # Check if .pnpm folder exists
    if [ ! -d "$HOME/.pnpm" ]; then
        mkdir -p "$HOME/.pnpm"
        echo "Created .pnpm folder in your home directory."
    fi


    # Check if folder named v<version> exists
    echo "Checking if version already exists..."
    version_folder="$HOME/.pnpm/v${install_version}"
        if [ -d "$version_folder" ]; then
        echo "pnpm version $install_version is already installed. To reinstall, remove this version first"
        return 1
    fi


    # Download the file using wget
    echo "Downloading file..."
    download_dir="$HOME/.pnpm/v${install_version}"
    if [ ! -d "$download_dir" ]; then
        mkdir -p "$download_dir"
    fi
    
    wget -qO "$download_dir/pnpm" "$link"
    if [ $? -ne 0 ]; then
        echo "Failed to download the file."
        return 1
    fi

    echo "Download complete."

    # Add pnpm path to PATH variable
    echo "Updating bash PATH settings"
    # Check for existing line and either update or create it
    if grep -q "export PATH=\$HOME/.pnpm/v[^:]*/bin:\$PATH" ~/.bashrc; then
    # Update existing line
        sed -i "s|export PATH=\$HOME/.pnpm/v[^:]*/bin:\$PATH|export PATH=\$HOME/.pnpm/v$install_version/bin:\$PATH|" ~/.bashrc
    else
    # Create new line with comments
        echo "# START RVM PNPM PATH" >> ~/.bashrc
        echo "export PATH=\$HOME/.pnpm/$install_version/bin:\$PATH" >> ~/.bashrc
        echo "# END RVM PNPM PATH" >> ~/.bashrc
    fi

    source ~/.bashrc
}

uninstall() {
    # Define variables
    version="$1"  # Get the version to uninstall from the first argument
    version_folder="$HOME/.pnpm/v$version"

    # Check if the version is installed
    if [ ! -d "$version_folder" ]; then
        echo "pnpm version $version is not found"
        help_uninstall
        return 1
    fi

    # Remove the version folder
    rm -rf "$version_folder"
    if [ $? -ne 0 ]; then
        echo "Error removing pnpm version $version."
        return 1
    fi

    

    # Check if the uninstalled version was set in PATH
    current_path=$(echo $PATH | grep -oP "/.pnpm/v\K[^:]*(?=/bin)")
    echo "Current path:#${current_path}#"
    echo "Version:#${version}#"
    if [[ "$current_path" =~ "$version" ]]; then
        echo "version matches path"
        # Find the latest installed version
        latest_version=$(find "$HOME/.pnpm" -maxdepth 1 -type d -name "v*" | sed 's|.*/||' | sort -V | tail -n1)

        # Check if any versions remain
        echo "Latest version: ${latest_version}"
        if [[ -z "$latest_version" ]]; then
            # No versions left, remove PATH section
            sed -i '/^# START RVM PNPM PATH$/,/^# END RVM PNPM PATH$/d' ~/.bashrc
            source ~/.bashrc
            echo "No remaining pnpm versions found. Removed PATH section entirely."
        else
            # Update PATH with the latest version
            sed -i "s|/.pnpm/v$current_path/bin|/.pnpm/$latest_version/bin|g" ~/.bashrc
            source ~/.bashrc
            echo "PATH updated to use pnpm version $latest_version."
        fi
    else
        echo "Version does not match path, no changes to PATH settings"
    fi

    # Unset the version path from PATH
    PATH="${PATH%%:$HOME/.pnpm/$version/bin}"PNPM
    export PATH

    source ~/.bashrc

    echo "pnpm version $version uninstalled successfully."
}

prune() {
    if [ -z "$1" ]; then
        echo "Usage: rvm prune pnpm [version]"
        echo "version can be a major version (e.g., 8), a major.minor version (e.g., 8.10), or a specific version (e.g., 8.10.1)"
        return 1
    fi

    local requested_version="$1"
    local pruned_version=""
    local available_versions=()
    local default_version=""
    local new_default_version=""

    # List all installed versions
    for dir in "$HOME/.pnpm"/v*; do
        if [ -d "$dir" ]; then
            available_versions+=("$(basename "$dir")")
        fi
    done

    # Determine the default version from .bashrc if set
    if grep -q '# START RVM PNPM PATH' ~/.bashrc; then
        default_version=$(grep 'export PATH=$HOME/.pnpm/' ~/.bashrc | grep -o 'v[0-9.]\+')
    fi

    # Prune older versions
    for version in "${available_versions[@]}"; do
        if [[ "$version" < "v${requested_version}" ]]; then
            echo "Removing $version..."
            rm -rf "$HOME/.pnpm/$version"
            pruned_version="$version"
        fi
    done

    # If the default version was pruned, set a new default version
    if [[ ! -z "$pruned_version" && "$default_version" == "$pruned_version" ]]; then
        # Find the latest version as new default
        new_default_version=$(find "$HOME/.pnpm" -maxdepth 1 -type d -name "v*" | sort -V | tail -n1 | xargs basename)
        
        if [[ ! -z "$new_default_version" ]]; then
            local pnpm_path="$HOME/.pnpm/$new_default_version/bin"
            # Update .bashrc with new default version
            if grep -q '# START RVM PNPM PATH' ~/.bashrc; then
                sed -i "/# START RVM PNPM PATH/,/# END RVM PNPM PATH/{s|export PATH=\$HOME/.pnpm/v[^:]*/bin:\$PATH|export PATH=$pnpm_path:\$PATH|}" ~/.bashrc
            fi
            echo "Default pnpm version updated to $new_default_version"
        fi
    elif [[ -z "$pruned_version" ]]; then
        echo "No versions were pruned."
    else
        echo "pnpm versions older than $requested_version were removed."
    fi

    source ~/.bashrc
}

showall() {
  # Accept and validate the argument
  case "$1" in
    installed)
        type -t rvm >/dev/null && versions=$(find "$HOME/.pnpm" -maxdepth 1 -type d -name "v*")
        # Check if any versions were found
        if [[ -z "$versions" ]]; then
            echo "No pnpm versions are installed."
            return 0
        fi
        # Print each version with the corresponding pnpm command
        echo "These are all the pnpm versions installed"
        for version_folder in $versions; do
            version=$(basename "$version_folder")
            version=$(echo "$version" | cut -d'v' -f2-)

            echo "Version: $version"
            echo "  Command to set temporarily: rvm use pnpm $version"
            echo "  Command to set as default: rvm set pnpm $version"
        done
        ;;
    available)
        #
        echo "This functionality hasn't been implemented yet"
        ;;
    *)
      help_showall
      return 1
      ;;
  esac
}

removeall() {
    echo "Uninstalling all pnpm versions..."

    # Delete the .pnpm folder
    if [ -d "$HOME/.pnpm" ]; then
        echo "Removing the .pnpm folder..."
        rm -rf "$HOME/.pnpm"
        echo ".pnpm folder removed successfully."
    else
        echo "No .pnpm folder found. Skipping removal."
    fi

    # Delete the setting in the .bashrc file
    if grep -q '# START RVM PNPM PATH' ~/.bashrc; then
        echo "Removing pnpm path settings from .bashrc..."
        sed -i '/# START RVM PNPM PATH/,/# END RVM PNPM PATH/d' ~/.bashrc
        echo "pnpm path settings removed from .bashrc."
    else
        echo "pnpm path settings not found in .bashrc. Skipping removal."
    fi

    echo "All pnpm versions and settings have been uninstalled successfully."
}

update() {
    # Check for at least one argument
    if [ -z "$1" ]; then
        help_update
        return 1
    fi

    case "$1" in
        current)
            # Extract the current default pnpm version from PATH
            current_major_version=$(echo $PATH | grep -oP "\.pnpm/v\K[0-9]+(?=\.[0-9]+/[0-9]+/bin)")
            if [ -z "$current_major_version" ]; then
                echo "No default pnpm version found in PATH. Consider specifying a version to update."
                return 1
            fi

            # Call install function with the major version of the current default pnpm version
            echo "Updating pnpm within the major version line: $current_major_version"
            install "$current_major_version"
            ;;
        latest)
            # Directly call install with 'latest'
            install latest
            ;;

        *)
            # Handle specific version updates: pnpm 8, pnpm 8.10.0, etc.
            install "$1"
            ;;
    esac
}

use() {
    if [ -z "$1" ]; then
        help_use
        return 1
    fi

    local requested_version="$1"
    local version_folder=""
    local match_version=""

    # Handle different version specifications
    if [[ "$requested_version" =~ ^[0-9]+$ ]]; then
        # Major version: find the latest installed version of this major
        match_version=$(find "$HOME/.pnpm" -maxdepth 1 -type d -name "v${requested_version}.*" | sort -V | tail -n1)
    elif [[ "$requested_version" =~ ^[0-9]+\.[0-9]+$ ]]; then
        # Major.minor version: find the latest installed version of this major.minor
        match_version=$(find "$HOME/.pnpm" -maxdepth 1 -type d -name "v${requested_version}.*" | sort -V | tail -n1)
    elif [[ "$requested_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        # Specific version: use this specific version
        match_version="$HOME/.pnpm/v${requested_version}"
    fi

    if [ -z "$match_version" ] || [ ! -d "$match_version" ]; then
        echo "pnpm version matching '$requested_version' is not installed."
        return 1
    fi

    version_folder=$(basename "$match_version")

    # Construct the path to the pnpm binaries for the matched version
    local pnpm_path="$HOME/.pnpm/$version_folder/bin"

    # Add the matched pnpm version to the beginning of the PATH for the current session
    PATH="$pnpm_path:$PATH"

    echo "Using pnpm $version_folder. This change is temporary and will reset after the terminal session ends."
    # Optionally, you can display the version being used by executing 'pnpm -v'
    pnpm -v
}

set() {
    if [ -z "$1" ]; then
        help_set
        return 1
    fi

    local requested_version="$1"
    local version_folder=""
    local match_version=""

    # Handle different version specifications
    if [[ "$requested_version" =~ ^[0-9]+$ ]]; then
        # Major version: find the latest installed version of this major
        match_version=$(find "$HOME/.pnpm" -maxdepth 1 -type d -name "v${requested_version}.*" | sort -V | tail -n1)
    elif [[ "$requested_version" =~ ^[0-9]+\.[0-9]+$ ]]; then
        # Major.minor version: find the latest installed version of this major.minor
        match_version=$(find "$HOME/.pnpm" -maxdepth 1 -type d -name "v${requested_version}.*" | sort -V | tail -n1)
    elif [[ "$requested_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        # Specific version: use this specific version
        match_version="$HOME/.pnpm/v${requested_version}"
    fi

    if [ -z "$match_version" ] || [ ! -d "$match_version" ]; then
        echo "pnpm version matching '$requested_version' is not installed."
        return 1
    fi

    version_folder=$(basename "$match_version")

    # Construct the path to the pnpm binaries for the matched version
    local pnpm_path="$match_version/bin"

    # Check if the .bashrc already contains pnpm path settings and replace them
    if grep -q '# START RVM PNPM PATH' ~/.bashrc; then
        # The .bashrc contains existing pnpm path settings; replace them
        sed -i "/# START RVM PNPM PATH/,/# END RVM PNPM PATH/{s|export PATH=\$HOME/.pnpm/v[^:]*/bin:\$PATH|export PATH=$pnpm_path:\$PATH|}" ~/.bashrc
    else
        # The .bashrc does not contain pnpm path settings; add them
        echo "# START RVM PNPM PATH" >> ~/.bashrc
        echo "export PATH=$pnpm_path:\$PATH" >> ~/.bashrc
        echo "# END RVM PNPM PATH" >> ~/.bashrc
    fi

    source ~/.bashrc

    echo "pnpm $version_folder has been set as your default pnpm version"
}


help_install () {
    cat <<EOF
    To use this command, you can type in:
    Latest(as specified by pnpm):
    rvm install pnpm latest

    Latest of major version:
    rvm install pnpm 8
    rvm install pnpm latest 8

    Next version for a major version
    rvm install pnpm next 8

    Specific version:
    rvm install pnpm 8.15.3

    Note that latest major.minor version is unsupported for pnpm
EOF

}

help_uninstall () {
    cat <<EOF
    This function only supports uninstalling specific versions of pnpm
    To use this command, you can type in:

    rvm uninstall pnpm <pnpm version>

    You can also use uninstallall or prune functions if required
    
EOF
    
}

help_showall () {
    cat <<EOF
    To use this command, you can type in:
    Show all installed
    rvm showall pnpm installed

    *Show all available at pnpm repository for installation
    rvm showall pnpm available

    *Show all available major version at pnpm repository for installation
    rvm showall pnpm available 8

    *These 2 functionalities have not yet been implemented for pnpm
EOF

}

help_update () {
    cat <<EOF
    To use this command, you can type in:
    Update current default version(with latest of the same major version)
    rvm update pnpm current

    Update the latest version of pnpm (as per the pnpm website)
    rvm update pnpm latest

    Update a specific major version of pnpm
    rvm update pnpm 8

    The update function will call the install function.
    If a version does not exist, it will proceed to install it

    Note that on completion, the path to the version will be set to the new installed version
EOF

}

help_use () {
    cat <<EOF
    This command sets a specific specified version temporarily.
    The default version will revert back to the one set in your terminal settings file once you restart your terminal

    To change your default permanetly, call the rvm set pnpm <version>

    To use this command, you can type in:
    Latest installed of major version
    rvm use pnpm 18

    Latest installed of major/minor version
    rvm use pnpm 8.10

    Specific version
    rvm use pnpm 8.10.0

    rvm currently does not track latest / next versions locally, so it does not know which
    are latest / next versions and which aren't
EOF

}

help_set () {
    cat <<EOF
    This command sets the default version in your system.

    To change your default temporarily, call the rvm use pnpm <version>

    To use this command, you can type in:
    Latest installed of major version
    rvm set pnpm 8

    Latest installed of major/minor version
    rvm set pnpm 8.10

    Specific version
    rvm set pnpm 8.10.0

    rvm currently does not track latest / next versions locally, so it does not know which
    are latest / next versions and which aren't
EOF

}