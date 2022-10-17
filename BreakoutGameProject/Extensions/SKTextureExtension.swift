//
//  SKTextureExtension.swift
//  BreakoutGameProject
//
//  Created by Yann Christophe Maertens on 01/01/2022.
//

import SpriteKit

extension SKTexture {
    // Get the name of a node texture.
    var name: String? {
        let comps = description.components(separatedBy: "'")
        return comps.count > 1 ? comps[1] : nil
    }
}
