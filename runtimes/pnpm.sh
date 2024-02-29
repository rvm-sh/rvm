#!/bin/sh

download() {
  if command -v curl > /dev/null 2>&1; then
    curl -fsSL "$1"
  else
    wget -qO- "$1"
  fi
}

abort() {
  printf "%s\n" "$@"
  exit 1
}
