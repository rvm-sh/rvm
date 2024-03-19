
#!/bin/sh

# Name runtime here
$RUNTIME = ""

# Add installs either <specific version>, <latest>, <major> at a minimum
# Add can implement runtime-specific arguments such as 
# rvm add node latest       - installs latest as defined by runtime maintainers
# rvm add node 18           - installs latest version of node 18
# rvm add node 18.14.12     - installs this specific version

add () {
    local $

}

help_add () {
    echo "Add installs either <specific version>, <latest>, <major_version> or <major_minor_version> depending on availability by runtime managers"
    echo "rvm add $RUNTIME <version> - installs the specific version of $RUNTIME. eg:"
    echo "rvm add $RUNTIME latest - installs the latest version of $RUNTIME"
    echo "rvm add $RUNTIME 8 - installs the latest version of $RUNTIME 8"
    echo "rvm add $RUNTIME 8.14 - installs the latest version of $RUNTIME 8.14"
    echo "rvm add $RUNTIME 8.14.12 - installs this specific version of $RUNTIME 8.14.12"

}

# Remove removes <specific_version>, <major_version> and <major> versions only currently
# rvm remove node 18
# rvm remove node 18.14.12

remove () {

}

# Update installs latest of the major version being used and makes it the default
# rvm update node
# will update to the latest node 18 if that is the major version set as default 

update () {

}

# Upgrade adds the latest version and makes it the default
# rvm upgrade node

upgrade () {

}

# Removeall removes all the versions of the runtime 
# rvm removeall node

removeall() {

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

# Prune all versions of runtime older than the stated version
# rvm prune node 18
# rvm prune node 18.10
# rvm prune node 18.10.14 
prune() {
    
}




