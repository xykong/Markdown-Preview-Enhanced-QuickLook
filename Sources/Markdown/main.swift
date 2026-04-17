import AppKit

if CommandLine.arguments.contains("--export-pdf") {
    let delegate = CLIAppDelegate()
    let app = NSApplication.shared
    app.delegate = delegate
    app.setActivationPolicy(.accessory)
    app.run()
} else {
    MarkdownApp.main()
}
