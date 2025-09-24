use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "rvm")]
#[command(about = "A Linux Runtime Manager for Javascript, Python, Go and Rust")]
#[command(version)]
pub struct Cli {
    #[command(subcommand)]
    pub command: Commands,
}

#[derive(Subcommand)]
pub enum Commands {
    /// Install a runtime
    Add {
        /// Runtime to install (node, deno, bun, cpython, pypy, golang, rustup)
        runtime: String,
        /// Version to install (defaults to latest)
        version: Option<String>,
    },
    /// Remove a runtime or specific version
    Remove {
        /// Runtime to remove
        runtime: String,
        /// Specific version to remove (removes all if not specified)
        version: Option<String>,
    },
    /// Remove old runtime versions
    Prune {
        /// Runtime to prune
        runtime: String,
        /// Keep versions newer than this
        version: String,
    },
    /// Update runtime to latest version
    Update {
        /// Runtime to update
        runtime: String,
    },
    /// Set default runtime version
    Set {
        /// Runtime to set as default
        runtime: String,
        /// Version to set as default
        version: String,
    },
    /// Use runtime version for current session
    Use {
        /// Runtime to use
        runtime: String,
        /// Version to use
        version: String,
    },
    /// Watch for file changes and restart command
    Watch {
        /// Command and arguments (including -<seconds> for interval)
        #[arg(required = true, allow_hyphen_values = true)]
        args: Vec<String>,
    },
    /// List runtimes, available versions, or installed versions
    List {
        /// Arguments (runtimes | available <runtime> | installed <runtime>)
        #[arg(required = true)]
        args: Vec<String>,
    },
}

pub fn parse() -> Cli {
    Cli::parse()
}