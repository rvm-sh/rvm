


rvm_update() {

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

rvm_uninstall() {
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