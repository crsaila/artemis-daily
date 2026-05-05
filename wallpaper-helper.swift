import AppKit

guard CommandLine.arguments.count > 1 else { exit(1) }
let fileURL = URL(fileURLWithPath: CommandLine.arguments[1])

// Target the built-in MacBook display specifically; fall back to primary screen
let screen = NSScreen.screens.first(where: {
    $0.localizedName.localizedCaseInsensitiveContains("built-in")
}) ?? NSScreen.main ?? NSScreen.screens.first

guard let screen else { exit(1) }
try? NSWorkspace.shared.setDesktopImageURL(fileURL, for: screen, options: [:])
