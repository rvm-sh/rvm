#!/bin/sh

# Define the default and latest versions of node
DEFAULT_NODE_VERSION=""
INSTALLED_VERSIONS=""
ALL_AVAILABLE_NODE_VERSIONS=""

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


    source ~/.bashrc

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
# where we al already determined the exact version we want
install_specific() {
    echo "Function not implemented yet"
}

uninstall() {
    echo "Function not implemented yet"

}

prune() {
    echo "Function not implemented yet"

}

showall() {
    echo "Function not implemented yet"

}

uninstallall() {
    echo "Function not implemented yet"

}

update() {
    echo "Function not implemented yet"

}

use () {
    echo "Function not implemented yet"

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

