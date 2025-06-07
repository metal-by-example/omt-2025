import SwiftUI
import Metal
import MetalKit

class TriangleRenderer : NSObject, RenderDelegate {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    var positionBuffer: MTLBuffer!
    var colorBuffer: MTLBuffer!
    var pipelineState: MTLRenderPipelineState!

    override init() {
        device = MTLCreateSystemDefaultDevice()!
        commandQueue = device.makeCommandQueue()!

        super.init()
        makeResources()
        makePipeline()
    }

    private func makeResources() {
        let positions: [SIMD2<Float>] = [
            [ 0.0,  0.5],
            [-0.8, -0.5],
            [ 0.8, -0.5],
        ]

        let colors: [SIMD3<Float>] = [
            [0.822, 0.058, 0.032],
            [0.108, 0.532, 0.111],
            [0.080, 0.383, 0.740],
        ]

        self.positionBuffer = positions.withUnsafeBytes { ptr in
            return device.makeBuffer(bytes: ptr.baseAddress!,
                                     length: MemoryLayout<SIMD2<Float>>.stride * ptr.count)
        }

        self.colorBuffer = colors.withUnsafeBytes { ptr in
            return device.makeBuffer(bytes: ptr.baseAddress!,
                                     length: MemoryLayout<SIMD3<Float>>.stride * ptr.count)
        }
    }

    private func makePipeline() {
        guard let library: MTLLibrary = device.makeDefaultLibrary() else {
            fatalError("Could not create default Metal library; make sure target contains at least one .metal file")
        }

        let vertexFunction: MTLFunction = library.makeFunction(name: "triangle_vertex")!
        let fragmentFunction = library.makeFunction(name: "triangle_fragment")!

        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        } catch {
            fatalError("Failed to make render pipeline state: \(error)")
        }
    }

    func configure(_ view: MTKView) {
        view.device = device
        view.colorPixelFormat = .bgra8Unorm_srgb
        view.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        view.delegate = self
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }

    func draw(in view: MTKView) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        let commandBuffer = commandQueue.makeCommandBuffer()!

        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        // TODO: Your code here (set the pipeline and vertex buffers and issue a draw call)
        commandEncoder.endEncoding()

        commandBuffer.present(view.currentDrawable!)

        commandBuffer.commit()
    }
}

struct ContentView: View {
    @State var renderer: RenderDelegate = TriangleRenderer()

    var body: some View {
        MetalView(delegate: renderer)
            .ignoresSafeArea()
    }
}

@main
struct HelloTriangleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

#Preview {
    ContentView()
}
