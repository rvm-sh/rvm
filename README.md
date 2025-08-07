# RVMSH - A Linux Runtime Manager for Javascript, Python, Go and Rust

## Introduction
RVMSH is a runtime version manager for Linux built to install and manage (to the best capability) multiple runtimes and versions available for each programming language. The goal is to encourage the use of alternative runtimes more easily, as well as manage multiple versions of the software due to inconsistent runtime management across the different runtimes.

Inspired by nvm.

## Goals
1. Encourage the use of alternative runtimes
2. Standardise runtime version management across different languages
3. Reduce mental load of dealing with different runtimes and package managers
4. Have a nice little watch mode so that I don't have to context switch as often

## Functionality Target
1. Manage one or more runtimes for js, go, python and rust
2. Manage one or more versions of the same runtime, if the feature is not available by the runtime
3. Watch mode (akin to nodemon) that can be enabled to automatically watch and restart the runtime on changes

## Manage one or more runtimes
### Get list of runtimes available
Displays the list of runtimes supported by rvm

```
rvm list runtimes
```

### Get list of available versions of a runtime
Gets a list of available versions of the runtime specified

```
rvm list available <runtime>
```

### Get list of installed runtimes
Gets a list of installed versions of the runtime specified

```
rvm list installed <runtime>
```

### Installing runtimes - Not implemented yet
Installs the runtime specified. If not specified, or latest is mentioned, the latest version is installed

```
rvm add <runtime>
```

or

```
rvm add <runtime> latest
```

or

```
rvm add <runtime> version
```

### Uninstalling runtime
#### Remove all versions of the runtime - Not implemented yet
Removes all versions of the runtime, as well as the .profile settings

```
rvm remove <runtime>
```

#### Remove a specific version of the runtime - Not implemented yet
Deletes the specific runtime from the system. If it is set as the default in .profile, this is changed to the latest runtime version available

```
rvm remove <runtime> <version>
```

#### Prune old runtime versions - Not implemented yet
Removes runtimes older than the specified runtime

```
rvm prune <runtime> <version>
```

### Updating runtime
Installs the latest version of the runtime without deleting the old runtime, and sets it as the default runtime

```
rvm update <runtime>
```

## Manage one or more versions of the runtime

### Set default runtime
Sets the runtime version as the default version in the user's .profile file

```
rvm set <runtime> <version>
```

### Use default version of runtime until next reset
Sets the runtime version as the temporary default until the next restart

```
rvm use <runtime> <version>
```

## Watch for changes
Watch for changes is implemented in time due to the complex nature of determining when best to run, and also the overhead in actually compiling the application. Ignores any files/folders that are named in the .gitignore files.

The last dash-number (e.g. `-5`) is the rebuild time. To account for some scenarios where a dash-number may need to be part of the inner argument (or for more complex commands), the inner argument can put in double quotes)
```
rvm watch <command> -<time_in_seconds>

## Example utilising cargo run
rvm watch cargo run -5

## Example where the dash-number is part of the inner argument
rvm watch "git diff -3"

rvm watch "cargo build && ./target/debug/rvm" -10
```

* Please note that the watcher may fail if your inotify watches are not sufficient. To increase your inotify watches, please follow [this guide](https://www.suse.com/support/kb/doc/?id=000020048) (should work in most distros)


## Supported Runtimes and Features
### Supported runtimes
- JS
  - node
  - deno
  - bun
  - pnpm
  - yarn

- Python
  - python(cPython)
  - pypy

- Rust
 - rustup

- Go
 - go


### Supported features
 - python - runtime install, version management, version use & watch mode
 - js - runtime and package manager install, version management, version use and watch mode
 - go - runtime install, version management, version use and watch mode
 - rust - runtime install and watch mode (rustup / cargo already manages versions)

## Key Notes
1. All runtimes are installed in their respective `.<runtime>/v<version>` in the `$HOME` folder (`home/<user>`). This may be different from the standard installation directory. For example, golang installation has the files put in `usr/local`. The difference is that files in the user's home folder is only available to the user, while `usr/local` makes it available to every user.
2. Settings for path is put in `.profile`. In some terminals and distros, this may not work. For now, you can choose to source the `.profile` from your terminal's specific settings.



## Why?
- Why another tool - yes, I am aware of [this](https://xkcd.com/927/). Just wanted one that works with my mental model. Hopefully you will find it useful too
- Why not in Shell:
 - originally built in shell but I got tired of trying to shoehorn it in shell and decided to write in another language
 - almost everything i need is available in a module
 - can't be bothered trying to write/match posix, bash, zsh, etc
- Why Rust - ~~just the language I'm trying to master.~~ Just had to choose one. Note, the "R" in rvm is for runtime rather than rust
- Why only 4 languages - these are the only languages I use. Goal is to add more if I start using other languages
- Why only Linux - currently I only use Linux and I'd like to support the ecosystem
- Why pnpm/yarn - wanted an easy way to install and use these package managers instead of npm (npm is default in node)
