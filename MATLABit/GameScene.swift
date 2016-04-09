//
//  GameScene.swift
//  MATLABit
//
//  Created by Tomn on 09/04/16.
//  Copyright © 2016 Tomn. All rights reserved.
//

import SpriteKit

class GameVC : UIViewController {
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .Landscape
    }
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    private var blade: SWBlade?
    private var bladeDelta = CGPointZero

    override func didMoveToView(view: SKView) {
        backgroundColor = UIColor.blackColor()
    }
    
    override func update(currentTime: NSTimeInterval) {
        blade?.position = CGPointMake((blade?.position.x)! + bladeDelta.x, (blade?.position.y)! + bladeDelta.y)
        bladeDelta = CGPointZero
    }
    
    func showBladeAt(position: CGPoint) {
        blade = SWBlade(position: position, target: self, color: UIColor.whiteColor())
        addChild(blade!)
    }
    
    func hideBlade() {
        bladeDelta = CGPointZero
        blade?.removeFromParent()
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch = touches.first {
            let loc = touch.locationInNode(self)
            showBladeAt(loc)
            
            let viewHeight = (scene?.size.height ?? 375) / 375
            let viewWidth = (scene?.size.width ?? 667) / 667
            let direction: Int8 = arc4random_uniform(2) == 1 ? 1 : -1
            let xMult: CGFloat = CGFloat(arc4random_uniform(UInt32(60 * viewWidth))) / 10 + 0.5
            let widthMult: Double = Double(arc4random_uniform(UInt32(10 * viewWidth))) / 10 + 0.02
            let heightMult: Double = Double(arc4random_uniform(UInt32(8 * viewHeight))) / 10 + 1.15
            
            let fruit = SKSpriteNode(color: UIColor.redColor(), size: CGSize(width: 50, height: 50))
            fruit.position = CGPoint(x: (size.width / 2) - (50 * xMult * CGFloat(direction)), y: 0)
            addChild(fruit)
            
            fruit.physicsBody = SKPhysicsBody(circleOfRadius: fruit.size.width / 2)
            fruit.physicsBody?.affectedByGravity = true
            fruit.physicsBody?.velocity = CGVector(dx: 300 * widthMult * Double(direction), dy: 500 * heightMult)
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch = touches.first {
            let currentLoc = touch.locationInNode(self)
            let previousLoc = touch.previousLocationInNode(self)
            
            bladeDelta = CGPointMake(currentLoc.x - previousLoc.x, currentLoc.y - previousLoc.y)
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        hideBlade()
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        hideBlade()
    }
}

class Fruit: SKSpriteNode {
    
}
