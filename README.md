# rvm
## Runner Version Manager

[!WARNING]: 
 > Currently only supports linux
 > Not ready for production use


### Introduction and Motivations
The runner version manager was created because I had trouble running multiple versions of pnpm, especially projects that lock the version of the runner. I've also had issues running other js frameworks from other people's projects for some reason or the other, and hopefully this solves some of the issue. 

I ultimately hope to be able to use this to manage all my runners, whether it be js, python, rust, etc.

Inspired by the simplicity of node version manager

### Definitions
A runner, as I would define them, is the executable that is run to execute another script / command / task / etc. This includes pnpm, npm, node, yarn, react, vue and other js runners / frameworks / compilers currently but hopefully will include other programming language such as python and rust. The main goal is to have a single version manager for everything that can fall under the category of a runner

### Goals
 - An all-in-one version manager for any runner
 - Any runner has a default but can also use any specific version that is installed
 - Use multiple overlapping runners (for example node, deno and bun) in the same system
 - Clean remove / delete of rvm as well as to remove any packages installed by rvm
 - Enable control of runners without another runner, (for example corepack needs node)
 - Clean - aims to leave no footprint after uninstall whenever possible
 - Stick to pure shell commands

### Future possibilities
- Target to be POSIX compliant
- Target to support node, yarn, bun, python and others
- Target to ensure compatibility with all shells
- Target to support MacOS, Windows, as well as different architectures in the future
- Target to have renames/alias, for example, if i call npm install, it calls pnpm install instead
- Target ask if it will remove any path redirection / bindings on uninstall of rvm
- Target ask if it will remove any installed packages on uninstall of rvm

### Usage Commands

#### Installation
```
wget -qO- https://raw.githubusercontent.com/rvm-sh/rvm/<version>/install.sh | sh -
```

#### Install the latest version of a runner
```
rvm add pnpm@latest
```
also the `install` argument works too
```
rvm install pnpm@latest
```

#### Install a specific version of a runner
Use either `add` or `install`
```
rvm add pnpm@8
```
or even
```
rvm install pnpm@8.14.0
```

#### Set a specific runner version as default
Use either `set` or `use`
```
rvm set pnpm@18.14.0
```
or
```
rvm use pnpm@18.14.0
```

#### Show version of default runner
```
pnpm -v
```

#### Using the runner
Use the default runner:
```
pnpm build
```
Use a specific runner:
```
pnpm@8.14.0 build
```

#### Show all installed versions of a specific runner
```
rvm showall pnpm
```

or 
```
rvm all pnpm
```

#### Remove specific version of a runner
```
rvm remove pnpm@8.14.0
```

#### Prune all older versions of a runner
This deletes all versions of a runner older than the specified runner (specified version not included)
```
rvm prune pnpm@6.12.4
```

#### Remove all versions of a runner
```
rvm removeall pnpm
```

#### Uninstall rvm 
```
rvm uninstall rvm
```
```
rvm remove rvm
```

#### Update rvm
```
rvm update rvm
```




