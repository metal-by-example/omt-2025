import SwiftUI
import Metal
import MetalKit
import Spatial

extension SIMD4<Float> {
    var xyz: SIMD3<Float> {
        return SIMD3<Float>(x, y, z)
    }
}

extension simd_float3x3 {
    var adjugate: simd_float3x3 {
        return simd_float3x3(rows: [
            cross(columns.1, columns.2),
            cross(columns.2, columns.0),
            cross(columns.0, columns.1)
        ])
    }
}

extension simd_float4x4 {
    var upperLeft3x3: simd_float3x3 {
        return simd_float3x3(
            columns.0.xyz,
            columns.1.xyz,
            columns.2.xyz)
    }
}

class PerspectiveCamera {
    var position: SIMD3<Double> = [0, 0, 0]
    var orientation: simd_quatd = simd_quatd(ix: 0.0, iy: 0.0, iz: 0.0, r: 1.0)
    var fieldOfView: Angle2D = .degrees(60)
    var nearZ = 0.1
    var farZ = 100.0

    var transform: simd_float4x4 {
        let affineTransform = AffineTransform3D(rotation: Rotation3D(orientation),
                                                translation: Vector3D(vector: position))
        return simd_float4x4(affineTransform)
    }

    func viewMatrix() -> simd_float4x4 {
        let affineTransform = AffineTransform3D(rotation: Rotation3D(orientation),
                                                translation: Vector3D(vector: position))
        return simd_float4x4(affineTransform.inverse!)
    }

    func projectionMatrix(aspectRatio: Double) -> simd_float4x4 {
        let projectionTransform = ProjectiveTransform3D(fovY: fieldOfView,
                                                        aspectRatio: aspectRatio,
                                                        nearZ: nearZ,
                                                        farZ: farZ)
        return simd_float4x4(projectionTransform)
    }
}

class LitModelRenderer : NSObject, RenderDelegate {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    var pipelineState: MTLRenderPipelineState!
    var depthState: MTLDepthStencilState!
    var samplerState: MTLSamplerState!
    var entities: [ModelEntity] = []
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

        let vertexFunction = library.makeFunction(name: "lit_model_vertex")!
        let fragmentFunction = library.makeFunction(name: "lit_model_fragment")!

        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
        renderPipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        renderPipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(Model.vertexDescriptor)
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
        view.depthStencilPixelFormat = .depth32Float
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
        renderEncoder.setDepthStencilState(depthState)
        for entity in entities {
            guard let model = entity.model else { continue }
            for (index, vertexBuffer) in model.mesh.vertexBuffers.enumerated() {
                renderEncoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: index)
            }

            let aspectRatio = view.drawableSize.width / view.drawableSize.height
            var frameConstants = FrameConstants(viewMatrix: camera.viewMatrix(),
                                                projectionMatrix: camera.projectionMatrix(aspectRatio: aspectRatio),
                                                cameraPosition: simd_float3(camera.position))

            let modelMatrix = entity.transform
            var instanceConstants = InstanceConstants(modelMatrix: modelMatrix,
                                                      normalMatrix: modelMatrix.upperLeft3x3.adjugate.transpose)

            var lighting = LightingConstants()
            lighting.lights.0 = Light(direction: [-1, -1, -1], color: [1, 1, 1])
            lighting.lights.1 = Light(direction: [1, 0, 0], color: [0.05, 0.05, 0.05])
            lighting.activeLightCount = 2

            renderEncoder.setVertexBytes(&frameConstants, length: MemoryLayout<FrameConstants>.size, index: 8)
            renderEncoder.setVertexBytes(&instanceConstants, length: MemoryLayout<InstanceConstants>.size, index: 9)

            renderEncoder.setFragmentBytes(&frameConstants, length: MemoryLayout<FrameConstants>.size, index: 8)
            renderEncoder.setFragmentBytes(&lighting, length: MemoryLayout<LightingConstants>.size, index: 9)

            for (submeshIndex, submesh) in model.mesh.submeshes.enumerated() {
                let material = model.materials[submeshIndex % model.materials.count]

                renderEncoder.setFragmentTexture(material.baseColorTexture, index: 0)
                renderEncoder.setFragmentSamplerState(samplerState, index: 0)

                var materialConstants = MaterialConstants(specularColor: material.specularColor,
                                                          shininess: material.shininess,
                                                          metalness: material.metalness)
                renderEncoder.setFragmentBytes(&materialConstants, length: MemoryLayout<MaterialConstants>.size, index: 10)

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

struct LitModelView: View {
    @State var device: MTLDevice
    @State var renderer: LitModelRenderer

    init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Could not create Metal default device")
        }
        self.device = device
        self.renderer = LitModelRenderer(device: device)
    }

    var body: some View {
        MetalView(delegate: renderer)
            .ignoresSafeArea()
            .task {
                let modelURL = Bundle.main.url(forResource: "spot", withExtension: "usdz")!
                let entity = try? ModelEntity(url: modelURL, device: device)
                entity?.transform = simd_float4x4(AffineTransform3D(rotation: Rotation3D(angle: .degrees(-30), axis: .y),
                                                                    translation: Vector3D(x: 0, y: -0.5, z: 0)))
                renderer.entities.append(entity!)
            }
    }
}

#Preview {
    LitModelView()
}

@main
struct LightingApp: App {
    var body: some Scene {
        WindowGroup {
            LitModelView()
        }
    }
}
