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

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    enum BrickLevel: CGFloat {
        case low = 0.0
        case high = 100.0
    }
    
    let skater = Skater(imageNamed: "skater")
    
    var bricks = [SKSpriteNode]()
    var brickSize = CGSize.zero
    var brickLevel = BrickLevel.low
    
    var gems = [SKSpriteNode]()
    
    
    var scrollSpeed: CGFloat = 5.0
    
    let startingScrollSpeed: CGFloat = 5.0
    
    
    let gravitySpeed: CGFloat = 1.5
    var lastUpdateTime: TimeInterval?
    
    func updateSkater() {
        if let velocityY = skater.physicsBody?.velocity.dy {
            if velocityY < -100.0 || velocityY > 100.0 {
                skater.isOnGround = false
            }
        }
        
        let isOffScreen = skater.position.y < 0.0 || skater.position.x < 0.0
        
        let maxRotation = CGFloat(GLKMathDegreesToRadians(85.0))
        
        let isTippedOver = skater.zRotation > maxRotation || skater.zRotation < -maxRotation
        
        if isOffScreen || isTippedOver {
            gameOver()
        }
        
    }
    func updateGems(withScrollAmount currentScrollAmount:CGFloat){
        for gem in gems {
            let thisGemX = gem.position.x - currentScrollAmount
            gem.position = CGPoint(x: thisGemX, y: gem.position.y)
            if gem.position.x < 0.0 {
                removeGem(gem)
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
            let brickY = brickSize.height / 2.0 + brickLevel.rawValue
            
            let randomNumber = arc4random_uniform(99)
            
            if randomNumber < 5 {
                let gap = 20.0 * scrollSpeed
                brickX += gap
                
                let randomGemYAmount = CGFloat(arc4random_uniform(150))
                
                let newGemY = brickY + skater.size.height + randomGemYAmount
                let newGemX = brickX - gap / 2.0
                spawnGem(atPosition: CGPoint(x: newGemX, y: newGemY))
                
                
            } else if randomNumber < 10 {
                if brickLevel == .high {
                    brickLevel = .low
                } else if  brickLevel == .low {
                    brickLevel = .high
                }
            }
            
            
            let newBrick = spawnBrick(atPosition: CGPoint(x: brickX, y: brickY))
            farthestRightBrickX = newBrick.position.x
            
            
            
        }
        
    }
    
    
    override func didMove(to view: SKView) {
       physicsWorld.gravity = CGVector(dx: 0.0, dy: -6.0)
        physicsWorld.contactDelegate = self
        
        anchorPoint = CGPoint.zero
        
        let background = SKSpriteNode(imageNamed: "background")
        let xMid = frame.midX
        let yMid = frame.midY
        
        background.position = CGPoint(x: xMid, y: yMid)
        
        addChild(background)
        skater.setupPhysicsBody()
        addChild(skater)
        
        let tapMethod = #selector(GameScene.handleTap(tapGesture:))
        let tapGesture = UITapGestureRecognizer(target: self, action: tapMethod)
        view.addGestureRecognizer(tapGesture)
        
        startGame()
        
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        if contact.bodyA.categoryBitMask == PhysicsCategory.skater && contact.bodyB.categoryBitMask == PhysicsCategory.brick {
            skater.isOnGround =  true
        } else if contact.bodyA.categoryBitMask == PhysicsCategory.skater && contact.bodyB.categoryBitMask == PhysicsCategory.gem {
            if let gem = contact.bodyB.node as? SKSpriteNode {
                removeGem(gem)
            }
        }
    }
    
    
    
    
    @objc func handleTap(tapGesture: UITapGestureRecognizer) {
        if skater.isOnGround {
            skater.velocity = CGPoint(x: 0.0, y: skater.jumpSpeed)
            
            skater.isOnGround = false
            
            skater.physicsBody?.applyImpulse(CGVector(dx: 0.0, dy: 260.0))
        }
    }
    
    func resetSkater() {
        let skaterX = frame.midX / 2.0
        let skaterY = skater.frame.height / 2.0 + 64.0
        skater.position = CGPoint(x: skaterX, y: skaterY)
        skater.zPosition = 10
        skater.minimumY = skaterY
        
        skater.zRotation = 0.0
        skater.physicsBody?.velocity = CGVector(dx: 0.0, dy: 0.0)
        
        skater.physicsBody?.angularVelocity = 0.0
        
    }
    
    func startGame() {
        
        resetSkater()
        scrollSpeed = startingScrollSpeed
        brickLevel = .low
        
        lastUpdateTime = nil
        
        for brick in bricks {
            brick.removeFromParent()
        }
        bricks.removeAll(keepingCapacity: true)
        
    }
    
    func gameOver() {
        startGame()
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
    
    func spawnGem(atPosition position: CGPoint) {
        let gem = SKSpriteNode(imageNamed: "gem")
        gem.position = position
        gem.zPosition = 9
        
        addChild(gem)
        
        gem.physicsBody = SKPhysicsBody(rectangleOf: gem.size, center: gem.centerRect.origin)
        gem.physicsBody?.categoryBitMask = PhysicsCategory.gem
        gem.physicsBody?.affectedByGravity = false
        
        gems.append(gem)
        
    }
    
    func removeGem(_ gem: SKSpriteNode){
        gem.removeFromParent()
        
        if let gemIndex = gems.index(of: gem) {
            gems.remove(at: gemIndex)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        scrollSpeed += 0.01
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
        updateGems(withScrollAmount: currentScrollAmount)
        
    }
}


