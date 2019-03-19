//
//  GameScene.swift
//  Skateboarder game
//
//  Created by Luke Kollen on 12/6/18.
//  Copyright © 2018 Luke Kollen. All rights reserved.
//

import SpriteKit

struct PhysicsCategory {
    static let skater:UInt32 = 0x1 << 0
    static let brick:UInt32 = 0x1 << 1
    static let gem:UInt32 = 0x1 << 2
}

class GameScene: SKScene {
    
    let skater = Skater(imageNamed: "skater")
    
    var bricks = [SKSpriteNode]()
    var brickSize = CGSize.zero
    
    var scrollSpeed: CGFloat = 5.0
    
    let gravitySpeed: CGFloat = 1.5
    var lastUpdateTime: TimeInterval?
    
    func updateSkater() {
        if !skater.isOnGround {
            let velocityY = skater.velocity.y - gravitySpeed
            skater.velocity = CGPoint(x: skater.velocity.x, y: velocityY)
            
            let newSkaterY: CGFloat = skater.position.y + skater.velocity.y
            skater.position = CGPoint(x: skater.position.x, y: newSkaterY)
            
            if skater.position.y < skater.minimumY {
                skater.position.y = skater.minimumY
                skater.velocity = CGPoint.zero
                skater.isOnGround = true
            }
        }
    }
    
    func updateBricks(withScrollAmount currentScrollAmount: CGFloat) {
        var farthestRightBrickX: CGFloat = 0.0
        
        for brick in bricks {
            let newX = brick.position.x - currentScrollAmount
            
            // if the brick has a negative x-value this means that the brick is no longer visible to the user
            if newX < -brickSize.width {
                // we are now removing the brick visually and from memory
                brick.removeFromParent()
                
                // we also need to remove the brick from the bricks array based on the index value
                if let brickIndex = bricks.index(of: brick) {
                    bricks.remove(at: brickIndex)
                }
            } else {
                // for the brick still on the screen update its position
                brick.position = CGPoint(x: newX, y: brick.position.y)
                
                // update our furthest right position tracker
                if brick.position.x > farthestRightBrickX {
                    farthestRightBrickX = brick.position.x
                }
            }
            
        }
        
        while farthestRightBrickX < frame.width {
            var brickX = farthestRightBrickX + brickSize.width + 1.0
            let brickY = brickSize.height / 2.0
            
            let randomNumber = arc4random_uniform(99)
            
            if randomNumber < 5 {
                let gap = 20.0 * scrollSpeed
                brickX += gap
            }
            let newBrick = spawnBrick(atPosition: CGPoint(x: brickX, y: brickY))
            farthestRightBrickX = newBrick.position.x
            
            
            
        }
        
    }
    
    
    override func didMove(to view: SKView) {
       physicsWorld.gravity = CGVector(dx: 0.0, dy: -6.0)
        
        anchorPoint = CGPoint.zero
        
        let background = SKSpriteNode(imageNamed: "background")
        let xMid = frame.midX
        let yMid = frame.midY
        
        background.position = CGPoint(x: xMid, y: yMid)
        
        addChild(background)
        skater.setupPhysicsBody()
        resetSkater()
        addChild(skater)
        
        let tapMethod = #selector(GameScene.handleTap(tapGesture:))
        let tapGesture = UITapGestureRecognizer(target: self, action: tapMethod)
        view.addGestureRecognizer(tapGesture)
        
    }
    
    @objc func handleTap(tapGesture: UITapGestureRecognizer) {
        if skater.isOnGround {
            skater.velocity = CGPoint(x: 0.0, y: skater.jumpSpeed)
            
            skater.isOnGround = false
        }
    }
    
    func resetSkater() {
        let skaterX = frame.midX / 2.0
        let skaterY = skater.frame.height / 2.0 + 64.0
        skater.position = CGPoint(x: skaterX, y: skaterY)
        skater.zPosition = 10
        skater.minimumY = skaterY
        
    }
    
    func spawnBrick(atPosition position: CGPoint) -> SKSpriteNode {
        let brick = SKSpriteNode(imageNamed: "sidewalk")
        brick.position = position
        brick.zPosition = 8
        addChild(brick)
        
        brickSize = brick.size
        
        bricks.append(brick)
        
        let center = brick.centerRect.origin
        brick.physicsBody = SKPhysicsBody(rectangleOf: brick.size, center: center)
        brick.physicsBody?.affectedByGravity = false
        
        brick.physicsBody?.categoryBitMask = PhysicsCategory.brick
        brick.physicsBody?.collisionBitMask = 0
        
        return brick
    }
    
    override func update(_ currentTime: TimeInterval) {
        var elapsedTime: TimeInterval = 0.0
        
        if let lastTimeStamp = lastUpdateTime {
            elapsedTime = currentTime - lastTimeStamp
        }
        
        lastUpdateTime = currentTime
        
        let expectedElapsedTime: TimeInterval = 1.0 / 60.0
        
        let scrollAdjustment = CGFloat(elapsedTime / expectedElapsedTime)
        // The scroll adjustment will be greater than or less than 1
        let currentScrollAmount = scrollSpeed * scrollAdjustment
       
        updateBricks(withScrollAmount: currentScrollAmount)
        updateSkater()
        
    }
}


