import Flutter
import UIKit
import SwiftUI

class NativeObjectDetectionViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return NativeObjectDetectionView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger)
    }
}

class NativeObjectDetectionView: NSObject, FlutterPlatformView {
    private var _view: UIView
    private var hostingController: UIHostingController<ObjectDetectionViewWrapper>?

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        _view = UIView(frame: frame)
        super.init()
        createNativeView(view: _view)
    }

    func view() -> UIView {
        return _view
    }

    func createNativeView(view _view: UIView) {
        let swiftUIView = ObjectDetectionViewWrapper()
        
        hostingController = UIHostingController(rootView: swiftUIView)
        guard let hostingView = hostingController?.view else { return }
        
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        _view.addSubview(hostingView)
        
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: _view.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: _view.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: _view.trailingAnchor)
        ])
    }
}

struct ObjectDetectionViewWrapper: View {
    @StateObject private var viewModel = CameraViewModel()
    @State private var mode: ContentView.Mode = .objectDetection
    @State private var showSettings: Bool = false
    @StateObject private var debouncer = ButtonPressDebouncer()

    var body: some View {
        ObjectDetectionView(
            viewModel: viewModel,
            mode: $mode,
            showSettings: $showSettings,
            orientation: UIDevice.current.orientation,
            isPortrait: UIDevice.current.orientation.isPortrait,
            rotationAngle: .zero,
            onBack: {
                // Not needed in Flutter wrapper, back handled by Flutter usually
            },
            buttonDebouncer: debouncer
        )
    }
}
