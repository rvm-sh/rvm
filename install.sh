#!/bin/sh

{ # this ensures the entire script is downloaded #

# Abort function
abort() {
  printf "%s\n" "$@"
  exit 1
}

# Download function
download() {

  # Default destination
  dest="$HOME/Downloads"
  
  # Allow passing custom destination 
  if [ "$2" ]; then
    dest="$2"
  fi

  if command -v curl > /dev/null 2>&1; then
    curl -fsSL "$1" -o "$dest/rvm.tar.gz" 
  else
    wget -qO- "$1" -O "$dest/rvm.tar.gz"
  fi

}

#Get the json containing the latest version info
version_json="$(download "https://registry.npmjs.org/@pnpm/exe")" || abort "Download Error!"

# Get latest version data
LATEST_RVM_VERSION_URL="https://api.github.com/repos/rvm-sh/rvm/releases/latest"
latest_version_json="$(download $LATEST_RVM_VERSION_URL)" || abort "Error connecting to Github to get latest rvmsh version"

# Extract tag_name with substring operations
latest_version="${json#*\'tag_name\': \"}"
latest_version="${name%%\"*}"

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
version_folder="$HOME/.rvm/${install_version}"
mkdir -p "$version_folder"

# Fetch the rvm folder
RVM_FOLDER_URL="https://api.github.com/repos/rvm-sh/rvm/tarball/${latest_version}"
download "$RVM_FOLDER_URL" -O "${HOME}/.rvm"

# Extract the contents of the compressed file to the version directory
tar -xzf "${HOME}/.rvm/rvm.tar.gz" -C "$version_folder" --strip-components=1

# Make rvm.sh executable
chmod +x "${version_folder}/rvm.sh"

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

# Set the path to rvm
echo "#runner version manager settings" >> "$PROFILE"
echo "export RVM_DIR=\"$version_folder\"" >> "$PROFILE"
echo "[ -s \"$version_folder/rvm.sh\" ] && . \"$version_folder/rvm.sh\"  # This loads rvm" >> "$PROFILE"
echo "#end of runner version manager settings" >> "$PROFILE"


# Remove install folder after installation
rm -f "$HOME/.rvm/rvm.tar.gz"

# Inform the user
echo "Installation complete. Please restart your terminal or run 'source $PROFILE' to use rvm."


}
