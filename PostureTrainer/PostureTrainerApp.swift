import SwiftUI

@main
struct PostureTrainerApp: App {
    @StateObject private var store = PostureStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .onAppear {
                    NotificationManager.shared.requestPermission()
                    store.refreshCurrentWeekIfNeeded()
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        store.refreshCurrentWeekIfNeeded()
                    }
                }
        }
    }
}
