//
//  GameScene.swift
//  MATLABit
//
//  Created by Tomn on 09/04/16.
//  Copyright © 2016 Tomn. All rights reserved.
//

import SpriteKit

class GameVC : UIViewController {
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let gameView = self.view as! SKView
        if gameView.scene == nil {
            let scene = GameScene(size: CGSizeMake(max(gameView.bounds.size.height,gameView.bounds.size.width), min(gameView.bounds.size.height,gameView.bounds.size.width)))
            scene.scaleMode = .AspectFill
            gameView.presentScene(scene)
        }
    }
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .Landscape
    }
}

enum CollisionType: UInt32 {
    case NoType = 0
    case Blade = 1
    case Flying = 2
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    private let startDelay = 2.0
    private let startLives = 3
    private let livesMax = 5
    private let difficultéMax = 3.5
    private let bladeMaxTouchTime: NSTimeInterval = 2
    
    private var blade: SWBlade?
    private var bladeDelta = CGPointZero
    private let scoreHUD = SKLabelNode(fontNamed: "Gang of Three")
    private var livesHUD = Array<SKSpriteNode>()
    
    private var score = 0
    private var lives = 3
    private var timeStart: NSTimeInterval = 0
    private var timeStartTouch: NSTimeInterval = 0
    private var timeLastFruit: NSTimeInterval = 0
    
    private var contactQueue = Array<SKPhysicsContact>()

    override func didMoveToView(view: SKView) {
        backgroundColor = UIColor.blackColor()
        
        let back = SKSpriteNode(imageNamed:"backFruit")
        back.zPosition = -1
        back.size = size
        back.position = CGPoint(x: CGRectGetMidX(frame), y: CGRectGetMidY(frame))
        addChild(back)
        
        updateScore(0)
        scoreHUD.zPosition = 1
        scoreHUD.fontSize = 42
        scoreHUD.fontColor = UIColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 1.0 )
        scoreHUD.position = CGPoint(x: 15, y: size.height - scoreHUD.frame.size.height - 12)
        scoreHUD.horizontalAlignmentMode = .Left
        addChild(scoreHUD)
        
        let posX = size.width - 25
        let posY = size.height - 30
        for i in 0 ..< livesMax {
            let life = SKSpriteNode(imageNamed: "can")
            life.position = CGPoint(x: posX - (30 * CGFloat(i)), y: posY)
            addChild(life)
            livesHUD.append(life)
        }
        lives = startLives
        updateLives(0)
        
