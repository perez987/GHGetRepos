import SwiftUI

@main
struct GHGetReposApp: App {
    @StateObject private var settings = SettingsStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .frame(minWidth: 950, idealWidth: 950, minHeight: 720, idealHeight: 720)
        }
        .defaultSize(width: 950, height: 720)

        Settings {
            SettingsView()
                .environmentObject(settings)
                .frame(minWidth: 680, idealWidth: 680, maxWidth: 680, minHeight: 666, idealHeight: 666, maxHeight: 666)
        }
    }
}
