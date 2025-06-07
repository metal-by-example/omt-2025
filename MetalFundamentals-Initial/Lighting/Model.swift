import Foundation
import Metal
import MetalKit
import ModelIO

class Material {
    var baseColorTexture: MTLTexture?
    var specularColor: simd_float3 = [1, 1, 1]
    var shininess: Float = 50.0
    var metalness: Float = 0.0
}

class Model {
    var mesh: MTKMesh
    var materials: [Material]

    init(mesh: MTKMesh, materials: [Material]) {
        self.mesh = mesh
        self.materials = materials
    }
}

extension Model {
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
