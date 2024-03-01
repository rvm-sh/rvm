#!/bin/sh

{ # this ensures the entire script is downloaded #

# Get latest version data
LATEST_RVM_VERSION_URL="https://api.github.com/repos/rvm-sh/rvm/releases/latest"

# Download JSON into variable
latest_version_json=$(wget -qO- "$LATEST_RVM_VERSION_URL")

# Handle errors
if [ $? -ne 0 ]; then
  echo "Failed to get info on latest version of rvm from Github" >&2
  exit 1
fi

# Extract tag_name with substring operations
latest_version=$(echo "$latest_version_json" | grep -o '"name": *"[^"]*"' | awk -F '"' '{print $4}')

echo "Version to be installed: ${latest_version}"

# Check if .rvm folder exists
if [ ! -d "$HOME/.rvm" ]; then
    mkdir -p "$HOME/.rvm"
    echo "Created .rvm folder in your home directory."
else
    echo ".rvm folder in your home directory already exists"
    echo "If you already have rvm installed, you can update it using rvm update rvm"
    echo "Otherwise, please delete the folder before retrying"
    exit 1
fi

# Create folder to store the latest version
version_folder="$HOME/.rvm/${latest_version}"
mkdir -p "$version_folder"

# Fetch the rvm folder
RVM_FOLDER_URL="https://api.github.com/repos/rvm-sh/rvm/tarball/${latest_version}"

wget -qO "$HOME/.rvm/rvm.tar.gz" "$RVM_FOLDER_URL"

# Check the exit status of wget
if [ $? -eq 0 ]; then
    echo "File downloaded successfully."
else
    echo "Failed to download the file."
    echo "Please try again or check network status"
    echo "Removing the .rvm directory..."
    if [ -n "$HOME" ] && [ -d "$HOME/.rvm" ]; then
        echo "Removing the .rvm directory..."
        rm -rf "$HOME/.rvm"
    else
        echo "Safety check failed: Either HOME is not set, or the .rvm directory does not exist."
        exit 1
    fi
    exit 1
fi

# Extract the contents of the compressed file to the version directory
tar -xzf "${HOME}/.rvm/rvm.tar.gz" -C "$version_folder" --strip-components=1

# Make rvm.sh executable
chmod +x "${version_folder}/rvm.sh"

# Remove install folder after installation
rm -f "$HOME/.rvm/rvm.tar.gz"

# Determine the shell using the process name
SHELL_NAME=$(ps -p $$ -o comm=)

case "$SHELL_NAME" in
    bash)
        PROFILE="$HOME/.bashrc"
        ;;
    zsh)
        PROFILE="$HOME/.zshrc"
        ;;
    ksh)
        PROFILE="$HOME/.kshrc"
        ;;
    fish)
        PROFILE="$HOME/.config/fish/config.fish"
        ;;
    *sh|sh)
        PROFILE="$HOME/.profile"
        ;;
    *)
        echo "Unrecognized shell: $SHELL_NAME"
        exit 1
        ;;
esac

echo "Detected shell: $SHELL_NAME"
echo "Using profile file: $PROFILE"

# Set the path to rvm in a new .rvmrc file in the .rvm folder
echo "#RVM PATH START" >> "$HOME/.rvm/.rvmrc"
echo "export RVM_DIR=\"\$HOME/.rvm/${latest_version}\"" >> "$HOME/.rvm/.rvmrc"
echo "[ -s \"\$RVM_DIR/rvm.sh\" ] && . \"\$RVM_DIR/rvm.sh\"  # This loads rvmrc" >> "$HOME/.rvm/.rvmrc"
echo "#RVM PATH END" >> "$HOME/.rvm/.rvmrc"

# Set path to rvmrc in .bashrc
echo "#RVMRC PATH START" >> "$PROFILE"
echo "[ -s \"$HOME/.rvm/.rvmrc\" ] && . \"$HOME/.rvm/.rvmrc\"  # This loads the .rvmrc file" >> "$PROFILE"
echo "#RVMRC PATH END" >> "$PROFILE"

# Inform the user
echo "Installation complete. Please restart your terminal or run 'source $PROFILE' to use rvm."

source $PROFILE

# Check if jq is installed
echo "Checking if jq is already available in the system"

if ! command -v jq &> /dev/null; then
    echo " jq was not found in the system"
    echo " rvmsh uses jq to parse responses from websites when checking versions"

    # Detect the operating system to provide more specific installation instructions
    case "$(uname -s)" in
        Linux)
            echo "You can install jq using rvm or your system package manager"
            echo "rvmsh:         rvm install jq latest"
            echo "Debian/Ubuntu: sudo apt-get install jq"
            echo "openSUSE:      sudo zypper install jq"
            echo "Fedora:        sudo dnf install jq"
            echo "Arch:          sudo pacman -S jq"
            ;;
        Darwin)
            echo "You can install jq using rvm or use another package manager"
            echo "rvmsh:  rvm install jq latest"
            echo "Brew:   brew install jq"
            echo "Port:   port install jq"
            echo "Fink:   fink install jq"
            ;;
        *)
            echo "You can install jq using rvm or use another package manager"
            echo "rvmsh: rvm install jq latest"
            ;;
    esac

    # Exit the script if jq is not installed
    exit 1
else
    echo "jq already available"

fi

echo "Installation complete"

}
