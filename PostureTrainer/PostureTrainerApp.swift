import SwiftUI

@main
struct PostureTrainerApp: App {
    @StateObject private var store = PostureStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .onAppear {
                    NotificationManager.shared.requestPermission()
                }
        }
    }
}
