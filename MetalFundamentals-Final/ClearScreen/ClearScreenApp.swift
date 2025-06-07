import SwiftUI
import Metal
import MetalKit

class SolidColorRenderer : NSObject, RenderDelegate {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue

    override init() {
        device = MTLCreateSystemDefaultDevice()!
        commandQueue = device.makeCommandQueue()!

        super.init()
    }

    func configure(_ view: MTKView) {
        view.device = device
        view.colorPixelFormat = .bgra8Unorm_srgb
        view.clearColor = MTLClearColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
        view.delegate = self
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }

    func draw(in view: MTKView) {
        let commandBuffer = commandQueue.makeCommandBuffer()!
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.endEncoding()
        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()
    }
}

struct ContentView: View {
    @State var renderer = SolidColorRenderer()

    var body: some View {
        MetalView(delegate: renderer)
            .ignoresSafeArea()
    }
}

@main
struct ClearScreenApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

#Preview {
    ContentView()
}
