//
//  GameViewController.swift
//  BrickBreaker
//
//  Created by Ryan Poolos on 6/19/18.
//  Copyright © 2018 PopArcade. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit

enum CollisionCategory: Int {
    case ball = 2
    case block = 4
    case floor = 8
}

extension SCNPhysicsBody {
    var collisionCategory: [CollisionCategory] {
        get {
            return []
        }
        set {
//            collisionBitMask = collisionCategory.map({$0.rawValue})
        }
    }
}

class GameViewController: UIViewController, SCNPhysicsContactDelegate {

    override func loadView() {
        self.view = SCNView()
    }

    var scnView: SCNView {
        return self.view as! SCNView
    }

    lazy var floor: SCNNode = {
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(hue: .random(in: 0...255), saturation: 0.5, brightness: 0.5, alpha: 1)

        let plane = SCNPlane(width: 20, height: 40)
        plane.materials = [material]

        let floor = SCNNode(geometry: plane)
        floor.eulerAngles.x = .pi / -2.0
        floor.physicsBody = SCNPhysicsBody.kinematic()
        floor.physicsBody?.categoryBitMask = CollisionCategory.floor.rawValue
        floor.physicsBody?.collisionBitMask = CollisionCategory.ball.rawValue | CollisionCategory.block.rawValue

        return floor
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create a new scene
        let scene = SCNScene()
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 25, z: 0)
        cameraNode.eulerAngles.x = .pi / -2.0
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)

        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // set the scene to the view
        scnView.scene = scene
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = true
        
        // configure the view
        scnView.backgroundColor = UIColor.black

        scene.rootNode.addChildNode(floor)
        scene.physicsWorld.contactDelegate = self
        
        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(gestureRecognizer:)))
        scnView.addGestureRecognizer(tapGesture)

        layoutDemoBlocks()

        let displayLink = CADisplayLink(target: self, selector: #selector(gameloop))
        displayLink.add(to: RunLoop.main, forMode: .tracking)
    }

    @objc func gameloop() {
        addBall(at: view.center)
    }

    func layoutDemoBlocks() {
        for x in 0..<8 {
            for z in 0..<4 {
                let material = SCNMaterial()
                material.diffuse.contents = UIColor(hue: .random(in: 0...255), saturation: 1, brightness: 1, alpha: 1)

                let box = SCNBox(width: 1, height: 0.5, length: 0.5, chamferRadius: 0)
                box.materials = [material]

                let node = SCNNode(geometry: box)
                node.position = SCNVector3(x * 2 - 7 + (z % 2), 0, z - 10)
                node.physicsBody = SCNPhysicsBody.dynamic()
                node.physicsBody?.mass = 100
                node.physicsBody?.categoryBitMask = CollisionCategory.block.rawValue
                node.physicsBody?.collisionBitMask = CollisionCategory.floor.rawValue | CollisionCategory.ball.rawValue

                scnView.scene?.rootNode.addChildNode(node)
            }
        }
    }
    
    @objc func handleTap(gestureRecognizer: UITapGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            let position = gestureRecognizer.location(in: scnView)

            addBall(at: position)
        }
    }

    func addBall(at point: CGPoint) {
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(hue: .random(in: 0...255), saturation: 1, brightness: 1, alpha: 1)

        let geometry = SCNSphere(radius: 0.25)
        geometry.materials = [material]

        let node = SCNNode(geometry: geometry)
        node.position = SCNVector3((point.x - view.frame.midX) / view.frame.width * 10, 0.1, 10)
        node.physicsBody = SCNPhysicsBody.dynamic()
        node.physicsBody?.restitution = 1.0
        node.physicsBody?.rollingFriction = 0.1
        node.physicsBody?.categoryBitMask = CollisionCategory.ball.rawValue
        node.physicsBody?.collisionBitMask = CollisionCategory.floor.rawValue | CollisionCategory.block.rawValue

        scnView.scene?.rootNode.addChildNode(node)

        node.physicsBody?.applyForce(SCNVector3(0, 0, -30), asImpulse: true)
    }

    func addBox(atPoint point: CGPoint) {
        let geometry = SCNBox(width: 2.0, height: 2.0, length: 2.0, chamferRadius: 0.0)

        let node = SCNNode(geometry: geometry)
        node.position = convertPoint2Dto3D(point)
        scnView.scene?.rootNode.addChildNode(node)

        node.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 1)))
    }

    func convertPoint3Dto2D(_ point: SCNVector3) -> CGPoint {
        let projectedPoint = scnView.projectPoint(point)

        return CGPoint(x: Double(projectedPoint.x), y: Double(projectedPoint.y))
    }

    func convertPoint2Dto3D(_ point: CGPoint) -> SCNVector3 {
        // The zeropoint for the z isn't actually even, so grab our origin.
        let projectedOrigin = scnView.projectPoint(SCNVector3Zero)

        // Convert to 3D with our x/y plus the origin z
        let touchPoint = SCNVector3(x: Float(point.x), y: Float(point.y), z: projectedOrigin.z)

        // unproject it to 3D space
        let convertedPoint = scnView.unprojectPoint(touchPoint)

        return convertedPoint
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    //==========================================================================
    // MARK: - SCNPhysicsContactDelegate
    //==========================================================================

    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        // TODO: Show Explosion Particle or something
    }

    func physicsWorld(_ world: SCNPhysicsWorld, didEnd contact: SCNPhysicsContact) {
        func handle(node: SCNNode) {
            print(node)

            guard let category = CollisionCategory(rawValue: node.categoryBitMask) else {
                return
            }

            // TODO: Remove Block or Reduce Health
            if category == .block {
                node.removeFromParentNode()
            }
        }

        handle(node: contact.nodeA)
        handle(node: contact.nodeB)
    }
}
