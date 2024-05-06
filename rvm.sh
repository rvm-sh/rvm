#!/bin/sh

# Common function to handle manager script delegation
delegate_to_manager() {
    local command=$1
    local runtime_manager=$2
    local manager_script="${HOME}/.rvm/runtimes/${runtime_manager}.sh"

    local function_to_call="${command}"

    if [ -f "$manager_script" ]; then
        . "$manager_script"
        if command -v "$function_to_call" &> /dev/null; then
            echo "Calling $function_to_call $3 $4"
            $function_to_call "$3" "$4"
        else
            echo "Function $function_to_call not found in $manager_script"
        fi
    else
        echo "Manager script for $runtime_manager not found. This runtime is not supported"
    fi
}

# Define the rvm function
rvm() {
    local command=$1

    # Check if the command is empty and call the help function if it is
    if [ -z "$command" ]; then
        help
        return  # Exit the function early
    fi

    case $command in
        add | install)
            # Map 'add' and 'install' to the same function
            # Install a version of the runtime
            [ "$command" = "install" ] && command="add"
            delegate_to_manager "$command" "$2" "${@:3}"
            source_settings
            ;;
        remove | uninstall)
            # Map 'remove' and 'uninstall' to the same function
            # Uninstall a specific version of the runtime
            [ "$command" = "uninstall" ] && command="remove"
            delegate_to_manager "$command" "$2" "${@:3}"
            source_settings
            ;;
        prune)
            #Uninstall all older versions of a runtime
            delegate_to_manager "$command" "$2" "${@:3}"
            source_settings
            ;;
        showall | all)
            # Map 'showall' and 'all' to the same function
            # Show all installed versions of a runtime
            [ "$command" = "all" ] && command="showall"
            delegate_to_manager "$command" "$2" "${@:3}"
            source_settings
            ;;
        removeall | uninstallall)
            # Map 'removeall' and 'uninstallall' to the same function
            # Uninstall all versions of a runtime
            [ "$command" = "uninstallall" ] && command="removeall"
            delegate_to_manager "$command" "$2" "${@:3}"
            source_settings
            ;;
        update)
            # Update the default runtime to the latest major version and set this as default
            delegate_to_manager "$command" "$2" "${@:3}"
            source_settings
            ;;
        use)
            # Temporarily set a specific node version
            delegate_to_manager "$command" "$2" "${@:3}"
            source_settings
            ;;
        set | default)
            # Map 'set' and 'default' to the same function
            # Set default version of runtime
            [ "$command" = "default" ] && command="set"
            delegate_to_manager "$command" "$2" "${@:3}"
            source_settings
            ;;
        help)
            # Directly handle the help command
            if [ -z "$2" ]; then
                help
                return
            else 
                delegate_to_manager "$command" "$2" "${@:3}"
            fi

        version)
            # Directly handle the version command
            version "$@"
            ;;
        *)
            echo "Unrecognized command"
            help
            ;;
    esac
}

# Help function
help() {
    if [ -z "$2" ]; then
        cat <<EOF
            Welcome to rvmsh

            Current supported runtimes:
            - node
            - pnpm

            Usage: rvm [command] [runtime] [options]

            The following commands may be available for each runtime: 
            add/install, remove/uninstall, prune, showall, removeall, uninstallall, update, use, default, help
            (Currently not all commands may have been implemented for every runner)

            Every runtime has its own versioning, release, hosting and management quirks (as well as different pace in update in rvm).
            Get the guides from the respective help page for the runtime via:

            rvm help [runtime], e.g:
            rvm help node
EOF

    else
        echo "Hello, $2. What can I do for you?"
    fi
}

# Help function
version() {
    echo "No version tracking yet"
}

source_settings() {
    SHELL_NAME=$(ps -p $$ -o comm=)

    case "$SHELL_NAME" in
        bash)
            source "$HOME/.bashrc"
            ;;
        zsh)
            source "$HOME/.zshrc"
            ;;
        ksh)
            source "$HOME/.kshrc"
            ;;
        fish)
            source "$HOME/.config/fish/config.fish"
            ;;
        *sh|sh)
            source ="$HOME/.profile"
            ;;
        *)
            echo "Unrecognized shell: $SHELL_NAME"
            exit 1
            ;;
    esac

}