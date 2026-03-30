import SwiftUI

@main
struct ClaudeCodeManagerApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .defaultSize(width: 1100, height: 720)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .saveItem) {
                Button("保存") {
                    try? appState.saveSettings()
                }
                .keyboardShortcut("s", modifiers: .command)
            }
        }
    }
}
