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
        help)
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

help() {
    # Help function
    echo "Hello, $2, what can i do for you?"

}

remove_rvm_settings() {
    local profile_file=$1
    if [ -f "$profile_file" ]; then
        if command -v gsed &>/dev/null; then
            # Use GNU sed if available (gsed is the name in some environments)
            gsed -i '/#runner version manager settings/,/#end of runner version manager settings/d' "$profile_file"
        else
            # Fallback to regular sed, accommodating for both GNU and BSD sed syntax
            sed -i'' -e '/#runner version manager settings/,/#end of runner version manager settings/d' "$profile_file"
        fi
    fi
}

remove_rvm() {
    echo "Removing RVM..."

    # Remove the .rvm directory
    rm -rf "${HOME}/.rvm"

    # Remove lines related to rvm from the profile files
    remove_rvm_settings "${HOME}/.profile"
    
    # Also check and remove from the shell-specific profile
    SHELL_NAME=$(ps -p $$ -o comm=)
    case "$SHELL_NAME" in
        bash)
            remove_rvm_settings "${HOME}/.bashrc"
            ;;
        zsh)
            remove_rvm_settings "${HOME}/.zshrc"
            ;;
        ksh)
            remove_rvm_settings "${HOME}/.kshrc"
            ;;
        fish)
            remove_rvm_settings "${HOME}/.config/fish/config.fish"
            ;;
        *)
            echo "Shell-specific profile not modified."
            ;;
    esac

    echo "RVM has been removed. Please restart your terminal."
}



