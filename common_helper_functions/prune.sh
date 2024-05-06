#!/bin/sh

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