#!/bin/sh

# Add, update, upgrade and showall available should be manually written
# Remove, removeall, supported, use, set should be standard
# Standard functions should have their own shell script (so that we can change it without having to reimplement every script)

# Name runtime here
# Name should be all small letters, eg rvm, node, cargo, python
$RUNTIME = "node"

## ADD ##
# Add installs either <specific version>, <latest>, <major> at a minimum
# Use custom implementation code according to source requirements
# Must have the below 3 implementations but can also have additional commands such as future, forward, etc
# rvm add node latest       - installs latest as defined by runtime maintainers
# rvm add node 18           - installs latest version of node 18
# rvm add node 18.14.12     - installs this specific version

add() {
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
        help_install
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


    # Add Node.js path to PATH variable
    echo "Updating RVM PATH settings for Node.js"

    # Define the .rvmrc path
    rvmrc_path="$HOME/.rvm/.rvmrc"

    # Check for existing line and either update or create it
    if grep -q "export PATH=\$HOME/.node/v[^:]*/bin:\$PATH" "$rvmrc_path"; then
        # Update existing line
        sed -i "s|export PATH=\$HOME/.node/v[^:]*/bin:\$PATH|export PATH=\$HOME/.node/$install_version/bin:\$PATH|" "$rvmrc_path"
    else
        # Create new line with comments
        echo "# START RVM NODE PATH" >> "$rvmrc_path"
        echo "export PATH=\$HOME/.node/$install_version/bin:\$PATH" >> "$rvmrc_path"
        echo "# END RVM NODE PATH" >> "$rvmrc_path"
    fi
}

## UPDATE ##
# Update installs latest of the major version being used and makes it the default
# rvm update node
# will update to the latest node 18 if that is the major version set as default 
# Use custom implementation code according to source requirements

update () {
  if [[ $1 == "help" ]]; then
    help_update
    return
  fi
}



## UPGRADE ##
# Upgrade adds the latest version and makes it the default
# rvm upgrade node
# Use custom implementation code according to source requirements

upgrade () {
  if [[ $1 == "help" ]]; then
    help_update
    return
  fi
}


## SHOWALL ##
# Showall <installed> shows all installed versions of runtime
# rvm showall node
# rvm showall node installed
# rvm showall node available
showall() {
  if [[ $# -eq 0 ]]; then
    help_showall
    return
  fi

  if [[ $1 == "help" ]]; then
    help_showall
    return
  fi

}

## REMOVE ##
# remove () {}

## REMOVEALL ##
# removeall () {}

## SUPPORTED ##
# Returns positive confirmation that runtime is supported
# rvm supported node
supported() {
  if [[ $1 == "help" ]]; then
    help_supported
    return
  else
    echo "$RUNTIME is supported"
  fi

}

## USE ##


## SET ##





# ALL HELP FUNCTIONS

# Help displays the generic help for 
# rvm help node
help() {
    echo "Welcome to the help section for $RUNTIME management via rvm"
    echo "rvm supports the following commands for managing the $RUNTIME runtime: add, remove, update, upgrade, removeall, showall, use, set, help, supported, prune"
    echo "rvm <command> $RUNTIME help - displays the help for the specific command. e.g:"
    echo "rvm add $RUNTIME help - displays the help for the add command"
    echo "rvm remove $RUNTIME help - displays the help for the remove command"

    echo "To run a command, use the following syntax:"
    echo "rvm supported $RUNTIME -  returns positive confirmation that $RUNTIME is supported"
    echo "rvm add $RUNTIME latest - installs the latest version of the runtime, as define by the runtime maintainers"
    echo "rvm showall $RUNTIME installed - lists all installed versions of the runtime"
    echo "rvm showall $RUNTIME available - lists all available versions of the runtime from the runtime repository"
}

help_add () {
    echo "Add installs either <specific version>, <latest>, <major_version> depending on availability by runtime managers"
    echo "rvm add $RUNTIME <version> - installs the specific version of $RUNTIME. eg:"
    echo "rvm add $RUNTIME latest - installs the latest version of $RUNTIME"
    echo "rvm add $RUNTIME 8 - installs the latest version of $RUNTIME 8"
    echo "rvm add $RUNTIME 8.14.12 - installs this specific version of $RUNTIME 8.14.12"
}

help_update() {
    echo "Update installs latest of the major version being used and makes it the default"
    echo "rvm update $RUNTIME - e.g updates to the latest version of $RUNTIME v8 if that is the major version set as default"
}

help_upgrade() {
    echo "Upgrade installs the latest version of $RUNTIME and makes it the default. Unlike the update command, it will jump major versions if there is a newer major version available"
    echo "rvm update $RUNTIME"
}

help_use() {
    echo "Use sets the specific <major> or <major_minor_rev> version of the runtime temporarily. Resets on restart of os. eg."
    echo "rvm use $RUNTIME <version>"
    echo "rvm use $RUNTIME 18       - will use the latest version of $RUNTIME 18"
    echo "rvm use $RUNTIME 18.14.12 - will set the specific version(18.14.12) of $RUNTIME requested"
}

help_set() {
    echo "Set sets the specified <major> or <major_minor_rev> version as the default version. eg."
    echo "rvm set $RUNTIME <version>"
    echo "rvm set $RUNTIME 18       - will set the latest version of $RUNTIME 18 as the default"
    echo "rvm set $RUNTIME 18.14.12 - will set the specific version(18.14.12) of $RUNTIME requested as the default"
}

supported_help() {
    echo "Supported returns positive confirmation that $RUNTIME is supported. e.g.:"
    echo "rvm supported $RUNTIME"
}

help_showall() {
    echo "Showall shows all installed or available versions of runtime depending on the command option"
    echo "rvm showall $RUNTIME installed - lists all installed versions of $RUNTIME"
    echo "rvm showall $RUNTIME available - lists all available versions of $RUNTIME from the runtime repository"
}

help_remove()  {
    echo "Remove removes <specific_version> and <major_version> versions only"
    echo "rvm remove $RUNTIME <version> - removes the specific version of $RUNTIME. eg:"
    echo "rvm remove $RUNTIME 8         - removes the versions of $RUNTIME that has the major version 8"
    echo "rvm remove $RUNTIME 8.14.12   - removes this specific version of $RUNTIME 8.14.12"
    echo "see prune command for removing all versions older than a specific version"
    echo "see removeall command for removing all versions of $RUNTIME"
}

help_removeall() {
    echo "Removeall removes all the versions of $RUNTIME added to system. eg."
    echo "rvm removeall $RUNTIME"
}

help_prune() {
    echo "Prune all versions of $RUNTIME older than the stated version"
    echo "rvm prune $RUNTIME <version>  - removes all versions of $RUNTIME older than the stated version. eg:"
    echo "rvm prune $RUNTIME 18         - removes all versions of $RUNTIME older than the latest version of $RUNTIME 18 (not including any versions 18)"
    echo "rvm prune $RUNTIME 18.10      - removes all versions of $RUNTIME older than the latest version of $RUNTIME 18.10 (not including version 18.10)"
    echo "rvm prune $RUNTIME 18.10.14   - removes all versions of $RUNTIME older than the latest version of $RUNTIME 18.10.14 (not including version 18.10.14)"
}




