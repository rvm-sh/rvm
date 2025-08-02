mod runtime;
mod utils;

use utils::cli::Commands;
use utils::error::Result;
use utils::watcher::FileWatcher;

#[tokio::main]
async fn main() -> Result<()> {
    println!("Hello!");
    let cli = utils::cli::parse();

    match &cli.command {
        Commands::Add { runtime, version } => {
            match runtime::get_runtime(runtime) {
                Ok(rt) => {
                    if let Err(e) = rt.install(version.as_deref()) {
                        println!("Error installing {}: {}", runtime, e);
                    }
                }
                Err(e) => println!("Error: {}", e),
            }
        }
        Commands::Remove { runtime, version } => {
            match runtime::get_runtime(runtime) {
                Ok(rt) => {
                    if let Err(e) = rt.remove(version.as_deref()) {
                        println!("Error removing {}: {}", runtime, e);
                    }
                }
                Err(e) => println!("Error: {}", e),
            }
        }
        Commands::Prune { runtime, version } => {
            match runtime::get_runtime(runtime) {
                Ok(rt) => {
                    if let Err(e) = rt.prune(version) {
                        println!("Error pruning {}: {}", runtime, e);
                    }
                }
                Err(e) => println!("Error: {}", e),
            }
        }
        Commands::Update { runtime } => {
            match runtime::get_runtime(runtime) {
                Ok(rt) => {
                    if let Err(e) = rt.update() {
                        println!("Error updating {}: {}", runtime, e);
                    }
                }
                Err(e) => println!("Error: {}", e),
            }
        }
        Commands::Set { runtime, version } => {
            match runtime::get_runtime(runtime) {
                Ok(rt) => {
                    if let Err(e) = rt.set_default(version) {
                        println!("Error setting default {}: {}", runtime, e);
                    }
                }
                Err(e) => println!("Error: {}", e),
            }
        }
        Commands::Use { runtime, version } => {
            match runtime::get_runtime(runtime) {
                Ok(rt) => {
                    if let Err(e) = rt.use_version(version) {
                        println!("Error using {} {}: {}", runtime, version, e);
                    }
                }
                Err(e) => println!("Error: {}", e),
            }
        }
        Commands::Watch { args } => {
            let mut watcher = FileWatcher::new(args.clone())?;
            watcher.start().await?;
        }
        Commands::List { args } => {
            utils::list::handle_list_command(args)?;
        }
    }

    Ok(())
}
