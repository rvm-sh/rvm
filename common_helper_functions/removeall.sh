#!/bin/sh

removeall() {
    if [[ $1 == "help" ]]; then
        help_removeall
        return
    fi

    echo "This will uninstall all $RUNTIME versions. Are you sure? (y/n)"
    read -r confirm
    if [[ $confirm != "y" && $confirm != "Y" ]]; then
        echo "Uninstall cancelled."
        return
    fi

    echo "Uninstalling all $RUNTIME versions..."
    # Delete the .node folder
    if [ -d "$HOME/.$RUNTIME" ]; then
        echo "Removing the .$RUNTIME folder..."
        rm -rf "$HOME/.$RUNTIME"
        echo ".$RUNTIME folder removed successfully."
    else
        echo "No .$RUNTIME folder found. Skipping removal."
    fi

    RUNTIME_CAP=$(echo $RUNTIME | tr '[:lower:]' '[:upper:]')
    # Delete the setting in the .rvmshrc file
    if grep -q "# START $RUNTIME_CAP PATH" "$HOME/.rvm/.rvmshrc"; then
        echo "Removing $RUNTIME path settings from .rvmshrc..."
        sed -i "/# START $RUNTIME_CAP PATH/,/# END $RUNTIME_CAP PATH/d" "$HOME/.rvm/.rvmshrc"
        echo "$RUNTIME path settings removed from .rvmshrc."
    else
        echo "$RUNTIME path settings not found in .rvmshrc. Skipping removal."
    fi

    echo "All $RUNTIME versions and settings have been uninstalled successfully."
}


