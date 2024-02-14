#!/bin/sh

# Define the default and latest versions of typescript
DEFAULT_TYPESCRIPT_VERSION=""
ENABLE_AUTOCHECK="false"  # Control auto version check

INSTALLED_VERSIONS=""

# Function to call `tsc` with specified arguments
tsc() {
  # Use npx to find and execute the correct tsc version (if installed globally)
  echo "Called tsc"
}

# Function to call `tsserver` with specified arguments
tsserver() {
  # Use npx to find and execute the correct tsserver version (if installed globally)
  echo "Called tsserver"
}

# Make functions available
export -f tsc tsserver