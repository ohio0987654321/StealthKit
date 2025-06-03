import AppKit

// Pure AppKit main entry point
// This prevents SwiftUI from creating automatic windows
let app = NSApplication.shared
let delegate = PanelAppDelegate()
app.delegate = delegate

_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
