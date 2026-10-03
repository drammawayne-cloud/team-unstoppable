import SwiftUI

@main
struct TeamUnstoppableApp: App {
    @StateObject private var store = AppStore()
    @StateObject private var radio = RadioPlayer()
    @AppStorage("appearance") private var appearance = "light"
    @Environment(\.scenePhase) private var phase
    var body: some Scene {
        WindowGroup {
            AppShell()
                .environmentObject(store).environmentObject(radio)
                .preferredColorScheme(appearance == "system" ? nil : (appearance == "dark" ? .dark : .light))
                .task { radio.configure(store.station); await store.refresh(); radio.configure(store.station) }
                .onChange(of: store.station) { _, station in radio.configure(station) }
                .onChange(of: phase) { _, value in radio.setForeground(value == .active) }
        }
    }
}
