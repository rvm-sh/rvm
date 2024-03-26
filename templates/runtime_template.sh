
#!/bin/sh

# Name runtime here
# Name should be all small letters, eg rvm, node, cargo, python
$RUNTIME = ""

# Add installs either <specific version>, <latest>, <major> at a minimum
# Use custom implementation code according to source requirements
# Must have the below 3 implementations but can also have additional commands such as future, forward, etc
# rvm add node latest       - installs latest as defined by runtime maintainers
# rvm add node 18           - installs latest version of node 18
# rvm add node 18.14.12     - installs this specific version

add () {}

help_add () {
    echo "Add installs either <specific version>, <latest>, <major_version> depending on availability by runtime managers"
    echo "rvm add $RUNTIME <version> - installs the specific version of $RUNTIME. eg:"
    echo "rvm add $RUNTIME latest - installs the latest version of $RUNTIME"
    echo "rvm add $RUNTIME 8 - installs the latest version of $RUNTIME 8"
    echo "rvm add $RUNTIME 8.14.12 - installs this specific version of $RUNTIME 8.14.12"
}

# Remove removes <specific_version> and <major> versions only currently
# rvm remove node 18        - removes all versions of 18
# rvm remove node 18.14.12  - removes only specific version


remove() {
  if [[ $# -eq 0 ]]; then
    help_remove
    return
  fi

  if [[ $1 == "help" ]]; then
    help_remove
    return
  fi

  runtime_folder="$HOME/.$RUNTIME"

  if [[ $1 =~ ^[0-9]+$ ]]; then
    # Major version specified
    major_version=$1
    echo "Removing versions of $RUNTIME with major version $major_version"
    
    for folder in "$runtime_folder"/v"$major_version".*; do
      if [[ -d $folder ]]; then
        rm -rf "$folder"
        echo "Removed $folder"
      fi
    done
  else
    # Specific version specified
    specific_version=$1
    echo "Removing specific version $specific_version of $RUNTIME"
    
    folder="$runtime_folder/v$specific_version"
    if [[ -d $folder ]]; then
      rm -rf "$folder"
      echo "Removed $folder"
    else
      echo "Version $specific_version not found"
    fi
  fi

  # ADD PATH CHECKING TO THIS FUNCTION TO CHECK IF PATH IN THE .RVMSHRC FILE NEEDS TO BE UPDATED
  # IF YES, PLEASE  PARSE THE LATEST VERSION AVAILABLE/INSTALLED AND SET THAT AS THE DEFAULT
  # IF NO, PRINT OUT MESSAGE AND ERASE PATH AND DO NOT ADD ANYTHING TO IT
}

help_remove()  {
    echo "Remove removes <specific_version> and <major_version> versions only"
    echo "rvm remove $RUNTIME <version> - removes the specific version of $RUNTIME. eg:"
    echo "rvm remove $RUNTIME 8         - removes the versions of $RUNTIME that has the major version 8"
    echo "rvm remove $RUNTIME 8.14.12   - removes this specific version of $RUNTIME 8.14.12"
    echo "see prune command for removing all versions older than a specific version"
    echo "see removeall command for removing all versions of $RUNTIME"
}

# Update installs latest of the major version being used and makes it the default
# rvm update node
# will update to the latest node 18 if that is the major version set as default 
# Use custom implementation code according to source requirements

update () {
  if [[ $1 == "help" ]]; then
    help_update
    return
  fi
}

help_update() {
    echo "Update installs latest of the major version being used and makes it the default"
    echo "rvm update $RUNTIME - e.g updates to the latest version of $RUNTIME v8 if that is the major version set as default"
}

# Upgrade adds the latest version and makes it the default
# rvm upgrade node
# Use custom implementation code according to source requirements

upgrade () {
  if [[ $1 == "help" ]]; then
    help_update
    return
  fi
}

help_upgrade() {
    echo "Upgrade installs the latest version of $RUNTIME and makes it the default. Unlike the update command, it will jump major versions if there is a newer major version available"
    echo "rvm update $RUNTIME"
}

# Removeall removes all the versions of the runtime, e.g 
# rvm removeall node

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
    # Delete the setting in the .rvmrc file
    if grep -q "# START $RUNTIME_CAP PATH" "$HOME/.rvm/.rvmrc"; then
        echo "Removing $RUNTIME path settings from .rvmrc..."
        sed -i "/# START $RUNTIME_CAP PATH/,/# END $RUNTIME_CAP PATH/d" "$HOME/.rvm/.rvmrc"
        echo "$RUNTIME path settings removed from .rvmrc."
    else
        echo "$RUNTIME path settings not found in .rvmrc. Skipping removal."
    fi

    echo "All $RUNTIME versions and settings have been uninstalled successfully."
}


help_removeall() {
    echo "Removeall removes all the versions of $RUNTIME added to system. eg."
    echo "rvm removeall $RUNTIME"
}

# Use sets the specific <major> or <major_minor_rev> version of the runtime temporarily. Resets on restart
# rvm use node 18
# rvm use node 18.14.12

use () {
  if [[ $# -eq 0 ]]; then
    help_use
    return
  fi

  if [[ $1 == "help" ]]; then
    help_use
    return
  fi

}

help_use() {
    echo "Use sets the specific <major> or <major_minor_rev> version of the runtime temporarily. Resets on restart of os. eg."
    echo "rvm use $RUNTIME <version>"
    echo "rvm use $RUNTIME 18       - will use the latest version of $RUNTIME 18"
    echo "rvm use $RUNTIME 18.14.12 - will set the specific version(18.14.12) of $RUNTIME requested"
}

# Set sets the specified <major> or <major_minor_rev> version as the default version
# rvm set node 18
# rvm set node 18.14.12
set () {
  if [[ $# -eq 0 ]]; then
    help_set
    return
  fi

  if [[ $1 == "help" ]]; then
    help_set
    return
  fi

}

help_set() {
    echo "Set sets the specified <major> or <major_minor_rev> version as the default version. eg."
    echo "rvm set $RUNTIME <version>"
    echo "rvm set $RUNTIME 18       - will set the latest version of $RUNTIME 18 as the default"
    echo "rvm set $RUNTIME 18.14.12 - will set the specific version(18.14.12) of $RUNTIME requested as the default"
}

# Help displays the generic help for 
# rvm help node

help() {
    echo "Welcome to the help section for $RUNTIME management via rvm"
    echo "rvm supports the following commands for managing the $RUNTIME runtime: add, remove, update, upgrade, removeall, showall, use, set, help, supported, prune"
    echo "rvm <command> $RUNTIME help - displays the help for the specific command. e.g:"
    echo "rvm add $RUNTIME help - displays the help for the add command"
    echo "rvm remove $RUNTIME help - displays the help for the remove command"

    echo "To run a command, use the following syntax:"
    echo "rvm supported $RUNTIME -  returns positive confirmation that $RUNTIME is supported"
    echo "rvm add $RUNTIME latest - installs the latest version of the runtime, as define by the runtime maintainers"
    echo "rvm showall $RUNTIME installed - lists all installed versions of the runtime"
    echo "rvm showall $RUNTIME available - lists all available versions of the runtime from the runtime repository"
}

# Returns positive confirmation that runtime is supported
# rvm supported node
supported() {
  if [[ $1 == "help" ]]; then
    help_supported
    return
  fi

}

supported_help() {
    echo "Supported returns positive confirmation that $RUNTIME is supported. e.g.:"
    echo "rvm supported $RUNTIME"
}




# Showall <installed> shows all installed versions of runtime
# rvm showall node
# rvm showall node installed
# rvm showall node available
showall() {
  if [[ $# -eq 0 ]]; then
    help_showall
    return
  fi

  if [[ $1 == "help" ]]; then
    help_showall
    return
  fi

}

help_showall() {
    echo "Showall shows all installed or available versions of runtime depending on the command option"
    echo "rvm showall $RUNTIME installed - lists all installed versions of $RUNTIME"
    echo "rvm showall $RUNTIME available - lists all available versions of $RUNTIME from the runtime repository"
}

# Prune all versions of runtime older than the stated version
# rvm prune node 18
# rvm prune node 18.10
# rvm prune node 18.10.14 
prune() {
  if [[ $# -eq 0 ]]; then
    help_prune
    return
  fi

  if [[ $1 == "help" ]]; then
    help_prune
    return
  fi
    
}

help_prune() {
    echo "Prune all versions of $RUNTIME older than the stated version"
    echo "rvm prune $RUNTIME <version>  - removes all versions of $RUNTIME older than the stated version. eg:"
    echo "rvm prune $RUNTIME 18         - removes all versions of $RUNTIME older than the latest version of $RUNTIME 18 (not including any versions 18)"
    echo "rvm prune $RUNTIME 18.10      - removes all versions of $RUNTIME older than the latest version of $RUNTIME 18.10 (not including version 18.10)"
    echo "rvm prune $RUNTIME 18.10.14   - removes all versions of $RUNTIME older than the latest version of $RUNTIME 18.10.14 (not including version 18.10.14)"
}




