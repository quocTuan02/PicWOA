import SwiftUI

@main
struct PicwoaApp: App {
    var body: some Scene {
        WindowGroup {
            CameraScreen()
                .preferredColorScheme(.dark)
        }
    }
}
