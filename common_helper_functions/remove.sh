#!/bin/sh

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

