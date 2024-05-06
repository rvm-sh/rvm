#!/bin/sh

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