        physicsWorld.contactDelegate = self
    }

    
    // MARK: Update Events
    
    override func update(currentTime: NSTimeInterval) {
        blade?.position = CGPoint(x: (blade?.position.x)! + bladeDelta.x, y: (blade?.position.y)! + bladeDelta.y)
        bladeDelta = CGPointZero
        
        if timeStart == 0 {
            timeStart = currentTime
            return
        } else if currentTime - timeStart < startDelay {
            return
        }
        
        processContactForUpdate(currentTime)
        
        let difficulté = Double(arc4random_uniform(UInt32(difficultéMax)))
        let timeLimit = 0.35 + (Double(arc4random_uniform(100)) * (difficultéMax - difficulté))
        if currentTime - timeLastFruit > timeLimit {
            timeLastFruit = currentTime
            
            let randAppear = arc4random_uniform(200)
            if randAppear == 0 {
                showBonus()
            } else if randAppear < 10 {
                showBomb()
            } else {
                showFruit()
            }
        }
        
        enumerateChildNodesWithName("fruit") { (fruit, stop) in
            if fruit.position.y < 0 {
                fruit.removeFromParent()
                self.updateLives(-1)
            }
        }
    }
    
    func updateScore(by: Int) {
        score += by
        if score < 0 {
            score = 0
        }
        scoreHUD.text = String(score)
    }
    
    func updateLives(by: Int) {
        if lives + by > livesMax {
            return
        }
        
        lives += by
        
        if lives < 0 {
            gameOver()
            return
        }
        
        livesHUD.forEach({ (lifeHUD) in
            lifeHUD.alpha = 0.0
        })
        for i in 0 ..< lives {
            livesHUD[i].alpha = 1.0
        }
    }
    
    func gameOver() {
        paused = false
        
        scoreHUD.runAction(SKAction.group([SKAction.moveTo(CGPoint(x: CGRectGetMidX(frame), y: CGRectGetMidY(frame) - 30), duration: 1),
                           SKAction.scaleBy(2.0, duration: 1)]))
    }
    
    func showFruit() {
        addChild(Fruit(scene: self))
    }
    
    func showBomb() {
        addChild(Bomb(scene: self))
    }
    
    func showBonus() {
        addChild(Bonus(scene: self))
    }
    
    
    // MARK: - Touch Events
    
    func showBladeAt(position: CGPoint) {
        blade = SWBlade(position: position, target: self, color: UIColor.whiteColor())
        addChild(blade!)
        blade!.enablePhysics(CollisionType.Blade.rawValue,
                             contactTestBitmask: CollisionType.NoType.rawValue,
                             collisionBitmask: CollisionType.NoType.rawValue)
    }
    
    func hideBlade() {
        bladeDelta = CGPointZero
        
        blade?.runAction(SKAction.sequence([SKAction.fadeOutWithDuration(0.25), SKAction.removeFromParent()]))
        blade?.emitter.removeFromParent()
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if !paused,
            let touch = touches.first {
            let loc = touch.locationInNode(self)
            timeStartTouch = NSDate.timeIntervalSinceReferenceDate()
            showBladeAt(loc)
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch = touches.first {
            if NSDate.timeIntervalSinceReferenceDate() - timeStartTouch > bladeMaxTouchTime {
                timeStartTouch = 0
                hideBlade()
                return
            }
            let currentLoc = touch.locationInNode(self)
            let previousLoc = touch.previousLocationInNode(self)
            
            bladeDelta = CGPointMake(currentLoc.x - previousLoc.x, currentLoc.y - previousLoc.y)
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        timeStartTouch = 0
        hideBlade()
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        timeStartTouch = 0
        hideBlade()
    }
    
    
    // MARK: - Contact Events
    
    func didBeginContact(contact: SKPhysicsContact) {
        contactQueue.append(contact)
    }
    
    func processContactForUpdate(currentTime: NSTimeInterval) {
        let contacts = contactQueue
        for contact in contacts {
            handleContact(contact)
            contactQueue.removeObject(contact)
        }
    }
    
    func handleContact(contact: SKPhysicsContact) {
        if let bodyA = contact.bodyA.node,
            let bodyB = contact.bodyB.node {
            if bodyA.parent != nil && bodyB.parent != nil {
                let nodeNames = [bodyA.name, bodyB.name]
                
                if nodeNames.contains({$0 == "skblade"}) {
                    if let fruitIndex = nodeNames.indexOf({$0 == "fruit"}) {
                        let fruit = fruitIndex > 0 ? bodyB : bodyA
                        explode(fruit.position)
                        fruit.runAction(SKAction.sequence([SKAction.fadeOutWithDuration(0.1), SKAction.removeFromParent()]))
                        
                        updateScore(1)
                    } else if let bombIndex = nodeNames.indexOf({$0 == "bomb"}) {
                        let bomb = bombIndex > 0 ? bodyB : bodyA
                        bomb.removeFromParent()
                        
                        updateScore(-10)
                        updateLives(-1)
                    } else if let bonusIndex = nodeNames.indexOf({$0 == "bonus"}) {
                        let bonus = bonusIndex > 0 ? bodyB : bodyA
                        bonus.removeFromParent()
                        
                        updateScore(20)
                        updateLives(1)
                    }
                }
            }
        }
    }
    
    func explode(position: CGPoint) {
        let emitter = SKEmitterNode(fileNamed: "ExplosionPart.sks")!
        emitter.particlePosition = position
        emitter.targetNode = self
        emitter.zPosition = 5
        addChild(emitter)

        emitter.runAction(SKAction.sequence([SKAction.waitForDuration(1), SKAction.removeFromParent()]))
    }
}

// MARK: - Fruit, Bomb, Bonus

class Flying : SKSpriteNode {
    convenience init(image: String, scene: SKScene) {
        self.init(imageNamed: image)
        
        let viewHeight = (scene.size.height ?? 375) / 375
        let viewWidth = (scene.size.width ?? 667) / 667
        let direction: Int8 = arc4random_uniform(2) == 1 ? 1 : -1
        let xMult: CGFloat = CGFloat(arc4random_uniform(UInt32(60 * viewWidth))) / 10 + 0.5
        let widthMult: Double = Double(arc4random_uniform(UInt32(10 * viewWidth))) / 10 + 0.02
        let heightMult: Double = Double(arc4random_uniform(UInt32(8 * viewHeight))) / 10 + 1.15
        let angular = CGFloat(arc4random_uniform(201)) / 100 - 1
        
        zPosition = 2
//        size = CGSize(width: 60, height: 60)
        name = "unknownFlying"
        position = CGPoint(x: ((scene.size.width ?? 375) / 2) - (50 * xMult * CGFloat(direction)), y: 0)
        
        let physics = SKPhysicsBody(circleOfRadius: size.width / 2)
        physics.affectedByGravity = true
        physics.velocity = CGVector(dx: 300 * widthMult * Double(direction), dy: 500 * heightMult)
        physics.angularVelocity = angular
        physics.categoryBitMask = CollisionType.Flying.rawValue
        physics.contactTestBitMask = CollisionType.Blade.rawValue
        physics.collisionBitMask = CollisionType.NoType.rawValue
        
        physicsBody = physics
    }
}


class Fruit: Flying {
    convenience init(scene: SKScene) {
        self.init(image: "can", scene: scene)
        name = "fruit"
    }
}


class Bomb: Flying {
    convenience init(scene: SKScene) {
        self.init(image: "logo", scene: scene)
        name = "bomb"
    }
}


class Bonus: Flying {
    convenience init(scene: SKScene) {
        self.init(image: "can", scene: scene)
        name = "bonus"
    }
}
