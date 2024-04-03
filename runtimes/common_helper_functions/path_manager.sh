#!/bin/sh

# Get runtime version from the .rvmshrc
get_runtime_version() {
  RUNTIME="$1"
  RUNTIME_CAP=$(echo "$RUNTIME" | tr '[:lower:]' '[:upper:]')

  # Pull the runtime path from rvmshrc
  currentPath=$(grep -oP "${RUNTIME_CAP}_DIR=\"\$HOME/\.$RUNTIME/\K[^\"]*" "$HOME/.rvm/rvmshrc")

  if [ -z "$currentPath" ]; then
    echo "No $RUNTIME version found in rvmshrc."
    return 1
  fi

  # Extract the version from the currentPath
  version=$(echo "$currentPath" | sed 's/.*v\?//')

  echo "$version"

}

# Common function to update path
# Takes 2 args: runtime & runtime path
# runtime, eg: node, cargo, pnpm, etc
# runtime path eg: "pnpm" (for pnpm), "bin/node" for node

update_runtime_path() {
  RUNTIME_NAME="$1"
  RUNTIME_PATH="$2"
  RUNTIME_VERSION="$3"
  RUNTIME_NAME_CAP=$(echo "$RUNTIME_NAME" | tr '[:lower:]' '[:upper:]')  # Fixed variable reference

  # Delete any old settings in the .rvmshrc file
  delete_runtime_path "$RUNTIME_NAME"  # Fixed variable reference

  # Use heredoc for adding new settings to ensure proper escaping and quoting
  cat <<EOF >> "$HOME/.rvm/.rvmshrc"
# START ${RUNTIME_NAME_CAP} PATH
export ${RUNTIME_NAME_CAP}_DIR="\$HOME/.${RUNTIME_NAME}/v${RUNTIME_VERSION}"
[ -s "\${${RUNTIME_NAME_CAP}_DIR}/${RUNTIME_PATH}" ] && . "\${${RUNTIME_NAME_CAP}_DIR}/${RUNTIME_PATH}"
# END ${RUNTIME_NAME_CAP} PATH
EOF
}


# Take runtime name as the first argument
delete_runtime_path() {
    RUNTIME="$1"
    RUNTIME_CAP=$(echo "$RUNTIME" | tr '[:lower:]' '[:upper:]')
    
    if grep -q "# START $RUNTIME_CAP PATH" "$HOME/.rvm/.rvmshrc"; then
        echo "Removing old $RUNTIME path settings from .rvmshrc..."
        sed -i "/# START $RUNTIME_CAP PATH/,/# END $RUNTIME_CAP PATH/d" "$HOME/.rvm/.rvmshrc"
        echo "$RUNTIME path settings removed from .rvmshrc."
    fi
  
}