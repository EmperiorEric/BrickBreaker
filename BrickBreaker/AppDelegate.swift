//
//  AppDelegate.swift
//  BrickBreaker
//
//  Created by Ryan Poolos on 6/19/18.
//  Copyright © 2018 PopArcade. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .black
        window?.rootViewController = GameViewController()
        window?.makeKeyAndVisible()

        return true
    }

}

