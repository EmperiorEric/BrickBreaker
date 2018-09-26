//
//  CollisionMasks.swift
//  BrickBreaker
//
//  Created by Ryan Poolos on 9/25/18.
//  Copyright © 2018 PopArcade. All rights reserved.
//

import SceneKit

struct Mask: OptionSet {
    let rawValue: Int

    /// Used for world objects like floor or walls
    static let world = Mask(rawValue: 1 << 0)

    /// Used for game point objects like central bases
    static let target = Mask(rawValue: 1 << 1)

    /// Used for projectiles like bullets or missles
    static let projectile = Mask(rawValue: 1 << 2)

    /// Used for defensive structures like blocks
    static let structure = Mask(rawValue: 1 << 3)

    static let indestructible: Mask = .world
    var isIndestructible: Bool {
        return Mask.indestructible.contains(self)
    }

    static let destructible: Mask = [.target, .projectile, .structure]
    var isDestructible: Bool {
        return Mask.destructible.contains(self)
    }

    static let scoreable: Mask = .target
    var isScorable: Bool {
        return Mask.scoreable.contains(self)
    }
}

extension SCNPhysicsBody {
    var categoryMask: Mask {
        get {
            return Mask(rawValue: categoryBitMask)
        }
        set {
            categoryBitMask = newValue.rawValue
        }
    }

    var collisionMask: Mask {
        get {
            return Mask(rawValue: collisionBitMask)
        }
        set {
            collisionBitMask = newValue.rawValue
        }
    }

    var contactTestMask: Mask {
        get {
            return Mask(rawValue: contactTestBitMask)
        }
        set {
            contactTestBitMask = newValue.rawValue
        }
    }
}
