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
            echo "Calling $function_to_call $3"
            $function_to_call "$@"
        else
            echo "Function $function_to_call not found in $manager_script"
        fi
    else
        echo "Manager script for $runtime_manager not found"
    fi
}


# Define the rvm function
rvm() {
    local command=$1
    case $command in
        add | install)
            # Map 'add' and 'install' to the same function
            # Install a version of the runtime
            [ "$command" = "add" ] && command="install"
            delegate_to_manager "$command" "$2" "${@:3}"
            ;;
        remove | uninstall)
            # Map 'remove' and 'uninstall' to the same function
            # Uninstall a specific version of the runtime
            [ "$command" = "remove" ] && command="uninstall"
            delegate_to_manager "$command" "$2" "${@:3}"
            ;;
        prune)
            #Uninstall all older versions of a runtime
            delegate_to_manager "$command" "$2" "${@:3}"
            ;;
        showall | all)
            # Map 'showall' and 'all' to the same function
            # Show all installed versions of a runtime
            [ "$command" = "all" ] && command="showall"
            delegate_to_manager "$command" "$2" "${@:3}"
            ;;
        removeall | uninstallall)
            # Map 'removeall' and 'uninstallall' to the same function
            # Uninstall all versions of a runtime
            [ "$command" = "uninstallall" ] && command="removeall"
            delegate_to_manager "$command" "$2" "${@:3}"
            ;;
        update)
            # Update the default runtime to the latest major version and set this as default
            delegate_to_manager "$command" "$2" "${@:3}"
            ;;
        use)
            # Temporarily set a specific node version
            [ "$command" = "use" ] && command="default"
            delegate_to_manager "$command" "$2" "${@:3}"
            ;;
        set | default)
            # Map 'set' and 'default' to the same function
            # Set default version of runtime
            [ "$command" = "use" ] && command="default"
            delegate_to_manager "$command" "$2" "${@:3}"
            ;;
        help)
            # Directly handle the help command
            help "$@"
            ;;
        version)
            # Directly handle the version command
            version "$@"
            ;;
        *)
            echo "Unrecognized command: $command"
            ;;
    esac
}

# Help function
help() {
    if [ -z "$2" ]; then
        echo "Available commands: add, install, remove, uninstall, prune, showall, removeall, uninstallall, update, use, default, help"
    else
        echo "Hello, $2. What can I do for you?"
    fi
}

# Help function
version() {
    echo "No version tracking yet"
}