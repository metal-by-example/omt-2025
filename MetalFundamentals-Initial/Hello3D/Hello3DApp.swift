import SwiftUI
import Metal
import MetalKit
import Spatial

struct FrameConstants {
    var viewMatrix: simd_float4x4
    var projectionMatrix: simd_float4x4
}

struct InstanceConstants {
    var modelMatrix: simd_float4x4
}

class PerspectiveCamera {
    var scaleFactors: SIMD3<Double> = [1, 1, 1]
    var position: SIMD3<Double> = [0, 0, 0]
    var orientation: simd_quatd = simd_quatd(ix: 0.0, iy: 0.0, iz: 0.0, r: 1.0)
    var fieldOfView: Angle2D = .degrees(60)
    var nearZ = 0.1
    var farZ = 100.0

    var transform: simd_float4x4 {
        let affineTransform = AffineTransform3D(scale: Size3D(vector: scaleFactors),
                                                rotation: Rotation3D(orientation),
                                                translation: Vector3D(vector: position))
        return simd_float4x4(affineTransform)
    }

    func viewMatrix() -> simd_float4x4 {
        return transform.inverse
    }

    func projectionMatrix(aspectRatio: Double) -> simd_float4x4 {
        let projectionTransform = ProjectiveTransform3D(fovY: fieldOfView,
                                                        aspectRatio: aspectRatio,
                                                        nearZ: nearZ,
                                                        farZ: farZ)
        return simd_float4x4(projectionTransform)
    }
}

class BasicModelRenderer : NSObject, RenderDelegate {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    var pipelineState: MTLRenderPipelineState!
    var depthState: MTLDepthStencilState!
    var samplerState: MTLSamplerState!
    var model: BasicModel!
    var camera = PerspectiveCamera()

    init(device: MTLDevice) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()!

        super.init()
        makePipeline()

        camera.position = [0, 0, 1.75]
    }

    private func makePipeline() {
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Could not create default Metal library; make sure target contains at least one .metal file")
        }

        let vertexFunction = library.makeFunction(name: "basic_model_vertex")!
        let fragmentFunction = library.makeFunction(name: "basic_model_fragment")!

        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
        // TODO: Your code, Part 3 (Set a valid depth format)
        renderPipelineDescriptor.depthAttachmentPixelFormat = .invalid
        renderPipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(BasicModel.vertexDescriptor)
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        } catch {
            fatalError("Failed to make render pipeline state: \(error)")
        }

        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.isDepthWriteEnabled = true
        depthDescriptor.depthCompareFunction = .less
        depthState = device.makeDepthStencilState(descriptor: depthDescriptor)

        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .linear
        samplerDescriptor.sAddressMode = .repeat
        samplerDescriptor.tAddressMode = .repeat
        samplerState = device.makeSamplerState(descriptor: samplerDescriptor)
    }

    func configure(_ view: MTKView) {
        view.device = device
        view.colorPixelFormat = .bgra8Unorm_srgb
        // TODO: Your code, Part 3 (Set a valid depth format)
        view.depthStencilPixelFormat = .invalid
        view.clearColor = MTLClearColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
        view.delegate = self
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }

    func draw(in view: MTKView) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        let commandBuffer = commandQueue.makeCommandBuffer()!

        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.setRenderPipelineState(pipelineState)

        // TODO: Your code, Part 3 (Bind the depth state)

        if let model {
            for (index, vertexBuffer) in model.mesh.vertexBuffers.enumerated() {
                renderEncoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: index)
            }

            let aspectRatio = view.drawableSize.width / view.drawableSize.height
            var frameConstants = FrameConstants(viewMatrix: camera.viewMatrix(),
                                                projectionMatrix: camera.projectionMatrix(aspectRatio: aspectRatio))
            var instanceConstants = InstanceConstants(modelMatrix: model.modelMatrix)

            // TODO: Your code, step 1 (Bind constants: frame constants at index 8; instance constants at index 9)

            for (submeshIndex, submesh) in model.mesh.submeshes.enumerated() {
                let material = model.materials[submeshIndex % model.materials.count]

                // TODO: Your code, step 2 (Bind a base color texture and sampler)

                renderEncoder.drawIndexedPrimitives(type: submesh.primitiveType,
                                                    indexCount: submesh.indexCount,
                                                    indexType: submesh.indexType,
                                                    indexBuffer: submesh.indexBuffer.buffer,
                                                    indexBufferOffset: submesh.indexBuffer.offset)
            }
        }
        renderEncoder.endEncoding()

        commandBuffer.present(view.currentDrawable!)

        commandBuffer.commit()
    }
}

struct BasicModelView: View {
    @State var device: MTLDevice
    @State var renderer: BasicModelRenderer

    init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Could not create Metal default device")
        }
        self.device = device
        self.renderer = BasicModelRenderer(device: device)
    }

    var body: some View {
        MetalView(delegate: renderer)
            .ignoresSafeArea()
            .task {
                let modelURL = Bundle.main.url(forResource: "spot", withExtension: "usdz")!
                let model = try? BasicModel(url: modelURL, device: device)
                model?.modelMatrix = simd_float4x4(AffineTransform3D(rotation: Rotation3D(angle: .degrees(-30), axis: .y),
                                                                        translation: Vector3D(x: 0, y: -0.5, z: 0)))
                renderer.model = model
            }
    }
}

#Preview {
    BasicModelView()
}

@main
struct Hello3DApp: App {
    var body: some Scene {
        WindowGroup {
            BasicModelView()
        }
    }
}
