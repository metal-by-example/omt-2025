import ModelIO

// Extensions to work around Model I/O -> Swift rough edges

extension MDLVertexDescriptor {
    var vertexAttributes: [MDLVertexAttribute] {
        return attributes as! [MDLVertexAttribute]
    }

    var bufferLayouts: [MDLVertexBufferLayout] {
        return layouts as! [MDLVertexBufferLayout]
    }
}

extension MDLMesh {
    var submeshArray: [MDLSubmesh] {
        return submeshes as! [MDLSubmesh]
    }
}

// Slightly Swiftier child object access
extension MDLAsset {
    struct ChildObjectProxy {
        let asset: MDLAsset
        subscript<T>(componentType: T.Type) -> [T] where T : MDLObject  {
            return asset.childObjects(of: T.self) as? [T] ?? []
        }
    }

    var childObjects: ChildObjectProxy {
        return ChildObjectProxy(asset: self)
    }
}
