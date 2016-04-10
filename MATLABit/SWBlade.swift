//
//  SWBlade.swift
//  SWBladeDemo
//
//  Created by Julio Montoya on 18/06/14.
//  Copyright (c) 2014 Julio Montoya. All rights reserved.
//
//
//  Copyright (c) <2014> <Julio Montoya>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import UIKit
import SpriteKit

class SWBlade: SKNode {
    
     var emitter: SKEmitterNode!
    
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
    
  init(position:CGPoint, target:SKNode, color:UIColor) {
    super.init()
        
    self.name = "skblade"
    self.position = position
        
    let tip:SKSpriteNode = SKSpriteNode(color: color, size: CGSizeMake(25, 25))
//    tip.zRotation = 0.785398163
    tip.zPosition = 10
    tip.texture = SKTexture(imageNamed: "spark.png")
    self.addChild(tip)
        
    emitter = emitterNodeWithColor(color)
    emitter.targetNode = target
    emitter.zPosition = 0
    tip.addChild(emitter)
        
    self.setScale(0.6)
  }
    
  func enablePhysics(categoryBitMask:UInt32, contactTestBitmask:UInt32, collisionBitmask:UInt32) {
    self.physicsBody = SKPhysicsBody(circleOfRadius: 16)
    self.physicsBody?.categoryBitMask = categoryBitMask
    self.physicsBody?.contactTestBitMask = contactTestBitmask
    self.physicsBody?.collisionBitMask = collisionBitmask
    self.physicsBody?.dynamic = false
  }
    
  func emitterNodeWithColor(color:UIColor)->SKEmitterNode {
    let emitterNode:SKEmitterNode = SKEmitterNode(fileNamed: "Blade.sks")!/*
    emitterNode.particleTexture = SKTexture(imageNamed: "spark.png")
    emitterNode.particleBirthRate = 3000
        
    emitterNode.particleLifetime = 0.2
    emitterNode.particleLifetimeRange = 0
        
    emitterNode.particlePositionRange = CGVectorMake(0.0, 0.0)
        
    emitterNode.particleSpeed = 0.0
    emitterNode.particleSpeedRange = 0.0
        
    emitterNode.particleAlpha = 0.8
    emitterNode.particleAlphaRange = 0.2
    emitterNode.particleAlphaSpeed = -0.45
        
    emitterNode.particleScale = 0.5
    emitterNode.particleScaleRange = 0.001
    emitterNode.particleScaleSpeed = -1
        
    emitterNode.particleRotation = 0
    emitterNode.particleRotationRange = 0
    emitterNode.particleRotationSpeed = 0
        
    emitterNode.particleColorBlendFactor = 1
    emitterNode.particleColorBlendFactorRange = 0
    emitterNode.particleColorBlendFactorSpeed = 0
        
    emitterNode.particleColor = color
    emitterNode.particleBlendMode = SKBlendMode.Add*/
        
    return emitterNode
  }
}