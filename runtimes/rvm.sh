#!/bin/sh

# Add installs either <specific version>, <latest>, <major> at a minimum
# rvm add node latest       - installs latest stable version
# rvm add node 18           - installs latest stable version of node 18
# rvm add node 18.14.12     - installs this specific version

add () {
    # Check for at least one argument
    if [ -z "$1" ]; then
        help_install
        return 1
    fi

    # Get the list of versions

    # parse 




}

# Remove removes <specific_version> only currently
# rvm remove node 18.14.12

remove () {

}

# Update installs latest of the major version being used and makes it the default
# rvm update node
# will update to the latest node 18 if that is the major version set as default 

update () {

}

# Upgrade adds the latest stable version and makes it the default
# rvm upgrade node

upgrade () {

}

# Removeall removes all the versions of the runtime 
# rvm removeall node

removeall() {
    echo "Removing all versions of rvm"
    echo "Removing rvm without removing installed runtimes (that are managed by rvm) will break the ability to use the installed runtimes"
    echo "It is recommended that you remove the runtimes before removing rvm"

    read -p "Are you sure you want to proceed? [y(yes)/n(no)]: " choice

    case $choice in
        y | Y | yes)
            # Remove .rvm folder
            rm -rf "$HOME/.rvm"

            # check shell name
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

            # Remove rvm link in file setting
            sed -i '/^#RVMRC PATH START$/,/^#RVMRC PATH END$/d' "$PROFILE"

            ;;
        n | N | no)
            exit 1
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac


}


# Use sets the specific <major> or <major_minor_rev> version of the runtime temporarily. Resets on restart
# rvm use node 18
# rvm use node 18.14.12

use () {

}

# Set sets the specified <major> or <major_minor_rev> version as the default version
# rvm set node 18
# rvm set node 18.14.12
set () {

}

# Help displays the generic help for 
# rvm help node

help() {

}

# Returns positive confirmation that runtime is supported
# rvm supported node
supported() {

}

# Showall <installed> shows all installed versions of runtime
# rvm showall node
# rvm showall node installed
# rvm showall node available
showall() {

}