#!/bin/sh

{ # this ensures the entire script is downloaded #

# Fetch the rvm.sh script
RVM_SCRIPT_URL="https://raw.githubusercontent.com/rvm-sh/rvm/main/rvm.sh"
wget -q "$RVM_SCRIPT_URL" -O "${HOME}/rvm.sh"

# Create the .rvm directory in the user's home directory
RVM_DIR="${HOME}/.rvm"
mkdir -p "${RVM_DIR}"

# Move the downloaded rvm.sh to .rvm directory
mv "${HOME}/rvm.sh" "${RVM_DIR}/rvm.sh"

# Make rvm.sh executable
chmod +x "${RVM_DIR}/rvm.sh"

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

echo "#runner version manager settings" >> "$PROFILE"
echo "export RVM_DIR=\"$RVM_DIR\"" >> "$PROFILE"
echo "[ -s \"$RVM_DIR/rvm.sh\" ] && . \"$RVM_DIR/rvm.sh\"  # This loads rvm" >> "$PROFILE"
echo "#end of runner version manager settings" >> "$PROFILE"


# Remove install script after installation
# rm -- "$0"

# Inform the user
echo "Installation complete and install script removed. Please restart your terminal or run 'source $PROFILE' to use rvm."


}
