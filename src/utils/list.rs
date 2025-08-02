use anyhow::Result;
use crate::runtime;

pub fn handle_list_command(args: &[String]) -> Result<()> {
    if args.is_empty() {
        println!("Error: List command requires arguments");
        return Ok(());
    }
    
    match args[0].as_str() {
        "runtimes" => {
            match runtime::list_supported_runtimes() {
                Ok(runtimes) => {
                    println!("Supported runtimes:");
                    for runtime in runtimes {
                        println!("  {}", runtime);
                    }
                }
                Err(e) => println!("Error listing runtimes: {}", e),
            }
        }
        "available" => {
            if args.len() < 2 {
                println!("Error: 'list available' requires a runtime name");
                return Ok(());
            }
            println!("Available versions for {}: (not implemented yet)", args[1]);
        }
        "installed" => {
            if args.len() < 2 {
                println!("Error: 'list installed' requires a runtime name");
                return Ok(());
            }
            println!("Installed versions for {}: (not implemented yet)", args[1]);
        }
        _ => {
            println!("Error: Unknown list command '{}'. Use: runtimes, available <runtime>, or installed <runtime>", args[0]);
        }
    }
    
    Ok(())
}