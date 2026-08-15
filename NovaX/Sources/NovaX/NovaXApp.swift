import SwiftUI

@main
struct NovaXApp: App {
    init() {
        disableDebugger()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
