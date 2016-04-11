//
//  Tab.swift
//  MATLABit
//
//  Created by Tomn on 11/04/16.
//  Copyright © 2016 Tomn. All rights reserved.
//

import UIKit

class Tab: UITabBarController, UITabBarControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
    }
    
    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        if tabBarController.viewControllers?.indexOf(viewController) == 3 {
            if let url = Data.sharedData.fbURL {
                UIApplication.sharedApplication().openURL(url)
            }
            return false
        }
        return true
    }
}
