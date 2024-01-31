#!/bin/sh

# Define the rvm function
rvm() {
    case "$1" in
        remove | uninstall)
            remove "$@"
            ;;
        add | install)
            add "$@"
            ;;
        all | showall)
            all "$@"
            ;;
        prune)
            prune "$@"
            ;;
        removeall | uninstallall)
            removeall "$@"
            ;;
        update)
            update "$@"
            ;;
        set | use)
            set "$@"
            ;;
        echo | help)
            echo "$@"
            ;;          
        *)
            echo "Unrecognized command: $1"
            ;;
    esac
}

# Function to handle 'remove' and 'uninstall' commands
remove() {
    if [ "$2" = "rvm" ]; then
        remove_rvm
    else
        echo "Invalid argument for remove. Usage: 'rvm remove rvm' or 'rvm uninstall rvm'."
    fi
}


add() {
    # Implement the logic for 'add / install' command
    echo "Add / Install command called with argument: $2"

}

all() {
    # Implement the logic for 'all / showall' command
    echo "All / showall command called with argument: $2"

}

prune() {
    # Implement the logic for 'prune' command
    echo "Prune command called with argument: $2"

}

removeall() {
    # Implement the logic for 'removeall' command
    echo "Removeall / Uninstallall command called with argument: $2"

}

update() {
    # Implement the logic for 'update' command
    echo "Update command called with argument: $2"

}

set() {
    # Implement the logic for 'set' command
    echo "Set / Use command called with argument: $2"

}

echo() {
    # A template argument to test if rvm can be reached
    echo "Hello, $2, what can i do for you?"

}

# Function to remove rvm
remove_rvm() {
    echo "Removing RVM..."

    # Remove the .rvm directory
    rm -rf "${HOME}/.rvm"

    # Remove lines related to rvm from the profile file
    PROFILE="${HOME}/.profile"
    sed -i '/RVM_DIR/d' "$PROFILE"
    sed -i '/rvm.sh/d' "$PROFILE"

    echo "RVM has been removed. Please restart your terminal."
}


