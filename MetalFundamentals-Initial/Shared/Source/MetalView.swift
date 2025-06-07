import SwiftUI
import Metal
import MetalKit

protocol RenderDelegate : MTKViewDelegate {
    @MainActor func configure(_ view: MTKView)
}

#if !os(macOS)
struct MetalView : UIViewRepresentable {
    public typealias UIViewType = MTKView
    public var delegate: RenderDelegate?

    public init(delegate: RenderDelegate) {
        self.delegate = delegate
    }

    public func makeUIView(context: Context) -> MTKView {
        return MTKView()
    }

    public func updateUIView(_ view: MTKView, context: Context) {
        delegate?.configure(view)
    }
}
#else
struct MetalView : NSViewRepresentable {
    public typealias NSViewType = MTKView
    public var delegate: RenderDelegate?

    public init(delegate: RenderDelegate) {
        self.delegate = delegate
    }

    public func makeNSView(context: Context) -> MTKView {
        return MTKView()
    }

    public func updateNSView(_ view: MTKView, context: Context) {
        delegate?.configure(view)
    }
}
#endif
