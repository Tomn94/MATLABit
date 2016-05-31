//
//  GameScene.swift
//  MATLABit
//
//  Created by Thomas Naudet on 09/04/16.
//  Copyright © 2016 Thomas Naudet

//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.

//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.

//  You should have received a copy of the GNU General Public License
//  along with this program. If not, see http://www.gnu.org/licenses/
//

import SpriteKit
import AVFoundation

class GameVC : UIViewController {
    
    private var audioPlayer: AVAudioPlayer? = AVAudioPlayer()
    
    convenience init() {
        self.init(nibName:nil, bundle:nil)
        
        let documentsPath: NSString = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let filePath = documentsPath.stringByAppendingPathComponent("son.mp3")
        let url = NSURL(fileURLWithPath: filePath)
        do {
            audioPlayer = try AVAudioPlayer(contentsOfURL: url)
            audioPlayer!.numberOfLoops = -1
            audioPlayer!.prepareToPlay()
        } catch {
            audioPlayer = nil
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let gameView = self.view as! SKView
        if gameView.scene == nil {
            let scene = GameScene(size: CGSizeMake(max(gameView.bounds.size.height,gameView.bounds.size.width), min(gameView.bounds.size.height,gameView.bounds.size.width)))
            scene.scaleMode = .AspectFill
            gameView.presentScene(scene)
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(quit), name: "quitGame", object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(error(_:)), name: "errorGame", object: nil)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let ap = audioPlayer {
            ap.play()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if let ap = audioPlayer {
            ap.stop()
        }
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .Landscape
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func error(notif: NSNotification) {
        if let info = notif.userInfo as? Dictionary<String, String> {
            let alert = UIAlertController(title: "Erreur lors de l'envoi du score. Essaie de te reconnecter", message: info["message"], preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func quit() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}


enum CollisionType: UInt32 {
    case NoType = 0
    case Blade = 1
    case Flying = 2
}

enum ExplosionType {
    case Fruit
    case SpecialFruit
    case Bomb
    case Bonus
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    private let startDelay = 2.0
    private let startLives = 3
    private let livesMax = 5
    private let difficultéMax = 3.5
    private let scoreMaxDifficulté = 130
    private let bladeMaxTouchTime: NSTimeInterval = 2
    private var harder = 1.0
    
    private var blade: SWBlade?
    private var bladeDelta = CGPointZero
    private let scoreHUD = SKLabelNode(fontNamed: "Gang of Three")
    private let bestHUD = SKLabelNode(fontNamed: "Gang of Three")
    private var lostHUD: SKLabelNode?
    private var lostHUD2: SKLabelNode?
    private var btnRetry: SKSpriteNode?
    private var btnQuit: SKSpriteNode?
    private var bestEmitter: SKEmitterNode?
    private var livesHUD = Array<SKSpriteNode>()
    private var scoreHUDpos: CGPoint!
    private var bestHUDpos: CGPoint!
    
    private var playing = true
    private var score = 0
    private var lives = 3
    private var timeStart: NSTimeInterval = 0
    private var timeStartTouch: NSTimeInterval = 0
    private var timeLastFruit: NSTimeInterval = 0
    private var best = Data.sharedData.bestScore
    
    private var contactQueue = Array<SKPhysicsContact>()

    override func didMoveToView(view: SKView) {
        if Data.sharedData.harder > 1.0 {
            harder = Data.sharedData.harder
        }
        
        backgroundColor = UIColor.blackColor()
        let back = SKSpriteNode(imageNamed:"backFruit")
        back.zPosition = -1
        back.size = size
        back.position = CGPoint(x: CGRectGetMidX(frame), y: CGRectGetMidY(frame))
        addChild(back)
        
        updateScore(0)
        scoreHUD.zPosition = 1
        scoreHUD.fontSize = 42
        scoreHUD.fontColor = UIColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 1.0)
        scoreHUDpos = CGPoint(x: 15, y: size.height - scoreHUD.frame.size.height - 12)
        scoreHUD.position = scoreHUDpos
        scoreHUD.horizontalAlignmentMode = .Left
        addChild(scoreHUD)
        
        bestHUD.zPosition = 1
        bestHUD.fontSize = 21
        bestHUD.fontColor = UIColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 0.6)
        bestHUDpos = CGPoint(x: 15, y: scoreHUD.position.y - 21)
        bestHUD.position = bestHUDpos
        bestHUD.horizontalAlignmentMode = .Left
        addChild(bestHUD)
        
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
        // Blade
        blade?.position = CGPoint(x: (blade?.position.x)! + bladeDelta.x, y: (blade?.position.y)! + bladeDelta.y)
        bladeDelta = CGPointZero
        
        // Delay game beginning
        if timeStart == 0 {
            timeStart = currentTime
            return
        } else if currentTime - timeStart < startDelay {
            return
        }
        
        // Slashed fruit
        processContactForUpdate(currentTime)
        
        if !playing {
            return
        }
        
        // Spawn
        var difficulté = Double(score) * difficultéMax / Double(scoreMaxDifficulté) * harder
        if difficulté > difficultéMax {
            difficulté = difficultéMax
        }
        let timeLimit = (Double(arc4random_uniform(100)) + 0.1) * (0.2 + difficultéMax - difficulté)
        if currentTime - timeLastFruit > timeLimit {
            timeLastFruit = currentTime
            
            let randAppear = arc4random_uniform(200)
            if randAppear < 2 {
                showBonus()
            } else if randAppear < 10 {
                showSpecialFruit()
            } else if randAppear < 10 + UInt32(ceil(difficulté) * 2) {
                showBomb()
            } else {
                showFruit()
            }
        }
        
        // Lost fruit
        enumerateChildNodesWithName("fruit") { (fruit, stop) in
            if fruit.position.y < 0 {
                fruit.removeFromParent()
                self.updateLives(-1)
            }
        }
    }
    
    func updateScore(by: Int) {
        if !playing {
            return
        }
        
        score += by
        if score < 0 {
            score = 0
        }
        
        scoreHUD.text = String(score)
        if score >= best {
            bestHUD.runAction(SKAction.fadeOutWithDuration(0.5))
        } else if score < best {
            bestHUD.text = "MAX: " + String(best)
        }
    }
    
    func updateLives(by: Int) {
        if !playing ||
            lives + by > livesMax {
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
    
    func showFruit() {
        addChild(Fruit(scene: self))
    }
    
    func showSpecialFruit() {
        addChild(SpecialFruit(theScene: self))
    }
    
    func showBomb() {
        addChild(Bomb(scene: self))
    }
    
    func showBonus() {
        addChild(Bonus(scene: self))
    }
    
    func gameOver() {
        playing = false
        
        lostHUD = SKLabelNode(fontNamed: "Gang of Three")
        lostHUD2 = SKLabelNode(fontNamed: "Gang of Three")
        lostHUD!.text = "Game Over"
        lostHUD2!.text = "Game Over"
        lostHUD!.zPosition = 100
        lostHUD2!.zPosition = 99
        lostHUD!.fontSize = 100 * size.width / 667
        lostHUD2!.fontSize = 104 * size.width / 667
        lostHUD!.fontColor = UIColor(red: 0.9867, green: 0.1506, blue: 0.2419, alpha: 1.0 )
        lostHUD2!.fontColor = UIColor(white: 0, alpha: 0.6)
        lostHUD!.position = CGPoint(x: CGRectGetMidX(frame), y: CGRectGetMidY(frame))
        lostHUD2!.position = CGPoint(x: CGRectGetMidX(frame), y: CGRectGetMidY(frame))
        lostHUD!.setScale(4)
        lostHUD2!.setScale(4)
        lostHUD!.alpha = 0
        lostHUD2!.alpha = 0
        addChild(lostHUD!)
        addChild(lostHUD2!)
        
        lostHUD! .runAction(SKAction.group([SKAction.fadeInWithDuration(0.3), SKAction.scaleTo(1, duration: 0.3)]))
        lostHUD2!.runAction(SKAction.group([SKAction.fadeInWithDuration(0.3), SKAction.scaleTo(1, duration: 0.3)]))
        
        let newScale = 2 * size.width / 667
        let newYBest = 78 * size.width / 667
        scoreHUD.runAction(SKAction.group([SKAction.moveTo(CGPoint(x: 15, y: 15),       duration: 0.3), SKAction.scaleTo(newScale, duration: 0.3)]))
        bestHUD .runAction(SKAction.group([SKAction.moveTo(CGPoint(x: 15, y: newYBest), duration: 0.3), SKAction.scaleTo(newScale, duration: 0.3)]))
        
        btnRetry = SKSpriteNode(imageNamed: "btnRetry")
        btnRetry!.name = "btnRetry"
        btnRetry!.zPosition = 200
        btnRetry!.setScale(0.3)
        btnRetry!.position = CGPoint(x: CGRectGetMidX(frame) + 60, y: CGRectGetMidY(frame) - 80)
        btnRetry!.alpha = 0
        addChild(btnRetry!)
        btnRetry!.runAction(SKAction.sequence([SKAction.waitForDuration(1.15), SKAction.fadeInWithDuration(0.3)]))
        
        btnQuit = SKSpriteNode(imageNamed: "btnQuit")
        btnQuit!.name = "btnQuit"
        btnQuit!.zPosition = 200
        btnQuit!.setScale(0.3)
        btnQuit!.position = CGPoint(x: CGRectGetMidX(frame) - 60, y: CGRectGetMidY(frame) - 80)
        btnQuit!.alpha = 0
        addChild(btnQuit!)
        btnQuit!.runAction(SKAction.sequence([SKAction.waitForDuration(1.15), SKAction.fadeInWithDuration(0.3)]))
        
        if score > best {
            best = score
            bestEmitter = SKEmitterNode(fileNamed: "FirefliesPart.sks")
            bestEmitter!.particlePositionRange = CGVector(dx: scoreHUD.frame.width * newScale, dy: scoreHUD.frame.height * newScale)
            bestEmitter!.particlePosition = CGPoint(x: 15 + scoreHUD.frame.width, y: 15 + scoreHUD.frame.height)
            bestEmitter!.targetNode = self
            bestEmitter!.zPosition = 1
            addChild(bestEmitter!)
        }
        sendBestScore()
    }
    
    func retry() {
        if let lost = lostHUD,
            lost2 = lostHUD2,
            retry = btnRetry,
            quit = btnQuit {
            lost.runAction(SKAction.group([SKAction.fadeOutWithDuration(0.3), SKAction.scaleTo(4, duration: 0.3)]))
            lost2.runAction(SKAction.group([SKAction.fadeOutWithDuration(0.3), SKAction.scaleTo(4, duration: 0.3)]))
            quit.runAction(SKAction.fadeOutWithDuration(0.3))
            retry.runAction(SKAction.fadeOutWithDuration(0.3))
        }
        if let emitter = bestEmitter {
            emitter.removeFromParent()
        }
        
        scoreHUD.runAction(SKAction.group([SKAction.moveTo(scoreHUDpos, duration: 0.3), SKAction.scaleTo(1, duration: 0.3)]))
        bestHUD .runAction(SKAction.group([SKAction.moveTo(bestHUDpos,  duration: 0.3), SKAction.scaleTo(1, duration: 0.3), SKAction.fadeInWithDuration(0.3)]))
        
        enumerateChildNodesWithName("fruit") { (node, stop) in
            node.removeFromParent()
        }
        enumerateChildNodesWithName("bomb") { (node, stop) in
            node.removeFromParent()
        }
        enumerateChildNodesWithName("bonus") { (node, stop) in
            node.removeFromParent()
        }
        
        score = 0
        lives = startLives
        timeStart = 0
        timeStartTouch = 0
        timeLastFruit = 0
        playing = true
        
        updateScore(0)
        updateLives(0)
    }
    
    func quit() {
        NSNotificationCenter.defaultCenter().postNotificationName("quitGame", object: nil)
    }
    
    func sendBestScore() {
        if let login = KeychainSwift().get("login"),
            passw = KeychainSwift().get("passw") {
            let body = ["score": String(best),
                        "client": login,
                        "password": passw,
                        "os": "iOS",
                        "hash": ("**** SCORES ****" + login + String(best) + passw).sha256()]
            
            Data.JSONRequest(Data.sharedData.phpURLs["sendScore"]!, post: body) { (JSON) in
                if let json = JSON,
                    status = json.valueForKey("status") as? Int,
                    cause = json.valueForKey("cause") as? String {
                    if status != 1 {
                        NSNotificationCenter.defaultCenter().postNotificationName("errorGame", object: nil, userInfo: ["message": cause])
                    }
                } else {
                    NSNotificationCenter.defaultCenter().postNotificationName("errorGame", object: nil, userInfo: ["message": "Erreur serveur"])
                }
            }
        }
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
        if let touch = touches.first {
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
        
        if !playing,
            let touch = touches.first {
            let loc = touch.locationInNode(self)
            
            let node = nodeAtPoint(loc)
            if node.name == "btnRetry" {
                retry()
            } else if node.name == "btnQuit" {
                quit()
            }
        }
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
                        
                        let special = fruit.userData!["specialFruit"] as! Bool
                        explode(fruit.position, type: special ? .SpecialFruit : .Fruit)
                        fruit.runAction(SKAction.sequence([SKAction.fadeOutWithDuration(0.1), SKAction.removeFromParent()]))
                        
                        updateScore((special) ? 5 : 1)
                    } else if let bombIndex = nodeNames.indexOf({$0 == "bomb"}) {
                        let bomb = bombIndex > 0 ? bodyB : bodyA
                        
                        explode(bomb.position, type: .Bomb)
                        bomb.runAction(SKAction.sequence([SKAction.fadeOutWithDuration(0.1), SKAction.removeFromParent()]))
                        
                        updateScore(-10)
                        updateLives(-1)
                    } else if let bonusIndex = nodeNames.indexOf({$0 == "bonus"}) {
                        let bonus = bonusIndex > 0 ? bodyB : bodyA
                        
                        explode(bonus.position, type: .Bonus)
                        bonus.runAction(SKAction.sequence([SKAction.fadeOutWithDuration(0.1), SKAction.removeFromParent()]))
                        
                        updateScore(10)
                        updateLives(1)
                    }
                }
            }
        }
    }
    
    func explode(position: CGPoint, type: ExplosionType) {
        var emitter = SKEmitterNode(fileNamed: "ExplosionPart.sks")!
        
        switch type {
        case .Fruit:
            break
        case .SpecialFruit:
            emitter.particleColorSequence = SKKeyframeSequence(keyframeValues: [SKColor.whiteColor(), SKColor.redColor()],
                                                               times: [0, 0.15])
        case .Bomb:
            emitter = SKEmitterNode(fileNamed: "FirePart.sks")!
        case .Bonus:
            emitter.particleColorSequence = SKKeyframeSequence(keyframeValues: [SKColor.whiteColor(), SKColor.yellowColor()],
                                                               times: [0, 0.15])
        }
        
        emitter.particlePosition = position
        emitter.targetNode = self
        emitter.zPosition = 5
        addChild(emitter)

        emitter.runAction(SKAction.sequence([SKAction.waitForDuration(1), SKAction.removeFromParent()]))
    }
}


// MARK: - Fruit, Bomb, Bonus

extension SKNode {
    func setFlyingPhysics(diameter: CGFloat, scene: SKScene) {
        let viewHeight = (scene.size.height ?? 375) / 375
        let viewWidth = (scene.size.width ?? 667) / 667
        let direction: Int8 = arc4random_uniform(2) == 1 ? 1 : -1
        let xMult: CGFloat = CGFloat(arc4random_uniform(UInt32(60 * viewWidth))) / 10 + 0.5
        let widthMult: Double = Double(arc4random_uniform(UInt32(10 * viewWidth))) / 10 + 0.02
        let heightMult: Double = Double(arc4random_uniform(UInt32(8 * viewHeight))) / 10 + 1.15
        let angular = CGFloat(arc4random_uniform(201)) / 100 - 1
        
        userData = ["specialFruit": false]
        zPosition = 2
        position = CGPoint(x: ((scene.size.width ?? 375) / 2) - (50 * xMult * CGFloat(direction)), y: 0)
        
        let physics = SKPhysicsBody(circleOfRadius: diameter / 2)
        physics.affectedByGravity = true
        physics.velocity = CGVector(dx: 300 * widthMult * Double(direction), dy: 500 * heightMult)
        physics.angularVelocity = angular
        physics.categoryBitMask = CollisionType.Flying.rawValue
        physics.contactTestBitMask = CollisionType.Blade.rawValue
        physics.collisionBitMask = CollisionType.NoType.rawValue
        
        physicsBody = physics
    }
}


class Fruit: SKLabelNode {
    convenience init(scene: SKScene) {
        self.init()
        
        name = "fruit"
        let fruits = ["🍏", "🍎", "🍐", "🍊", "🍋", "🍌", "🍉", "🍇", "🍓", "🍈", "🍒", "🍑", "🍍", "🍆"]
        text = fruits[Int(arc4random_uniform(UInt32(fruits.count)))]
        fontSize = 72
        
        setFlyingPhysics(self.frame.width, scene: scene)
    }
}

class SpecialFruit: Fruit {
    convenience init(theScene: SKScene) {
        self.init(scene: theScene)
        
        userData = ["specialFruit": true]
        var specials = ["🍗", "🍕", "🍔", "🍟"]
        if #available(iOS 9.1, *) {
            specials = ["🌮", "🌯", "🍗", "🍕", "🍔", "🍟"]
        }
        text = specials[Int(arc4random_uniform(UInt32(specials.count)))]
    }
}


class Bomb: SKSpriteNode {
    convenience init(scene: SKScene) {
        self.init(texture: SKTexture(image: Data.sharedData.logo))
        
        name = "bomb"
        size = CGSize(width: 70, height: 70)
        
        setFlyingPhysics(size.width, scene: scene)
    }
}


class Bonus: SKSpriteNode {
    convenience init(scene: SKScene) {
        self.init(imageNamed: "can")
        
        name = "bonus"
        setFlyingPhysics(size.width, scene: scene)
    }
}
