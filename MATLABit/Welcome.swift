//
//  Welcome.swift
//  MATLABit
//
//  Created by Tomn on 08/04/16.
//  Copyright © 2016 Tomn. All rights reserved.
//

import UIKit
import SpriteKit

class Welcome: UIViewController {
    
    @IBOutlet weak var content: UIView!
    @IBOutlet weak var logo: Logo!
    private var animator: UIDynamicAnimator!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        logo.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(bounce)))
        animator = UIDynamicAnimator(referenceView: content)
    }
    
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
        
        let vc = GameVC()
        let gameView = SKView()
        gameView.showsFPS = true;
        gameView.showsNodeCount = true
        gameView.ignoresSiblingOrder = true
        vc.view = gameView
        presentViewController(vc, animated: true, completion: nil)
        
        let scene = GameScene(size: UIScreen.mainScreen().bounds.size)
        scene.scaleMode = .AspectFill
        gameView.presentScene(scene)
	}
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        animator.removeAllBehaviors()
    }
    
    func bounce() {
        animator.removeAllBehaviors()
        
        let collisionBehavior = UICollisionBehavior(items: [logo])
        collisionBehavior.translatesReferenceBoundsIntoBoundary = true;
        animator.addBehavior(collisionBehavior)
        
        if !logo.hasFallen {
            logo.hasFallen = true
            
            let gravityBehavior = UIGravityBehavior(items: [logo])
            gravityBehavior.magnitude = 5
            animator.addBehavior(gravityBehavior)
            
            let elasticityBehavior = UIDynamicItemBehavior(items: [logo])
            elasticityBehavior.elasticity = 0.8;
            animator.addBehavior(elasticityBehavior)
        } else {
            let pusher = UIPushBehavior(items: [logo], mode: .Instantaneous)
            pusher.pushDirection = CGVectorMake(50, 40)
            pusher.active = true
            animator.addBehavior(pusher)
            
            let paddle = UIDynamicItemBehavior(items: [logo])
            paddle.elasticity = 0.8
            animator.addBehavior(paddle)
        }
    }
}

class Logo: UIImageView {
    private var hasFallen = false
    
    @available(iOS 9.0, *)
    override var collisionBoundsType: UIDynamicItemCollisionBoundsType {
        return (hasFallen) ? .Ellipse : .Rectangle
    }
}