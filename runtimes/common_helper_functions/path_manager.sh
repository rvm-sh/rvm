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
    # Rename vars
    $RUNTIME = "$1"
    $RUNTIME_PATH = "$2" 
    $RUNTIME_CAP = $(echo "$RUNTIME" | tr '[:lower:]' '[:upper:]')

    # Delete any old settings in the .rvmshrc file
    delete_runtime_path "$RUNTIME"

    # Add new settings
    echo "Adding new $RUNTIME path settings to .rvmshrc..."
    echo ""                                                             >> "$HOME/.rvm/.rvmshrc"
    echo "# START ${RUNTIME_CAP} PATH"                                  >> "$HOME/.rvm/.rvmshrc"
    echo "export ${RUNTIME_CAP}_DIR=\"\$HOME/.$RUNTIME/\""                >> "$HOME/.rvm/.rvmshrc"
    echo "[ -s \"\${${RUNTIME_CAP}_DIR}/$RUNTIME_PATH\" ] && . \"\${${RUNTIME_CAP}_DIR}/$RUNTIME_PATH\""        >> "$HOME/.rvm/.rvmshrc"
    echo "# END ${RUNTIME_CAP} PATH"                                    >> "$HOME/.rvm/.rvmshrc"

}

delete_runtime_path() {
    RUNTIME="$1"
    RUNTIME_CAP=$(echo "$RUNTIME" | tr '[:lower:]' '[:upper:]')
    
    if grep -q "# START $RUNTIME_CAP PATH" "$HOME/.rvm/.rvmshrc"; then
        echo "Removing old $RUNTIME path settings from .rvmshrc..."
        sed -i "/# START $RUNTIME_CAP PATH/,/# END $RUNTIME_CAP PATH/d" "$HOME/.rvm/.rvmshrc"
        echo "$RUNTIME path settings removed from .rvmshrc."
    fi
  
}