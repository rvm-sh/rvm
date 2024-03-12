# rvmsh
## Runtime Version Manager

>[!WARNING]
> Currently only supports bash on linux 

> [!CAUTION]
> Not ready for production use, functions may not yet have been implemented or even work


## Introduction and Motivations
rvmsh was created because I had trouble in the course of my programing experience, from having issues managing new runtimes, multiple runtime managers, issues with packages, etc. 

I ultimately hope to be able to use this to manage all my runtimes, whether it be js, python, rust, etc. Hopefully, I would also be able to have some kind of auto determiner that just decides what the correct runtime version to use and to call that version.

Inspired by the simplicity of nvm.

## Definitions
A runtime is the programme that is run to execute another script / command / task / etc. For the purpose of rvmsh this can include package managers, compilers, linters, etc. 

## Goals
Current goal is to manage pnpm, npm, node, yarn, bun and other js runtimes / frameworks / compilers but hopefully will include other programming language such as python and rust.

Primary principles:
 - Monolithic - rvm manages everything instead of modular plugins
 - Multi OS support - currently supports Linux, MacOS, WSL
 - Multi-shell support - currently only supports bash. Plan for zsh and other shells
 - Multi-language - aim to support languages that I use, such as python and rust
 - Runtime agnostic - aim to support as many runtimes as possible to encourage ecosystem growth / experimentation
 - Clean - all installation and usage files / folders / settings predictable, self-contained and leaves no trace on uninstall
 - Maximal compatibility - aims to be maximally compatible 
 - Minimal dependency - minimise dependency on external packages that do not tend to come standard in unix-based systems 

Future goals:
 - Support runtimes from other languages
 - Support autocheck / auto determiner to automatically determine and call the correct version

nvm > rvmsh > asdf
* The goal of this project is to be a more-encompassing, monolithic version of nvm. 

Currently supports:
 - jq
 - node
 - pnpm

* Does not support npm currently

Working on 
 - standalone npm / npx support
 - bun
 - yarn
 - typescript
 - deno
 - llrt

Feature goal:
 - An all-in-one version manager for any runner
 - Stick to pure shell commands, no dependencies
 - Monolithic rather than modular (any new package being supported is added via update to rvm rather than as a plugin)
 - Any runner has a default but can also use any specific version that is installed
 - Use multiple overlapping runners (for example pnpm, npm and bun) in the same system
 - Clean - aims to leave no footprint after uninstall whenever possible

## Future possibilities
- Target to be POSIX compliant
- Target to support node, python, rust and others
- Target to ensure compatibility with all shells
- Target to support MacOS, Windows, as well as different architectures in the future
- Target to have renames/alias, for example, if i call npm install, it calls pnpm install instead
- Target ask if it will remove any path redirection / bindings on uninstall of rvm
- Target ask if it will remove any installed packages on uninstall of rvm
- Ability to set new profile for a new shell installed

## Usage Commands

### Installation
Download and pipe to your shell, for example with bash:
```
wget -qO- https://raw.githubusercontent.com/rvm-sh/rvm/main/install.sh | bash -
```

On macos (using default zsh):
```
wget -qO- https://raw.githubusercontent.com/rvm-sh/rvm/main/install.sh | zsh -
```

### Install the latest version of a runner
```
rvm add pnpm latest
```
also the `install` argument works too
```
rvm install pnpm latest
```

### Install a specific version of a runner
Use either `add` or `install`
```
rvm add pnpm 8
```
or even
```
rvm install pnpm 8.14.0
```

### Upgrade a runner
Installs latest version of the runner (of the same major version) and sets this new version as default
```
rvm upgrade pnpm
```

### Set a specific runner version as default
Use either `set` or `use`
```
rvm set pnpm 18.14.0
```
or
```
rvm use pnpm 18.14.0
```

### Show version of default runner
```
rvm show pnpm
```

### Using the runner
Use the default runner:
```
pnpm build
```
Use a specific runner:
```
pnpm 8.14.0 build
```

### Show all installed versions of a specific runner
```
rvm showall pnpm
```

or 
```
rvm all pnpm
```

### Remove specific version of a runner
```
rvm remove pnpm 8.14.0
```

### Prune all older versions of a runner
This deletes all versions of a runner older than the specified runner (specified version not included)
```
rvm prune pnpm 6.12.4
```

### Remove all versions of a runner
```
rvm removeall pnpm
```

### Uninstall rvm 
```
rvm uninstall rvm
```
```
rvm remove rvm
```

### Update rvm
```
rvm update rvm
```


Issues:
If you have nvm installed previously, the nvm env variables are not removed automatically on uninstall. This will break the functionality of rvm when /usr/bin/env is used in any script. Currently, a manual process is required to clean up any of these variables.




