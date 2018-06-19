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

class GameViewController: UIViewController {

    override func loadView() {
        self.view = SCNView()
    }

    var scnView: SCNView {
        return self.view as! SCNView
    }

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

        let material = SCNMaterial()
        material.diffuse.contents = UIColor(hue: .random(in: 0...255), saturation: 1, brightness: 1, alpha: 1)

        let plane = SCNPlane(width: 100, height: 100)
        plane.materials = [material]

        let floor = SCNNode(geometry: plane)
//        floor.physicsBody = SCNPhysicsBody.kinematic()
        scene.rootNode.addChildNode(floor)
        
        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)

        layoutDemoBlocks()
    }

    func layoutDemoBlocks() {
        for x in 0..<8 {
            for z in 0..<4 {
                let material = SCNMaterial()
                material.diffuse.contents = UIColor(hue: .random(in: 0...255), saturation: 1, brightness: 1, alpha: 1)

                let box = SCNBox(width: 1, height: 0.5, length: 0.5, chamferRadius: 0)
                box.materials = [material]

                let node = SCNNode(geometry: box)
                node.position = SCNVector3(x * 2 - 7, 1, z - 10)
                node.physicsBody = SCNPhysicsBody.dynamic()

                scnView.scene?.rootNode.addChildNode(node)
            }
        }
    }
    
    @objc func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // check what nodes are tapped
        let p = gestureRecognize.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [:])
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result = hitResults[0]
            
            // get its material
            let material = result.node.geometry!.firstMaterial!
            
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            // on completion - unhighlight
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                
                material.emission.contents = UIColor.black
                
                SCNTransaction.commit()
            }
            
            material.emission.contents = UIColor.red
            
            SCNTransaction.commit()
        }
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

}
