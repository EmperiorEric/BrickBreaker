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
        node.physicsBody = SCNPhysicsBody.kinematic()
        node.physicsBody?.categoryMask = .world
        node.physicsBody?.collisionMask = [.structure, .target, .projectile]

        return node
    }()

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

    @objc func gameloop() {

    }

    var boxNode: SCNNode!
    func setupGame() {
        layoutDemoBlocks()
    }

    var score: Int = 0 {
        didSet {
            print("Score: \(score)")
            if score >= 3 {
                scnView.scene?.rootNode.childNodes.forEach {
                    guard $0 != floor else {
                        return
                    }
                    $0.removeFromParentNode()
                }
                gameOver()
            }
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

    func moveBoxToPoint(position: CGPoint) {
        let projectedOrigin = scnView.projectPoint(SCNVector3Zero)
        let unprojectedOrigin = scnView.unprojectPoint(SCNVector3Zero)
        print("projectedOrigin: \(projectedOrigin)")
        print("unprojectedOrigin: \(unprojectedOrigin)")

//        let box3DPosition = boxNode.position
//        let box2DPosition = scnView.projectPoint(box3DPosition)

        // 0.3 is 0 - 1 for the clipping plane. 0 being on the near and 1 being
        // on the far. Really we need to figure out where 0 y is on the clipping
        // plane...

        var newBox3DPosition = scnView.unprojectPoint(SCNVector3(position.x, position.y, 1))
//        newBox3DPosition.y = 0

        //            print("box3DPosition: \(box3DPosition)")
        //            print("box2DPosition: \(box2DPosition)")

        print("newBox3DPosition: \(newBox3DPosition)")

        boxNode.position = newBox3DPosition
    }
    
    @objc func handleTap(gestureRecognizer: UITapGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            let position = gestureRecognizer.location(in: scnView)

            addBall(at: position)
        }
    }

    @objc func handlePan(gesture: UIPanGestureRecognizer) {
        if gesture.state == .changed {
            let position = gesture.location(in: scnView)

            addBall(at: position)
//            moveBoxToPoint(position: position)
        }
    }

    func addBall(at point: CGPoint) {
        let node = BallNode()
        node.position = scnView.unprojectPoint(SCNVector3(point.x, point.y, 1))

        scnView.scene?.rootNode.addChildNode(node)

        node.physicsBody?.applyForce(SCNVector3(0, 0, -30), asImpulse: true)
    }

    func addBox(atPoint point: CGPoint) {
        let geometry = SCNBox(width: 2.0, height: 2.0, length: 2.0, chamferRadius: 0.0)

        let node = SCNNode(geometry: geometry)
        node.position = convertPoint2Dto3D(point)
        node.position.y = 1
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

        print(projectedOrigin)

        // Convert to 3D with our x/y plus the origin z
        let touchPoint = SCNVector3(x: Float(point.x), y: projectedOrigin.y, z: Float(point.y))

        print(touchPoint)

        // unproject it to 3D space
        var convertedPoint = scnView.unprojectPoint(touchPoint)
        convertedPoint.y = projectedOrigin.y

        print(convertedPoint)

        return convertedPoint
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
                else {
                    node.removeFromParentNode()
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
