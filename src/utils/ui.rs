use termion::terminal_size;

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

/// Display a complete banner (for compatibility)
pub fn display_banner() {
    display_header();
}
