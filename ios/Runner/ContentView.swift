import SwiftUI

struct ContentView {
    enum Mode {
        case home
        case liveOCR
        case objectDetection
    }
    
    enum AnimationState {
        case idle
        case scanning
        case complete
    }
}
