import Foundation
import Metal
import MetalKit
import ModelIO

class BasicMaterial {
    var baseColorTexture: MTLTexture?
}

class BasicModel {
    var mesh: MTKMesh
    var materials: [BasicMaterial]
    var modelMatrix: simd_float4x4 = matrix_identity_float4x4

    init(mesh: MTKMesh, materials: [BasicMaterial]) {
        self.mesh = mesh
        self.materials = materials
    }
}

extension BasicModel {
    static var vertexDescriptor: MDLVertexDescriptor {
        let vertexDescriptor = MDLVertexDescriptor()
        vertexDescriptor.vertexAttributes[0].name = MDLVertexAttributePosition
        vertexDescriptor.vertexAttributes[0].format = .float3
        vertexDescriptor.vertexAttributes[0].offset = 0
        vertexDescriptor.vertexAttributes[0].bufferIndex = 0

        vertexDescriptor.vertexAttributes[1].name = MDLVertexAttributeNormal
        vertexDescriptor.vertexAttributes[1].format = .float3
        vertexDescriptor.vertexAttributes[1].offset = MemoryLayout<Float>.size * 3
        vertexDescriptor.vertexAttributes[1].bufferIndex = 0

        vertexDescriptor.vertexAttributes[2].name = MDLVertexAttributeTextureCoordinate
        vertexDescriptor.vertexAttributes[2].format = .float2
        vertexDescriptor.vertexAttributes[2].offset = MemoryLayout<Float>.size * 6
        vertexDescriptor.vertexAttributes[2].bufferIndex = 0

        vertexDescriptor.bufferLayouts[0].stride = MemoryLayout<Float>.size * 8

        return vertexDescriptor
    }
}

extension BasicModel {
    enum Error : Swift.Error {
        case assetContainsNoMeshes
    }

    convenience init(url: URL, device: MTLDevice) throws {
        let textureLoader = MTKTextureLoader(device: device)
        let bufferAllocator = MTKMeshBufferAllocator(device: device)

        let asset = MDLAsset(url: url,
                             vertexDescriptor: BasicModel.vertexDescriptor,
                             bufferAllocator: bufferAllocator)
        asset.loadTextures()

        let mdlMeshes = asset.childObjects[MDLMesh.self]
        guard let mdlMesh = mdlMeshes.first else { throw Error.assetContainsNoMeshes }

        let materials = try mdlMesh.submeshArray.map { mdlSubmesh in
            let material = BasicMaterial()
            let options: [MTKTextureLoader.Option : Any] = [
                .generateMipmaps : true,
                .textureStorageMode : MTLStorageMode.private.rawValue
            ]
            if let mdlMaterial = mdlSubmesh.material,
               let baseColorProperty = mdlMaterial.property(with: .baseColor),
               let mdlSampler = baseColorProperty.textureSamplerValue,
               let mdlTexture = mdlSampler.texture
            {
                let texture = try textureLoader.newTexture(texture: mdlTexture, options: options)
                // Model I/O loses color space information when loading images,
                // so we reinterpret texture contents with an sRGB texture view
                material.baseColorTexture = texture.makeTextureView(pixelFormat: .rgba8Unorm_srgb)
            }
            return material
        }

        let mtkMesh = try MTKMesh(mesh: mdlMesh, device: device)

        self.init(mesh: mtkMesh, materials: materials)
    }
}
