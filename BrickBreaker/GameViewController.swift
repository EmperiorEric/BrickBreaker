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
import GLKit

class GameViewController: UIViewController, SCNPhysicsContactDelegate {

    override func loadView() {
        self.view = SCNView()
    }

    var scnView: SCNView {
        return self.view as! SCNView
    }

    lazy var floor: SCNNode = {
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.green

        let plane = SCNPlane(width: 20, height: 40)
        plane.materials = [material]

        let node = SCNNode(geometry: plane)
        node.eulerAngles.x = .pi / -2.0
        node.physicsBody = SCNPhysicsBody.static()
        node.physicsBody?.categoryMask = .world
        node.physicsBody?.collisionMask = [.structure, .target, .projectile]

        return node
    }()

    func createWall() -> SCNNode {
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.blue

        let plane = SCNPlane(width: 100, height: 100)
        plane.materials = [material]

        let node = SCNNode(geometry: plane)
        node.physicsBody = SCNPhysicsBody.static()
        node.physicsBody?.categoryMask = .world
        node.physicsBody?.collisionMask = [.structure, .target, .projectile]
        node.physicsBody?.restitution = 1.5

        return node
    }

    var displayLink: CADisplayLink?

    let cameraNode = SCNNode()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create a new scene
        let scene = SCNScene()
        
        // create and add a camera to the scene
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zFar = 25
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
//        scnView.allowsCameraControl = true

        // show statistics such as fps and timing information
        scnView.showsStatistics = true
        scnView.debugOptions = [.showPhysicsShapes]
        
        // configure the view
        scnView.backgroundColor = UIColor.black

        scene.rootNode.addChildNode(floor)
        scene.physicsWorld.contactDelegate = self

        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(gestureRecognizer:)))
        scnView.addGestureRecognizer(tapGesture)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(gesture:)))
        scnView.addGestureRecognizer(panGesture)

        displayLink = CADisplayLink(target: self, selector: #selector(gameloop))
        displayLink?.add(to: RunLoop.current, forMode: .default)

        setupGame()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        setupWalls()
    }

    @objc func gameloop() {
        panLocations.forEach { addBall(at: $0) }
    }

    var boxNode: SCNNode!
    func setupGame() {
        layoutDemoBlocks()
    }

    var score: Int = 0 {
        didSet {
            print("Score: \(score)")
            if score >= 3 {
                reset()
                gameOver()
            }
        }
    }

    func reset() {
        scnView.scene?.rootNode.childNodes.forEach {
            guard $0 != floor else {
                return
            }
            $0.removeFromParentNode()
        }
    }

    func layoutDemoBlocks() {
        // Create the Castle we need to destroy
        let castle = CastleNode()
        castle.position = SCNVector3(0, 0, -12)
        scnView.scene?.rootNode.addChildNode(castle)

        // Layout barrier blocks
        for z in 1...4 {
            let rowCount = 7 - (z % 2)
            for x in 1..<rowCount {
                let material = SCNMaterial()
                material.diffuse.contents = UIColor(hue: .random(in: 0...255), saturation: 1, brightness: 1, alpha: 1)

                let box = SCNBox(width: 1, height: 0.5, length: 0.5, chamferRadius: 0)
                box.materials = [material]

                let node = SCNNode(geometry: box)
                node.position = SCNVector3(x * 2 - 7 + (z % 2), 0, z - 12)
                node.physicsBody = SCNPhysicsBody.dynamic()
                node.physicsBody?.mass = 100
                node.physicsBody?.categoryMask = .structure
                node.physicsBody?.collisionMask = [.world, .projectile]
                node.physicsBody?.contactTestMask = .projectile

                scnView.scene?.rootNode.addChildNode(node)
            }
        }
    }

    func setupWalls() {
        let topWall = createWall()
        scnView.scene?.rootNode.addChildNode(topWall)
        topWall.position = scnView.unprojectPoint(SCNVector3(view.bounds.midX, view.bounds.minY, 0.9999))

        let leftWall = createWall()
        scnView.scene?.rootNode.addChildNode(leftWall)
        leftWall.position = scnView.unprojectPoint(SCNVector3(view.bounds.minX, view.bounds.midY, 0.9999))
        leftWall.runAction(SCNAction.rotateBy(x: 0, y: .pi / 2, z: 0, duration: 0.1))

        let rightWall = createWall()
        scnView.scene?.rootNode.addChildNode(rightWall)
        rightWall.position = scnView.unprojectPoint(SCNVector3(view.bounds.maxX, view.bounds.midY, 0.9999))
        rightWall.runAction(SCNAction.rotateBy(x: 0, y: .pi / -2, z: 0, duration: 0.1))

        let bottomWall = createWall()
        scnView.scene?.rootNode.addChildNode(bottomWall)
        bottomWall.position = scnView.unprojectPoint(SCNVector3(view.bounds.midX, view.bounds.maxY, 0.9999))
    }
    
    @objc func handleTap(gestureRecognizer: UITapGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            let position = gestureRecognizer.location(in: scnView)

            addBall(at: position)
        }
    }

    var panLocations: [CGPoint] = []
    @objc func handlePan(gesture: UIPanGestureRecognizer) {
        panLocations = (0..<gesture.numberOfTouches).map({ touch -> CGPoint in
            return gesture.location(ofTouch: touch, in: scnView)
        })

        if gesture.state == .ended || gesture.state == .cancelled {
            panLocations = []
        }
    }

    func addBall(at point: CGPoint) {
        let node = BallNode()
        node.position = scnView.unprojectPoint(SCNVector3(point.x, point.y, 0.9999))

        scnView.scene?.rootNode.addChildNode(node)

        node.physicsBody?.applyForce(SCNVector3(0, 0, -30), asImpulse: true)
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }

    //==========================================================================
    // MARK: - SCNPhysicsContactDelegate
    //==========================================================================

    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        func handle(node: SCNNode) {
            guard let categoryMask = node.physicsBody?.categoryMask else {
                return
            }

            if categoryMask.isDestructible {
                // TODO: Show something like an explosion
                if var destructible = node as? Destructible {
                    destructible.health -= 1
                    if destructible.health <= 0 {
                        node.removeFromParentNode()
                    }
                }
            }

            if categoryMask.isScorable {
                score += 1
            }
        }

        handle(node: contact.nodeA)
        handle(node: contact.nodeB)
    }

    func gameOver() {
        score = 0
        print("You Win!")
        layoutDemoBlocks()
    }
}
