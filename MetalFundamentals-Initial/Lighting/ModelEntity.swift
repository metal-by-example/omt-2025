import simd
import Metal
import MetalKit
import ModelIO

class ModelEntity {
    var transform: simd_float4x4 = matrix_identity_float4x4
    var model: Model?
}

extension ModelEntity {
    enum Error : Swift.Error {
        case assetContainsNoMeshes
    }

    convenience init(url: URL, device: MTLDevice) throws {
        let textureLoader = MTKTextureLoader(device: device)
        let bufferAllocator = MTKMeshBufferAllocator(device: device)

        let asset = MDLAsset(url: url,
                             vertexDescriptor: Model.vertexDescriptor,
                             bufferAllocator: bufferAllocator)
        asset.loadTextures()

        let mdlMeshes = asset.childObjects[MDLMesh.self]
        guard let mdlMesh = mdlMeshes.first else { throw Error.assetContainsNoMeshes }

        let materials = try mdlMesh.submeshArray.map { mdlSubmesh in
            let material = Material()
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

        self.init()
        self.model = Model(mesh: mtkMesh, materials: materials)
        self.transform = MDLTransform.globalTransform(with: mdlMesh, atTime: 0.0)
    }
}
