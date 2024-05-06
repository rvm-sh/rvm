
# Add, update, upgrade and showall available should be manually written
# Remove, removeall, supported, use, set should be standard
# Standard functions should have their own shell script (so that we can change it without having to reimplement every script)

# Name runtime here
# Name should be all small letters, eg rvm, node, cargo, python
$RUNTIME = ""

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
            echo "Requested latest ${major_version_requested}. Calling latest version of ${major_version_requested} "
            read -r install_version link <<< $(get_latest_major_version "$major_version_requested" "$os" "$arch")

            if [ -z "$install_version" ] || [ -z "$link" ]; then
                echo "Failed to find a valid latest version for major version ${major_version_requested} requested on the pnpm server"
                echo "If this version has not been released yet, you may be able to install alpha / beta versions via"
                echo "rvm install pnpm next ${major_version_requested}"
                return 1
            fi

        else
            echo "No major version defined, looking up latest pnpm version"
            read -r install_version link <<< $(get_latest_pnpm_version "$os" "$arch")

            if [ -z "$install_version" ] || [ -z "$link" ]; then
                echo "Failed to find a valid latest version of pnpm from the pnpm server. This is likely an issue from pnpm's server response"
                return 1
            fi
        fi

        
        echo "Latest version requested. Installing pnpm ${install_version}"
    elif [[ $requested_version =~ ^[0-9]+$ ]]; then
        echo "Requested ${requested_version}"
        read -r install_version link <<< $(get_latest_major_version $requested_version $os $arch)

        if [ -z "$install_version" ] || [ -z "$link" ]; then
            echo "Failed to find the latest pnpm version for $os $arch"
            return 1
        fi

    elif [[ $requested_version == next ]]; then
        if [ -z "$major_version_requested" ]; then
            echo "A major version number must be specified for next version installations, e.g:"
            echo "rvm install pnpm next 9"
            return 1
        fi

        read -r install_version link <<< $(get_next_major_version $major_version_requested $os $arch)

        if [ -z "$install_version" ] || [ -z "$link" ]; then
            echo "Failed to find the latest next version of pnpm for the requested major version of pnpm for $os $arch"
            return 1
        fi

    elif [[ $requested_version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        version="${requested_version}"
        link="https://github.com/pnpm/pnpm/releases/download/v${requested_version}/pnpm-${os}-${arch}"

        version_json="$(download "https://registry.npmjs.org/@pnpm/exe/${version}")"

        # Check for "version not found" error in the JSON response
        if echo "$version_json" | grep -q "version not found: ${version}"; then
            echo "Version not found: ${major_version}."
            return 1
        fi


    else
        echo "Invalid version specification: $requested_version"
        return 1
    fi

    install_specific_version $install_version $link
}

get_latest_pnpm_version() {
    local os="$1"
    local arch="$2"

    version_json="$(download "https://registry.npmjs.org/@pnpm/exe")"
    version="$(printf '%s' "${version_json}" | tr '{' '\n' | awk -F '"' '/latest/ { print $4 }')"
    link="https://github.com/pnpm/pnpm/releases/download/v${version}/pnpm-${os}-${arch}"

    echo "$version $link"
    return 0
}


get_latest_major_version() {
    local major_version="$1"
    local os="$2"
    local arch="$3"

    version_json="$(download "https://registry.npmjs.org/@pnpm/exe")"
    version="$(printf '%s' "${version_json}" | tr '{' '\n' | awk -F '"' '/latest-${major_version}/ { print $4 }')"

    link="https://github.com/pnpm/pnpm/releases/download/v${version}/pnpm-${os}-${arch}"

    echo "$version $link"
    return 0
}


get_next_major_version() {
    local major_version="$1"
    local os="$2"
    local arch="$3"

    version_json="$(download "https://registry.npmjs.org/@pnpm/exe/next-$major_version")"

    # Check for "version not found" error in the JSON response
    if echo "$version_json" | grep -q "version not found: next-${major_version}"; then
        echo "Version not found: next-${major_version}."
        return 1
    fi

    # Attempt to parse the version number from the JSON, including pre-release versions
    version=$(echo "$version_json" | grep -oP '"version":"\K[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z-]+)?' | head -n 1)


    # Check if the version variable is set and follows the expected format
    if [[ -z "$version" || ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Failed to parse a valid version from the JSON data."
        return 1
    fi

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

    # Make the downloaded program executable
    chmod +x "$download_dir/pnpm"

    echo "Download complete. pnpm is now executable."

    # Add pnpm path to PATH variable
    echo "Updating bash PATH settings"

    # Path to the .rvmshrc file
    rvmshrc_path="$HOME/.rvm/.rvmshrc"


    # Check for existing line and either update or create it
    if grep -q "export PATH=\$HOME/.pnpm/v[^:]*:\$PATH" "$rvmshrc_path"; then
        # Update existing line
        sed -i "s|export PATH=\$HOME/.pnpm/v[^:]*:\$PATH|export PATH=\$HOME/.pnpm/v$install_version:\$PATH|" "$rvmshrc_path"
    else
        # Create new line with comments
        echo "# START RVM PNPM PATH" >> "$rvmshrc_path"
        echo "export PATH=\$HOME/.pnpm/v$install_version:\$PATH" >> "$rvmshrc_path"
        echo "# END RVM PNPM PATH" >> "$rvmshrc_path"
    fi

    # Source the updated file
    source "$rvmshrc_path"

    pnpm -v
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
remove () {}

## REMOVEALL ##
removeall () {}

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




