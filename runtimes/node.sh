#!/bin/sh

install() {
    # Check for at least one argument
    if [ -z "$1" ]; then
        help_install
        return 1
    fi


    # Determine os and arch
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    echo "OS detected: ${os}"
    local arch=$(uname -m)
    echo "Arch detected: ${arch}"
    case "$arch" in
        x86_64) arch="x64" ;;
        aarch64) arch="arm64" ;;
    esac

    # determine the version to install
    local requested_version="$1"
    if [[ $requested_version == latest ]]; then
        
        read -r install_version link <<< $(get_latest_node_version "$os" "$arch")

        if [ -z "$install_version" ] || [ -z "$link" ]; then
            echo "Failed to find the latest Node.js version for $os $arch"
            return 1
        fi
        echo "Latest version requested. Installing node ${install_version}"
    elif [[ $requested_version =~ ^[0-9]+$ ]]; then
        read -r install_version link <<< $(get_latest_major_version $requested_version $os $arch)

        if [ -z "$install_version" ] || [ -z "$link" ]; then
            echo "Failed to find the latest Node.js version for $os $arch"
            return 1
        fi
    elif [[ $requested_version =~ ^[0-9]+\.[0-9]+$ ]]; then
        read -r install_version link <<< $(get_latest_major_minor_version $requested_version $os $arch)

        if [ -z "$install_version" ] || [ -z "$link" ]; then
            echo "Failed to find the latest Node.js version for $os $arch"
            return 1
        fi

    elif [[ $requested_version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        file_name="node-v${requested_version}-${os}-${arch}.tar.gz"
        install_version="v${requested_version}"
        link="https://nodejs.org/download/release/v${requested_version}/${file_name}"

    elif [[ $requested_version =~ ^latest- ]]; then
        read -r install_version link <<< $(get_latest_lts_version $requested_version $os $arch)

        echo "Latest requested version for ${requested_version} determined: ${install_version}"
    else
        echo "Invalid version specification: $requested_version"
        return 1
    fi

    install_specific_version $install_version $link
}

get_latest_node_version() {
    local os="$1"
    local arch="$2"
    local url="https://nodejs.org/dist/latest/"

    # Use wget to fetch the directory listing
    local html_content=$(wget -qO- "$url")

    # Initialize an empty string for the version and link
    local version=""
    local link=""

    # Parse the latest version and corresponding download link
    echo "$html_content" | grep -Eo 'node-v[0-9.]+-'${os}'-'${arch}'\.tar\.gz' | while read -r line; do
        if [[ "$line" =~ node-v[0-9.]+-${os}-${arch}\.tar\.gz ]]; then
            # Extract version including the 'v' prefix
            version=$(echo "$line" | grep -Eo 'v[0-9.]+')
            link="${url}${line}"
            echo "$version $link"
            return 0  # Ensure to return 0 to signal success
        fi
    done

    # Check if the version and link were found
    if [[ -z "$version" || -z "$link" ]]; then
        echo "Failed to find the latest Node.js version for $os $arch"
        return 1
    fi
}


get_latest_major_version(){
    local major_version="$1"
    local os="$2"
    local arch="$3"
    local url="https://nodejs.org/download/release/latest-v${major_version}.x/"

    # Use wget to fetch the directory listing
    local html_content=$(wget -qO- "$url")

    # Initialize an empty string for the version and link
    local version=""
    local link=""

    # Parse the latest version and corresponding download link
    echo "$html_content" | grep -Eo 'node-v[0-9.]+-'${os}'-'${arch}'\.tar\.gz' | while read -r line; do
        if [[ "$line" =~ node-v[0-9.]+-${os}-${arch}\.tar\.gz ]]; then
            # Extract version including the 'v' prefix
            version=$(echo "$line" | grep -Eo 'v[0-9.]+')
            link="${url}${line}"
            echo "$version $link"
            return 0  # Ensure to return 0 to signal success
        fi
    done

    # Check if the version and link were found
    if [[ -z "$version" || -z "$link" ]]; then
        echo "Failed to find the latest Node.js version for $os $arch"
        return 1
    fi
}

get_latest_major_minor_version() {
    local major_minor_version="$1"
    local os="$2"
    local arch="$3"
    local url="https://nodejs.org/download/release/index.tab"

    # Fetch and parse the index.tab for the latest patch version of the major.minor version
    local version_info=$(wget -qO- "$url" | awk -v ver="$major_minor_version" -F'\t' '
    $1 ~ "^v" ver { print $1 }
    ' | sort -V | tail -n1)

    if [ -z "$version_info" ]; then
        echo "Failed to find the latest Node.js version with major.minor version $major_minor_version"
        return 1
    fi

    local version=$(echo "$version_info" | grep -Eo 'v[0-9.]+')
    local file_name="node-${version}-${os}-${arch}.tar.gz"
    local link="https://nodejs.org/download/release/${version}/${file_name}"

    echo "$version $link"
}



get_latest_lts_version() {
    local lts_version="$1"
    local os="$2"
    local arch="$3"
    local url="https://nodejs.org/download/release/${lts_version}/"

    # Use wget to fetch the directory listing
    local html_content=$(wget -qO- "$url")

    # Initialize an empty string for the version and link
    local version=""
    local link=""

    # Parse the latest version and corresponding download link
    echo "$html_content" | grep -Eo 'node-v[0-9.]+-'${os}'-'${arch}'\.tar\.gz' | while read -r line; do
        if [[ "$line" =~ node-v[0-9.]+-${os}-${arch}\.tar\.gz ]]; then
            # Extract version including the 'v' prefix
            version=$(echo "$line" | grep -Eo 'v[0-9.]+')
            link="${url}${line}"
            echo "$version $link"
            return 0  # Ensure to return 0 to signal success
        fi
    done

    # Check if the version and link were found
    if [[ -z "$version" || -z "$link" ]]; then
        echo "Failed to find the latest Node.js version for $os $arch"
        return 1
    fi
}


# this is the final function call for install
# where we already determined the exact version we want
install_specific_version() {
    install_version=$1 
    link=$2

    # Check if .node folder exists
    if [ ! -d "$HOME/.node" ]; then
        mkdir -p "$HOME/.node"
        echo "Created .node folder in your home directory."
    fi


    # Check if folder named v<version> exists
    echo "Checking if version already exists..."
    version_folder="$HOME/.node/${install_version}"
        if [ -d "$version_folder" ]; then
        echo "Node.js version $install_version is already installed. To reinstall, remove this version first"
        return 1
    fi


    # Download the file using wget
    echo "Downloading file..."
    download_dir="$HOME/.node/downloads"
    if [ ! -d "$download_dir" ]; then
        mkdir -p "$download_dir"
    fi
    
    wget -qO "$download_dir/node.tar.gz" "$link"
    if [ $? -ne 0 ]; then
        echo "Failed to download the file."
        return 1
    fi

    echo "Download complete. Installing version."
    mkdir -p "$version_folder"

    # unzip the file, rename the folder to its version (ie, v20.11.0)
    # Use tar to extract with custom directory name
    tar -xzf "$download_dir/node.tar.gz" -C "$version_folder" --strip-components=1


    #Delete the downloaded file
    echo "Install complete. Clearing up download file"
    rm -f "$download_dir/node.tar.gz"

    # Add Node.js path to PATH variable
    echo "Updating bash PATH settings"
    # Check for existing line and either update or create it
    if grep -q "export PATH=\$HOME/.node/v[^:]*/bin:\$PATH" ~/.bashrc; then
    # Update existing line
        sed -i "s|export PATH=\$HOME/.node/v[^:]*/bin:\$PATH|export PATH=\$HOME/.node/$install_version/bin:\$PATH|" ~/.bashrc
    else
    # Create new line with comments
        echo "# START RVM NODE PATH" >> ~/.bashrc
        echo "export PATH=\$HOME/.node/$install_version/bin:\$PATH" >> ~/.bashrc
        echo "# END RVM NODE PATH" >> ~/.bashrc
    fi

    # Update default version if applicable
    if [[ "$install_version" == "$(get_latest_node_version "$os" "$arch")" ]]; then
        DEFAULT_NODE_VERSION="$install_version"
        echo "Setting default Node.js version to: $DEFAULT_NODE_VERSION"
    fi


    source ~/.bashrc
}

uninstall() {
    # Define variables
    version="$1"  # Get the version to uninstall from the first argument
    version_folder="$HOME/.node/v$version"

    # Check if the version is installed
    if [ ! -d "$version_folder" ]; then
        echo "Node.js version $version is not installed. Currently only specific versions of node can be uninstalled via this function"
        return 1
    fi

    # Remove the version folder
    rm -rf "$version_folder"
    if [ $? -ne 0 ]; then
        echo "Error removing Node.js version $version."
        return 1
    fi

    

    # Check if the uninstalled version was set in PATH
    current_path=$(echo $PATH | grep -oP "/.node/v\K[^:]*(?=/bin)")
    echo "Current path:#${current_path}#"
    echo "Version:#${version}#"
    if [[ "$current_path" =~ "$version" ]]; then
        echo "version matches path"
        # Find the latest installed version
        latest_version=$(find "$HOME/.node" -maxdepth 1 -type d -name "v*" | sed 's|.*/||' | sort -V | tail -n1)

        # Check if any versions remain
        echo "Latest version: ${latest_version}"
        if [[ -z "$latest_version" ]]; then
            # No versions left, remove PATH section
            sed -i '/^# START RVM NODE PATH$/,/^# END RVM NODE PATH$/d' ~/.bashrc
            source ~/.bashrc
            echo "No remaining Node.js versions found. Removed PATH section entirely."
        else
            # Update PATH with the latest version
            sed -i "s|/.node/v$current_path/bin|/.node/$latest_version/bin|g" ~/.bashrc
            source ~/.bashrc
            echo "PATH updated to use Node.js version $latest_version."
        fi
    else
        echo "Version does not match path, no changes to PATH settings"
    fi

    # Unset the version path from PATH
    PATH="${PATH%%:$HOME/.node/$version/bin}"
    export PATH

    source ~/.bashrc

    echo "Node.js version $version uninstalled successfully."
}

prune() {
    echo "Function prune not implemented yet"
#   # Define variables
#   current_version=$(node -v | cut -d' ' -f1)  # Get the currently installed version
#   version_folder="$HOME/.node/v$current_version"  # Folder path for current version

#   # Check if there are any versions installed
#   if [ ! -d "$version_folder" ]; then
#     echo "No Node.js versions are installed."
#     return 0
#   fi

#   # Find all installed versions excluding the current one
#   older_versions=$(find "$HOME/.node" -maxdepth 1 -type d -name "v*" | grep -vE "^$version_folder$")

#   # Check if any older versions exist
#   if [[ -z "$older_versions" ]]; then
#     echo "No Node.js versions older than $current_version found."
#     return 0
#   fi

#   # Confirm removal before proceeding
#   echo "The following Node.js versions will be removed:"
#   echo "$older_versions"
#   read -p "Are you sure you want to proceed? (y/N) " answer
#   if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
#     echo "Aborting prune operation."
#     return 0
#   fi

#   # Remove each older version folder
#   for version_folder in $older_versions; do
#     echo "Removing $version_folder"
#     rm -rf "$version_folder"
#     if [ $? -ne 0 ]; then
#       echo "Error removing $version_folder."
#       return 1
#     fi
#   done

#   echo "Successfully pruned older Node.js versions."
}

showall() {
  # Accept and validate the argument
  case "$1" in
    installed)
        type -t rvm >/dev/null && versions=$(find "$HOME/.node" -maxdepth 1 -type d -name "v*")
        # Check if any versions were found
        if [[ -z "$versions" ]]; then
            echo "No Node.js versions are installed."
            return 0
        fi
        # Print each version with the corresponding node command
        echo "These are all the node versions installed"
        for version_folder in $versions; do
            version=$(basename "$version_folder")
            version=$(echo "$version" | cut -d'v' -f2-)

            echo "Version: $version"
            echo "  Command to set temporarily: rvm use node $version"
            echo "  Command to set as default: rvm set node $version"
        done
        ;;
    available)
        # Download the index file and capture versions
        versions=$(wget -q -O - https://nodejs.org/download/release/index.tab | grep -Eo '^v[0-9]+\.[0-9]+\.[0-9]+' | sed 's/^v//')

        # Check if any versions were found
        if [[ -z "$versions" ]]; then
            echo "No Node.js versions available were found from nodejs.org. Check that access to the web is not restricted / affected."
            return 0
        fi

        # Initialize filtered_versions array
        declare -a filtered_versions

        # Check if user specified a major version filter
        if [[ $# -gt 1 && "$2" =~ ^[0-9]+$ ]]; then
        # Filter versions based on major version
        for version in $versions; do
            major_version="${version%%.*}"
            if [[ "$major_version" == "$2" ]]; then
            filtered_versions+=("$version")
            fi
        done

        # Handle no matching versions
        if [[ ${#filtered_versions[@]} -eq 0 ]]; then
            echo "No Node.js versions available with major version $2."
            return 0
        fi

        # Print filtered versions
        echo "Available Node.js versions with major version $2:"
        for version in "${filtered_versions[@]}"; do
            echo "  - $version"
        done
        else
        # No specific major version filter provided, print all available versions
        echo "All available Node.js versions:"
        for version in $versions; do
            echo "  - $version"
        done
        fi
        ;;
    *)
      help_showall
      return 1
      ;;
  esac
}



removeall() {
    echo "Uninstalling all Node.js versions..."

    # Delete the .node folder
    if [ -d "$HOME/.node" ]; then
        echo "Removing the .node folder..."
        rm -rf "$HOME/.node"
        echo ".node folder removed successfully."
    else
        echo "No .node folder found. Skipping removal."
    fi

    # Delete the setting in the .bashrc file
    if grep -q '# START RVM NODE PATH' ~/.bashrc; then
        echo "Removing Node.js path settings from .bashrc..."
        sed -i '/# START RVM NODE PATH/,/# END RVM NODE PATH/d' ~/.bashrc
        echo "Node.js path settings removed from .bashrc."
    else
        echo "Node.js path settings not found in .bashrc. Skipping removal."
    fi

    echo "All Node.js versions and settings have been uninstalled successfully."
}

update() {
    # Check for at least one argument
    if [ -z "$1" ]; then
        help_update
        return 1
    fi

    case "$1" in
        current)
            # Extract the current default Node.js version from PATH
            current_version=$(echo $PATH | grep -oP "\.node/v\K[0-9]+(?=\.[0-9]+/[0-9]+/bin)")
            if [ -z "$current_version" ]; then
                echo "No default Node.js version found in PATH. Consider specifying a version to update."
                return 1
            fi

            # Call install function with the major version of the current default Node.js version
            echo "Updating Node.js within the major version line: $current_version"
            install "$current_version"
            ;;
        latest)
            # Directly call install with 'latest'
            install latest
            ;;
        latest-*)
            # Handle LTS versions update: latest-hydrogen, latest-iron, etc.
            install "$1"
            ;;
        *)
            # Handle specific version updates: node 18, node 18.10, etc.
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
        match_version=$(find "$HOME/.node" -maxdepth 1 -type d -name "v${requested_version}.*" | sort -V | tail -n1)
    elif [[ "$requested_version" =~ ^[0-9]+\.[0-9]+$ ]]; then
        # Major.minor version: find the latest installed version of this major.minor
        match_version=$(find "$HOME/.node" -maxdepth 1 -type d -name "v${requested_version}.*" | sort -V | tail -n1)
    elif [[ "$requested_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        # Specific version: use this specific version
        match_version="$HOME/.node/v${requested_version}"
    fi

    if [ -z "$match_version" ] || [ ! -d "$match_version" ]; then
        echo "Node.js version matching '$requested_version' is not installed."
        return 1
    fi

    version_folder=$(basename "$match_version")

    # Construct the path to the Node.js binaries for the matched version
    local node_path="$HOME/.node/$version_folder/bin"

    # Add the matched Node.js version to the beginning of the PATH for the current session
    PATH="$node_path:$PATH"

    echo "Using Node.js $version_folder. This change is temporary and will reset after the terminal session ends."
    # Optionally, you can display the version being used by executing 'node -v'
    node -v
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
        match_version=$(find "$HOME/.node" -maxdepth 1 -type d -name "v${requested_version}.*" | sort -V | tail -n1)
    elif [[ "$requested_version" =~ ^[0-9]+\.[0-9]+$ ]]; then
        # Major.minor version: find the latest installed version of this major.minor
        match_version=$(find "$HOME/.node" -maxdepth 1 -type d -name "v${requested_version}.*" | sort -V | tail -n1)
    elif [[ "$requested_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        # Specific version: use this specific version
        match_version="$HOME/.node/v${requested_version}"
    fi

    if [ -z "$match_version" ] || [ ! -d "$match_version" ]; then
        echo "Node.js version matching '$requested_version' is not installed."
        return 1
    fi

    version_folder=$(basename "$match_version")

    # Construct the path to the Node.js binaries for the matched version
    local node_path="$match_version/bin"

    # Check if the .bashrc already contains Node path settings and replace them
    if grep -q '# START RVM NODE PATH' ~/.bashrc; then
        # The .bashrc contains existing Node.js path settings; replace them
        sed -i "/# START RVM NODE PATH/,/# END RVM NODE PATH/{s|export PATH=\$HOME/.node/v[^:]*/bin:\$PATH|export PATH=$node_path:\$PATH|}" ~/.bashrc
    else
        # The .bashrc does not contain Node.js path settings; add them
        echo "# START RVM NODE PATH" >> ~/.bashrc
        echo "export PATH=$node_path:\$PATH" >> ~/.bashrc
        echo "# END RVM NODE PATH" >> ~/.bashrc
    fi

    source ~/.bashrc

    echo "Node.js $version_folder has been set as your default node version"
}




help_install () {
    cat <<EOF
To use this command, you can type in:
    Latest(as specified by node):
    rvm install node latest

    Latest of major version:
    rvm install node 18

    Latest of major & minor version:
    rvm install node 18.10

    Specific version:
    rvm install node 18.10.11

    Latest of specific LTS:
    rvm install node latest-iron
    rvm install node latest-hydrogen
EOF

}

help_showall () {
    cat <<EOF
To use this command, you can type in:
    Show all installed
    rvm showall node installed

    Show all available at nodejs repository for installation
    rvm showall available

    Show all available major version at nodejs repository for installation
    rvm showall node available 18 
EOF

}

help_update () {
    cat <<EOF
To use this command, you can type in:
    Update current default version(with latest of the same major version)
    rvm update node current

    Update the latest version of node (as per the nodejs website)
    rvm update node latest

    Update the latest version of an lts
    rvm update node latest-hydrogen
    rvm update node latest-iron

    Update a specific major / minor version of node
    rvm update node 18
    rvm update node 18.10

    The update function will call the install function.
    If a version does not exist, it will proceed to install it

    Note that on completion, the path to the version will be set to the new installed version
EOF

}

help_use () {
    cat <<EOF
    This command sets a specific specified version temporarily.
    The default version will revert back to the one set in your terminal settings file once you restart your terminal

    To change your default permanetly, call the rvm set node <version>

    To use this command, you can type in:
    Latest installed of major version
    rvm use node 18

    Latest installed of major/minor version
    rvm use 18.10

    Specific version
    rvm use 18.10.0

    rvm currently does not track lts versions locally, so it does not know which
    are lts versions and which aren't
EOF

}

help_set () {
    cat <<EOF
    This command sets the default version in your system.

    To change your default temporarily, call the rvm use node <version>

    To use this command, you can type in:
    Latest installed of major version
    rvm set node 18

    Latest installed of major/minor version
    rvm set 18.10

    Specific version
    rvm set 18.10.0

    rvm currently does not track lts versions locally, so it does not know which
    are lts versions and which aren't
EOF

}

