//
//  CastleNode.swift
//  BrickBreaker
//
//  Created by Ryan Poolos on 9/25/18.
//  Copyright © 2018 PopArcade. All rights reserved.
//

import SceneKit

class CastleNode: SCNNode, Destructible {

    var health: Int = 3 {
        didSet {
            let material = SCNMaterial()
            switch health {
            case 1:
                material.diffuse.contents = UIColor.red
            case 2:
                material.diffuse.contents = UIColor.orange
            default:
                material.diffuse.contents = UIColor.yellow
            }
            geometry?.materials = [material]
        }
    }

    override init() {
        super.init()

        let material = SCNMaterial()
        material.diffuse.contents = UIColor.yellow

        let box = SCNBox(width: 2, height: 2, length: 1, chamferRadius: 0.2)
        box.materials = [material]

        geometry = box

        physicsBody = SCNPhysicsBody.dynamic()
        physicsBody?.mass = 100
        physicsBody?.categoryMask = .target
        physicsBody?.collisionMask = [.world, .structure]
        physicsBody?.contactTestMask = .projectile
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Storyboards Ugh")
    }

}
