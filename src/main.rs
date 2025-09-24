mod runtime;
mod utils;

use utils::cli::Commands;
use utils::error::Result;
use utils::watcher::FileWatcher;
use std::time::Instant;

#[tokio::main]
async fn main() -> Result<()> {
    let start_time = Instant::now();
    utils::ui::display_header();
    let cli = utils::cli::parse();

    match &cli.command {
        Commands::Add { runtime, version } => match runtime::get_runtime(runtime) {
            Ok(rt) => {
                let version = version.clone();
                if let Err(e) = tokio::task::spawn_blocking(move || rt.add(version.as_deref()))
                    .await
                    .unwrap()
                {
                    println!("Error adding {}: {}", runtime, e);
                }
            }
            Err(e) => println!("Error: {}", e),
        },
        Commands::Remove { runtime, version } => match runtime::get_runtime(runtime) {
            Ok(rt) => {
                let version = version.clone();
                if let Err(e) = tokio::task::spawn_blocking(move || rt.remove(version.as_deref()))
                    .await
                    .unwrap()
                {
                    println!("Error removing {}: {}", runtime, e);
                }
            }
            Err(e) => println!("Error: {}", e),
        },
        Commands::Prune { runtime, version } => match runtime::get_runtime(runtime) {
            Ok(rt) => {
                let version = version.clone();
                if let Err(e) = tokio::task::spawn_blocking(move || rt.prune(&version))
                    .await
                    .unwrap()
                {
                    println!("Error pruning {}: {}", runtime, e);
                }
            }
            Err(e) => println!("Error: {}", e),
        },
        Commands::Update { runtime } => match runtime::get_runtime(runtime) {
            Ok(rt) => {
                if let Err(e) = tokio::task::spawn_blocking(move || rt.update())
                    .await
                    .unwrap()
                {
                    println!("Error updating {}: {}", runtime, e);
                }
            }
            Err(e) => println!("Error: {}", e),
        },
        Commands::Set { runtime, version } => match runtime::get_runtime(runtime) {
            Ok(rt) => {
                let version = version.clone();
                if let Err(e) = tokio::task::spawn_blocking(move || rt.set_default(&version))
                    .await
                    .unwrap()
                {
                    println!("Error setting default {}: {}", runtime, e);
                }
            }
            Err(e) => println!("Error: {}", e),
        },
        Commands::Use { runtime, version } => match runtime::get_runtime(runtime) {
            Ok(rt) => {
                let version_clone = version.clone();
                if let Err(e) = tokio::task::spawn_blocking(move || rt.use_version(&version_clone))
                    .await
                    .unwrap()
                {
                    println!("Error using {} {}: {}", runtime, version, e);
                }
            }
            Err(e) => println!("Error: {}", e),
        },
        Commands::Watch { args } => {
            let mut watcher = FileWatcher::new(args.clone())?;
            watcher.start().await?;
        }
        Commands::List { args } => {
            let args_clone = args.clone();
            if let Err(e) = tokio::task::spawn_blocking(move || utils::list::handle_list_command(&args_clone))
                .await
                .unwrap()
            {
                println!("Error with list command: {}", e);
            }
        }
    }

    let duration = start_time.elapsed();
    utils::ui::display_execution_time(duration);
    Ok(())
}
