use anyhow::{anyhow, Result};
use notify::{Config, RecommendedWatcher, RecursiveMode, Watcher, Event, EventKind};
use std::path::Path;
use std::process::Stdio;
use std::sync::mpsc;
use std::time::Duration;
use tokio::process::{Child, Command};
use tokio::time::{sleep, Instant};

pub struct FileWatcher {
    command: String,
    args: Vec<String>,
    interval: u64,
    current_process: Option<Child>,
}

impl FileWatcher {
    pub fn new(args: Vec<String>) -> Result<Self> {
        let (command, args, interval) = Self::parse_args(args)?;
        
        Ok(FileWatcher {
            command,
            args,
            interval,
            current_process: None,
        })
    }

    fn parse_args(args: Vec<String>) -> Result<(String, Vec<String>, u64)> {
        if args.is_empty() {
            return Err(anyhow!("No command provided"));
        }

        // Check if first arg is a quoted command (contains spaces)
        if args[0].contains(' ') {
            // First arg is quoted - split it and look for interval in remaining args
            let parts: Vec<&str> = args[0].split_whitespace().collect();
            let command = parts[0].to_string();
            let mut filtered_args: Vec<String> = parts[1..].iter().map(|s| s.to_string()).collect();
            
            let mut interval = None;
            let mut interval_index = None;

            // Look for interval in remaining args (args[1..])
            for (i, arg) in args[1..].iter().enumerate() {
                if arg.starts_with('-') && arg.len() > 1 && arg[1..].chars().all(|c| c.is_ascii_digit()) {
                    if let Ok(seconds) = arg[1..].parse::<u64>() {
                        interval = Some(seconds);
                        interval_index = Some(i);
                    }
                }
            }

            // Add remaining args except the interval
            for (i, arg) in args[1..].iter().enumerate() {
                if Some(i) != interval_index {
                    filtered_args.push(arg.clone());
                }
            }

            let final_interval = interval.unwrap_or_else(|| {
                println!("Warning: No interval specified. Default is 5 seconds.");
                println!("Press Enter to continue or Ctrl+C to cancel...");
                std::io::stdin().read_line(&mut String::new()).unwrap();
                5
            });
            
            return Ok((command, filtered_args, final_interval));
        }

        // No quoted command - find last -<number> as interval
        let command = args[0].clone();
        let mut filtered_args = Vec::new();
        let mut interval = None;
        let mut interval_index = None;

        // Find the last -<digits> argument
        for (i, arg) in args[1..].iter().enumerate() {
            if arg.starts_with('-') && arg.len() > 1 && arg[1..].chars().all(|c| c.is_ascii_digit()) {
                if let Ok(seconds) = arg[1..].parse::<u64>() {
                    interval = Some(seconds);
                    interval_index = Some(i + 1); // +1 because we're iterating from args[1..]
                }
            }
        }

        // Add all args except the interval to filtered_args
        for (i, arg) in args[1..].iter().enumerate() {
            if Some(i + 1) != interval_index {
                filtered_args.push(arg.clone());
            }
        }

        let final_interval = interval.unwrap_or_else(|| {
            println!("Warning: No interval specified. Default is 5 seconds.");
            println!("Press Enter to continue or Ctrl+C to cancel...");
            std::io::stdin().read_line(&mut String::new()).unwrap();
            5
        });

        Ok((command, filtered_args, final_interval))
    }

    pub async fn start(&mut self) -> Result<()> {
        println!("Watching for changes... (interval: {}s)", self.interval);
        println!("Press Ctrl+C to stop");

        let (tx, rx) = mpsc::channel();
        let mut watcher = RecommendedWatcher::new(
            move |result: Result<Event, notify::Error>| {
                if let Ok(event) = result {
                    if let EventKind::Modify(_) | EventKind::Create(_) = event.kind {
                        // Filter out temporary files and build directories
                        let should_ignore = event.paths.iter().any(|path| {
                            let path_str = path.to_string_lossy();
                            path_str.contains("target/") 
                                || path_str.contains("node_modules/")
                                || path_str.contains(".git/")
                                || path_str.ends_with(".tmp")
                                || path_str.ends_with("~")
                        });

                        if !should_ignore {
                            let _ = tx.send(event);
                        }
                    }
                }
            },
            Config::default(),
        )?;

        watcher.watch(Path::new("."), RecursiveMode::Recursive)?;

        // Start initial process
        self.restart_process().await?;

        let mut last_restart = Instant::now();

        loop {
            if let Ok(_event) = rx.try_recv() {
                let now = Instant::now();
                let elapsed = now.duration_since(last_restart);
                
                // Debounce: only restart if enough time has passed
                if elapsed >= Duration::from_secs(self.interval) {
                    println!("File change detected, restarting...");
                    self.restart_process().await?;
                    last_restart = now;
                }
            }
            
            sleep(Duration::from_millis(100)).await;
        }
    }

    async fn restart_process(&mut self) -> Result<()> {
        // Kill existing process
        if let Some(mut child) = self.current_process.take() {
            let _ = child.kill().await;
            let _ = child.wait().await;
        }

        println!("Running: {} {}", self.command, self.args.join(" "));

        // Start new process
        let mut cmd = Command::new(&self.command);
        cmd.args(&self.args);
        cmd.stdout(Stdio::inherit());
        cmd.stderr(Stdio::inherit());

        match cmd.spawn() {
            Ok(child) => {
                self.current_process = Some(child);
                Ok(())
            }
            Err(e) => Err(anyhow!("Failed to start process: {}", e)),
        }
    }
}