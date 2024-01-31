#!/bin/sh

{ # this ensures the entire script is downloaded #

# Fetch the rvm.sh script
RVM_SCRIPT_URL="https://github.com/rvm-sh/rvm/blob/main/rvm.sh"
wget -q "$RVM_SCRIPT_URL" -O "${HOME}/rvm.sh"

# Create the .rvm directory in the user's home directory
RVM_DIR="${HOME}/.rvm"
mkdir -p "${RVM_DIR}"

# Move the downloaded rvm.sh to .rvm directory
mv "${HOME}/rvm.sh" "${RVM_DIR}/rvm.sh"

# Make rvm.sh executable
chmod +x "${RVM_DIR}/rvm.sh"

# Modify the user's shell profile
PROFILE="${HOME}/.profile"  # Default to .profile

# Source rvm.sh in the profile
echo "export RVM_DIR=\"${RVM_DIR}\"" >> "$PROFILE"
echo "[ -s \"\$RVM_DIR/rvm.sh\" ] && . \"\$RVM_DIR/rvm.sh\"  # This loads rvm" >> "$PROFILE"

# Remove install script after installation
rm -- "$0"

# Inform the user
echo "Installation complete and install script removed. Please restart your terminal or run 'source $PROFILE' to use rvm."


}
