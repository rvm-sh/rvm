mod runtime;
mod utils;

use utils::cli::Commands;
use utils::watcher::FileWatcher;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    println!("Hello!");
    let cli = utils::cli::parse();

    match &cli.command {
        Commands::Add { runtime, version } => {
            println!(
                "Adding {} {}",
                runtime,
                version.as_deref().unwrap_or("latest")
            );
        }
        Commands::Remove { runtime, version } => match version {
            Some(v) => println!("Removing {} {}", runtime, v),
            None => println!("Removing all versions of {}", runtime),
        },
        Commands::Prune { runtime, version } => {
            println!("Pruning {} versions older than {}", runtime, version);
        }
        Commands::Update { runtime } => {
            println!("Updating {} to latest", runtime);
        }
        Commands::Set { runtime, version } => {
            println!("Setting {} {} as default", runtime, version);
        }
        Commands::Use { runtime, version } => {
            println!("Using {} {} for current session", runtime, version);
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
