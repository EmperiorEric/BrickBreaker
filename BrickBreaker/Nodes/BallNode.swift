//
//  BallNode.swift
//  BrickBreaker
//
//  Created by Ryan Poolos on 9/25/18.
//  Copyright © 2018 PopArcade. All rights reserved.
//

import SceneKit

class BallNode: SCNNode {

    override init() {
        super.init()

        let material = SCNMaterial()
        material.diffuse.contents = UIColor(hue: .random(in: 0...255), saturation: 1, brightness: 1, alpha: 1)

        let geometry = SCNSphere(radius: 0.25)
        geometry.materials = [material]

        self.geometry = geometry

        physicsBody = SCNPhysicsBody.dynamic()
        physicsBody?.restitution = 1.0
        physicsBody?.rollingFriction = 0.1
        physicsBody?.categoryMask = .projectile
        physicsBody?.collisionMask = [.world, .destructible]
        physicsBody?.contactTestMask = .destructible
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Storyboards Ugh")
    }
}
