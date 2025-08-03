use termion::terminal_size;
use std::time::{Duration, Instant};

/// Get terminal width with fallback
fn get_terminal_width() -> usize {
    match terminal_size() {
        Ok((width, _)) => width as usize,
        Err(_) => 80, // Fallback to 80 columns if we can't detect terminal size
    }
}

/// Display the header with subtle styling
pub fn display_header() {
    let title = "🚀 RVMSH 🚀";
    let subtitle = "A Linux Runtime Version Manager";

    // Center the title and subtitle
    let terminal_width = get_terminal_width();

    println!(); // Add some space before the header

    // Center the title
    let title_padding = (terminal_width - title.chars().count()) / 2;
    let title_line = format!("{}{title}", " ".repeat(title_padding));
    println!("{}", title_line);

    // Center the subtitle
    let subtitle_padding = (terminal_width - subtitle.len()) / 2;
    let subtitle_line = format!("{}{subtitle}", " ".repeat(subtitle_padding));
    println!("{}", subtitle_line);

    // Add a subtle underline under the subtitle (shorter than full width)
    let underline_length = subtitle.len() + 4; // A bit longer than subtitle
    let underline_padding = (terminal_width - underline_length) / 2;
    let underline = format!(
        "{}{}",
        " ".repeat(underline_padding),
        "─".repeat(underline_length)
    );
    println!("{}", underline);
    println!(); // Add some space after header
}

/// Display a subtle separator (optional, for use between sections)
pub fn display_separator() {
    println!("───");
    println!();
}

/// Display execution time in bottom right corner
pub fn display_execution_time(duration: Duration) {
    let terminal_width = get_terminal_width();
    let time_str = format!("⏱️  Completed in {:.2}s", duration.as_secs_f64());
    
    // Position the time in the bottom right
    let padding = terminal_width.saturating_sub(time_str.chars().count());
    println!("\n{}{}", " ".repeat(padding), time_str);
}

/// Display a step with an icon and message
pub fn display_step(message: &str) {
    println!("🔄 {}", message);
}

/// Display a success step with checkmark
pub fn display_success(message: &str) {
    println!("✅ {}", message);
}

/// Display an error step with X mark
pub fn display_error(message: &str) {
    println!("❌ {}", message);
}

/// Display a complete banner (for compatibility)
pub fn display_banner() {
    display_header();
}
