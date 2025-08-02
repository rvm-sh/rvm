use super::error::Result;
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
            match runtime::get_runtime(&args[1]) {
                Ok(rt) => {
                    match rt.list_available() {
                        Ok(versions) => {
                            println!("Available versions for {}:", args[1]);
                            for version in versions {
                                println!("  {}", version);
                            }
                        }
                        Err(e) => println!("Error listing available versions: {}", e),
                    }
                }
                Err(e) => println!("Error: {}", e),
            }
        }
        "installed" => {
            if args.len() < 2 {
                println!("Error: 'list installed' requires a runtime name");
                return Ok(());
            }
            match runtime::get_runtime(&args[1]) {
                Ok(rt) => {
                    match rt.list_installed() {
                        Ok(versions) => {
                            println!("Installed versions for {}:", args[1]);
                            for version in versions {
                                println!("  {}", version);
                            }
                        }
                        Err(e) => println!("Error listing installed versions: {}", e),
                    }
                }
                Err(e) => println!("Error: {}", e),
            }
        }
        _ => {
            println!("Error: Unknown list command '{}'. Use: runtimes, available <runtime>, or installed <runtime>", args[0]);
        }
    }
    
    Ok(())
}