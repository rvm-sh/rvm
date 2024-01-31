#!/bin/sh

# Common function to handle manager script delegation
delegate_to_manager() {
    local command=$1
    local runtime_manager=$2
    local manager_script="${HOME}/.rvm/managers/${runtime_manager}-manager.sh"

    local function_to_call="${runtime_manager}_${command}"

    if [ -f "$manager_script" ]; then
        . "$manager_script"
        if command -v "$function_to_call" &> /dev/null; then
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
            [ "$command" = "add" ] && command="install"
            delegate_to_manager "$command" "$2" "${@:3}"
            ;;
        remove | uninstall)
            # Map 'remove' and 'uninstall' to the same function
            [ "$command" = "remove" ] && command="uninstall"
            delegate_to_manager "$command" "$2" "${@:3}"
            ;;
        prune)
            delegate_to_manager "$command" "$2" "${@:3}"
            ;;
        showall | all)
            # Map 'showall' and 'all' to the same function
            [ "$command" = "all" ] && command="showall"
            delegate_to_manager "$command" "$2" "${@:3}"
            ;;
        removeall | uninstallall)
            # Map 'removeall' and 'uninstallall' to the same function
            [ "$command" = "uninstallall" ] && command="removeall"
            delegate_to_manager "$command" "$2" "${@:3}"
            ;;
        update)
            delegate_to_manager "$command" "$2" "${@:3}"
            ;;
        use | default)
            # Map 'use' and 'default' to the same function
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