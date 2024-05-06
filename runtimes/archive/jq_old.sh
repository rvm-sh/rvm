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
        x86_64) arch="amd64" ;;
        aarch64) arch="arm64" ;;
    esac

    

    # determine the version to install
    local requested_version="$1"

    if [[ $requested_version == latest ]]; then
        
        read -r install_version link <<< $(get_latest_jq_version "$os" "$arch")

        if [ -z "$install_version" ] || [ -z "$link" ]; then
            echo "Failed to find the latest jq version for $os $arch"
            return 1
        fi
        echo "Latest version requested. Installing node ${install_version}"

    elif [[ $requested_version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        tag_name="jq-${requested_version}"
        file_name="jq-${os}-${arch}"
        install_version="${requested_version}"
        link="https://github.com/jqlang/jq/releases/download/${tag_name}/${file_name}"

    else
        echo "Invalid version specification: $requested_version"
        return 1
    fi

    install_specific_version $install_version $link
}

get_latest_jq_version() {
    local os="$1"
    local arch="$2"
    local url="https://api.github.com/repos/jqlang/jq/releases/latest"

    # Use wget to fetch the directory listing
    local html_content=$(wget -qO- "$url")

    # Initialize an empty string for the version and link
    local version=""
    local link=""

    # Download JSON into variable
    latest_version_json=$(wget -qO- "$url")

    # Handle errors
    if [ $? -ne 0 ]; then
        echo "Failed to get info on latest version of jq from the Github repository" >&2
        exit 1
    fi

    # Extract tag_name with substring operations
    tag_name=$(echo "$latest_version_json" | grep -o '"tag_name": *"[^"]*"' | awk -F '"' '{print $4}')
    version=${tag_name#jq-}
    link="https://github.com/jqlang/jq/releases/download/${tag_name}/jq-${os}-${arch}"

    echo "Version to be installed: ${version}"

    # Check if the version and link were found
    if [[ -z "$version" || -z "$link" ]]; then
        echo "Failed to find the latest jq version for $os $arch"
        return 1
    fi

    echo "$version" "$link"
}

install_specific_version() {
    install_version=$1 
    link=$2

    # Check if .node folder exists
    if [ ! -d "$HOME/.jq" ]; then
        mkdir -p "$HOME/.jq"
        echo "Created .node folder in your home directory."
    fi


    # Check if folder named v<version> exists
    echo "Checking if version already exists..."
    version_folder="$HOME/.jq/v${install_version}"
        if [ -d "$version_folder" ]; then
        echo "Node.js version $install_version is already installed. To reinstall, remove this version first"
        return 1
    fi

    mkdir -p "$version_folder"


    # Download the file using wget
    # echo "Downloading file..."
    # download_dir="$HOME/.jq/downloads"
    # if [ ! -d "$download_dir" ]; then
    #     mkdir -p "$download_dir"
    # fi
    
    wget -qO "$version_folder/jq" "$link"
    if [ $? -ne 0 ]; then
        echo "Failed to download the file."
        return 1
    fi

    echo "Download complete."
    

    # unzip the file, rename the folder to its version (ie, v20.11.0)
    # Use tar to extract with custom directory name
    # tar -xzf "$download_dir/node.tar.gz" -C "$version_folder" --strip-components=1


    #Delete the downloaded file
    # echo "Install complete. Clearing up download file"
    # rm -f "$download_dir/node.tar.gz"

    # Add jq path to PATH variable
    echo "Updating bash PATH settings"
    # Check for existing jq path and either update or create it
    if grep -q "export PATH=\$HOME/.jq/v[^:]*/:\$PATH" "$HOME/.rvm/.rvmrc"; then
        # Update existing line
        sed -i "s|export PATH=\$HOME/.jq/v[^:]*/:\$PATH|export PATH=\$HOME/.jq/$install_version:\$PATH|" "$HOME/.rvm/.rvmrc"
    else
        # Create new line with comments
        echo "# START JQ PATH" >> "$HOME/.rvm/.rvmrc"
        echo "export PATH=\$HOME/.jq/$install_version:\$PATH" >> "$HOME/.rvm/.rvmrc"
        echo "# END JQ PATH" >> "$HOME/.rvm/.rvmrc"
    fi

    echo "Path updated. If terminal does not recognise new version, please restart your terminal"
}