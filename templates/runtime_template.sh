#!/bin/sh

# Add, update, upgrade and showall available should be manually written
# Remove, removeall, supported, use, set should be standard
# Standard functions should have their own shell script (so that we can change it without having to reimplement every script)

# Name runtime here
# Name should be all small letters, eg rvm, node, cargo, python
$RUNTIME = ""

## ADD ##
# Add installs either <specific version>, <latest>, <major> at a minimum
# Use custom implementation code according to source requirements
# Must have the below 3 implementations but can also have additional commands such as future, forward, etc
# rvm add node latest       - installs latest as defined by runtime maintainers
# rvm add node 18           - installs latest version of node 18
# rvm add node 18.14.12     - installs this specific version

add () {}

## UPDATE ##
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



## UPGRADE ##
# Upgrade adds the latest version and makes it the default
# rvm upgrade node
# Use custom implementation code according to source requirements

upgrade () {
  if [[ $1 == "help" ]]; then
    help_update
    return
  fi
}


## SHOWALL ##
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

## REMOVE ##
remove () {}

## REMOVEALL ##
removeall () {}

## SUPPORTED ##
# Returns positive confirmation that runtime is supported
# rvm supported node
supported() {
  if [[ $1 == "help" ]]; then
    help_supported
    return
  else
    echo "$RUNTIME is supported"
  fi

}

## USE ##


## SET ##





# ALL HELP FUNCTIONS

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

help_add () {
    echo "Add installs either <specific version>, <latest>, <major_version> depending on availability by runtime managers"
    echo "rvm add $RUNTIME <version> - installs the specific version of $RUNTIME. eg:"
    echo "rvm add $RUNTIME latest - installs the latest version of $RUNTIME"
    echo "rvm add $RUNTIME 8 - installs the latest version of $RUNTIME 8"
    echo "rvm add $RUNTIME 8.14.12 - installs this specific version of $RUNTIME 8.14.12"
}

help_update() {
    echo "Update installs latest of the major version being used and makes it the default"
    echo "rvm update $RUNTIME - e.g updates to the latest version of $RUNTIME v8 if that is the major version set as default"
}

help_upgrade() {
    echo "Upgrade installs the latest version of $RUNTIME and makes it the default. Unlike the update command, it will jump major versions if there is a newer major version available"
    echo "rvm update $RUNTIME"
}

help_use() {
    echo "Use sets the specific <major> or <major_minor_rev> version of the runtime temporarily. Resets on restart of os. eg."
    echo "rvm use $RUNTIME <version>"
    echo "rvm use $RUNTIME 18       - will use the latest version of $RUNTIME 18"
    echo "rvm use $RUNTIME 18.14.12 - will set the specific version(18.14.12) of $RUNTIME requested"
}

help_set() {
    echo "Set sets the specified <major> or <major_minor_rev> version as the default version. eg."
    echo "rvm set $RUNTIME <version>"
    echo "rvm set $RUNTIME 18       - will set the latest version of $RUNTIME 18 as the default"
    echo "rvm set $RUNTIME 18.14.12 - will set the specific version(18.14.12) of $RUNTIME requested as the default"
}

supported_help() {
    echo "Supported returns positive confirmation that $RUNTIME is supported. e.g.:"
    echo "rvm supported $RUNTIME"
}

help_showall() {
    echo "Showall shows all installed or available versions of runtime depending on the command option"
    echo "rvm showall $RUNTIME installed - lists all installed versions of $RUNTIME"
    echo "rvm showall $RUNTIME available - lists all available versions of $RUNTIME from the runtime repository"
}

help_remove()  {
    echo "Remove removes <specific_version> and <major_version> versions only"
    echo "rvm remove $RUNTIME <version> - removes the specific version of $RUNTIME. eg:"
    echo "rvm remove $RUNTIME 8         - removes the versions of $RUNTIME that has the major version 8"
    echo "rvm remove $RUNTIME 8.14.12   - removes this specific version of $RUNTIME 8.14.12"
    echo "see prune command for removing all versions older than a specific version"
    echo "see removeall command for removing all versions of $RUNTIME"
}

help_removeall() {
    echo "Removeall removes all the versions of $RUNTIME added to system. eg."
    echo "rvm removeall $RUNTIME"
}

help_prune() {
    echo "Prune all versions of $RUNTIME older than the stated version"
    echo "rvm prune $RUNTIME <version>  - removes all versions of $RUNTIME older than the stated version. eg:"
    echo "rvm prune $RUNTIME 18         - removes all versions of $RUNTIME older than the latest version of $RUNTIME 18 (not including any versions 18)"
    echo "rvm prune $RUNTIME 18.10      - removes all versions of $RUNTIME older than the latest version of $RUNTIME 18.10 (not including version 18.10)"
    echo "rvm prune $RUNTIME 18.10.14   - removes all versions of $RUNTIME older than the latest version of $RUNTIME 18.10.14 (not including version 18.10.14)"
}




