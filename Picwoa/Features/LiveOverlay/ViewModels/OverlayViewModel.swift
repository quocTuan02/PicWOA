import SwiftUI

@MainActor
@Observable
final class OverlayViewModel {

    var currentResponse: AICoachingResponse?
    var personDetected: Bool = false

    private(set) var lastResponse: AICoachingResponse?

    var showOverlay: Bool { personDetected && currentResponse != nil }
    var isReadyToCapture: Bool { currentResponse?.mainCue.contains("Chụp ngay") == true }

    func update(with response: AICoachingResponse) {
        currentResponse = response
        lastResponse = response
    }

    func updatePersonDetected(_ detected: Bool) {
        personDetected = detected
        if !detected { currentResponse = nil }
    }
}
