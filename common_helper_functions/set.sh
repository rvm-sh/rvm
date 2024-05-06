#!/bin/sh

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