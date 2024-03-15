
#!/bin/sh

# Add installs either <specific version>, <latest>, <major> at a minimum
# rvm add node latest       - installs latest stable version
# rvm add node 18           - installs latest stable version of node 18
# rvm add node 18.14.12     - installs this specific version

add () {

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




