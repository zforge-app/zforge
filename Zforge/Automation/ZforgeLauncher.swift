import Foundation
import SwiftUI
import AppKit

@main
@MainActor
enum ZforgeLauncher {
    static func main() {
        if ProcessInfo.processInfo.arguments.contains("--mcp") {
            // Run AppKit from synchronous main, rather than blocking the main
            // dispatch queue inside async main. No browser or SwiftUI scene is created.
            let app = NSApplication.shared
            app.setActivationPolicy(.prohibited)
            Task {
                await ZforgeMCPServer.run()
                app.stop(nil)
                if let event = NSEvent.otherEvent(with: .applicationDefined, location: .zero,
                                                  modifierFlags: [], timestamp: 0, windowNumber: 0,
                                                  context: nil, subtype: 0, data1: 0, data2: 0) {
                    app.postEvent(event, atStart: true)
                }
            }
            app.run()
        } else {
            ZforgeApp.main()
        }
    }
}
