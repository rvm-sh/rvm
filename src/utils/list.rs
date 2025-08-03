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
                            if versions.is_empty() {
                                println!("  No versions installed");
                            } else {
                                for version in versions {
                                    // Remove 'v' prefix for display
                                    let clean_version = version.strip_prefix('v').unwrap_or(&version);
                                    println!("  ✓ {}", clean_version);
                                }
                            }
                        }
                        Err(e) => println!("Error listing installed versions: {}", e),
                    }
                }
                Err(e) => println!("Error: {}", e),
            }
        }
        _ => {
            println!("Unknown list command. To use list, you can either use available or installed:\n");
            println!("rvm list available <runtime> - lists all available runtime versions in the public repository");
            println!("e.g: rvm list available node\n");
            println!("rvm list installed <runtime> - lists all locally installed versions");
            println!("e.g: rvm list installed node");
        }
    }
    
    Ok(())
}