//
//  GameScene.swift
//  BreakoutGameProject
//
//  Created by Yann Christophe Maertens on 30/12/2021.
//

// condition power up (durée, nombre de rebonds, briques)
// systeme de score


import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate, ObservableObject {
    
    // Bitmask categories for contacts/collisions
    
    let ballCategory: UInt32 = 0x1 << 0 // 1 = 1
    let groundCategory: UInt32 = 0x1 << 1 // 10 = 2
    let blockCategory: UInt32 = 0x1 << 2 // 100 = 4
    let paddleCategory: UInt32 = 0x1 << 3 // 1000 = 8
    let borderCategory: UInt32 = 0x1 << 4 // 10000 = 16
    let powerCategory: UInt32 = 0x1 << 5 // 100000 = 32
    
    @Published var currentLevel = 0
    
    var paddle: SKSpriteNode?
    
    let levels: [Level] = try! Bundle.main.decode("levels.json")
    let powers: [PowerUp] = try! Bundle.main.decode("powers.json")
    
    // Manage the game state
    lazy var gameState = GKStateMachine(states: [
        WaitingForTap(scene: self),
        Playing(scene: self),
        GameOver(scene: self)
    ])
    
    override func didMove(to view: SKView) {
        gameState.enter(WaitingForTap.self)
        buildBoard()
        buildGameMessage()
        buildGround()
        buildBlocks()
        buildBall()
        buildPaddle()
    }
    
    func remove(_ node: SKNode) { node.removeFromParent() }
    
    func getPowerUp() -> PowerUp? {
        let sortedPowers = powers.sorted(by: { $0.odds < $1.odds })
        var selectedPower: PowerUp? = nil
        
        for power in sortedPowers {
            let randomNumber = Int.random(in: 0...100)
            if randomNumber <= power.odds { selectedPower = power }
        }
        
        return selectedPower
    }
    
    // Release power ups from block destruction
    func releasePower(on node: SKNode) {
        
        guard let powerUp = getPowerUp() else { return }
        
        let power = SKSpriteNode(imageNamed: powerUp.image)
        power.name = "Power"
        power.texture = SKTexture(imageNamed: powerUp.image)
        power.size = CGSize(width: frame.width * 0.15, height: frame.height * 0.04)
        power.position = node.position
        power.zPosition = 2
        power.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: frame.width * 0.15, height: frame.height * 0.04))
        power.physicsBody!.categoryBitMask = powerCategory
        power.physicsBody?.collisionBitMask = groundCategory
        power.physicsBody!.contactTestBitMask = paddleCategory | groundCategory
        addChild(power)
        
        power.physicsBody!.applyImpulse(CGVector(dx: 0, dy: -15))
    }
    
    // Animation for paddle
    func paddleAnimation(on node: SKNode) {
        
        let texture = SKTexture(imageNamed: "paddle_texture")
        let back = SKTexture(imageNamed: "paddle")
        
        node.run(SKAction.sequence([
            SKAction.setTexture(texture),
            SKAction.wait(forDuration: 0.1),
            SKAction.setTexture(back)
        ]))
    }
    
    // Animation for blocks
    func blockDestructionAnimation(node: SKSpriteNode) {
        let block = SKShapeNode(rectOf: CGSize(width: frame.width * 0.15, height: frame.height * 0.04))
        block.strokeColor = .white
        block.fillColor = .white
        block.position = node.position
        block.zPosition = 3
        addChild(block)
        
        let wait = SKAction.wait(forDuration: 0.1)
        let remove = SKAction.removeFromParent()
        
        block.run(SKAction.sequence([wait, remove]))
    }
    
    func breakBlock(_ node: SKSpriteNode) {
        switch node.texture?.name {
        case "red":
            blockDestructionAnimation(node: node)
            node.texture = SKTexture(imageNamed: "orange")
        case "orange":
            blockDestructionAnimation(node: node)
            node.texture = SKTexture(imageNamed: "yellow")
        case "yellow":
            blockDestructionAnimation(node: node)
            node.texture = SKTexture(imageNamed: "green")
        case "green":
            releasePower(on: node)
            blockDestructionAnimation(node: node)
            node.removeFromParent()
        default:
            break
        }
    }
    
    func resizePaddle(_ powerName: String) {
        let smallerSize = frame.width * 0.15
        let normalSize = frame.width * 0.25
        let greaterSize = frame.width * 0.4
        
        let expandedSize = paddle?.size.width == smallerSize ? normalSize : greaterSize
        let reducedSize = paddle?.size.width == greaterSize ? normalSize : smallerSize
        
        switch powerName {
        case "expand":
            paddle?.size.width = expandedSize
        case "reduce":
            paddle?.size.width = reducedSize
        default:
            paddle?.size.width = normalSize
        }
        
        paddle?.physicsBody = SKPhysicsBody(rectangleOf: paddle?.size ?? size)
        paddle?.physicsBody!.isDynamic = false
        paddle?.physicsBody!.friction = 0
        paddle?.physicsBody!.restitution = 1
        paddle?.physicsBody!.categoryBitMask = paddleCategory
    }
    
    // Manage all the contacts/collisions
    func didBegin(_ contact: SKPhysicsContact) {
        
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        // Check collision when the paddle touch the ball
        if firstBody.categoryBitMask == ballCategory && secondBody.categoryBitMask == paddleCategory {
            paddleAnimation(on: secondBody.node as! SKSpriteNode)
        }
        
        
        if firstBody.categoryBitMask == ballCategory && secondBody.categoryBitMask == groundCategory {
            remove(firstBody.node as! SKShapeNode)
            gameState.enter(GameOver.self)
        }
        
        // Check collision when the ball touch a block
        if firstBody.categoryBitMask == ballCategory && secondBody.categoryBitMask == blockCategory {
            breakBlock(secondBody.node as! SKSpriteNode)
            if isGameWon() {
                gameState.enter(GameOver.self)
            }
        }
        
        // Check collision when the Power touch the ground
        if firstBody.categoryBitMask == groundCategory && secondBody.categoryBitMask == powerCategory {
            remove(secondBody.node as! SKSpriteNode)
        }
        
        // Check collision when paddle touch a power up.
        if firstBody.categoryBitMask == paddleCategory && secondBody.categoryBitMask == powerCategory {
            guard let power = secondBody.node as? SKSpriteNode else { return }
            
            if let texture = power.texture, let name = texture.name {
                resizePaddle(name)
            }
            
            remove(secondBody.node as! SKSpriteNode)
        }
    }
    
    func buildBoard() {
        self.size = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        
        let gravity = CGVector(dx: 0.0, dy: 0.0)
        let borderBody = SKPhysicsBody(edgeLoopFrom: frame)
        
        borderBody.categoryBitMask = borderCategory
        
        physicsBody = borderBody
        physicsBody!.friction = 0.0
        physicsWorld.gravity = gravity
        physicsWorld.contactDelegate = self
    }
    
    func buildGameMessage() {
        let gameMessage = SKLabelNode(text: "Level \(currentLevel)")
        gameMessage.name = "Game Message"
        gameMessage.fontSize = frame.width * 0.2
        gameMessage.fontColor = .white
        gameMessage.position = CGPoint(x: frame.midX, y: frame.midY * 0.7)
        addChild(gameMessage)
    }
    
    func buildGround() {
        let ground = SKShapeNode(rectOf: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.02))
        ground.name = "Ground"
        ground.strokeColor = .clear
        ground.fillColor = .clear
        ground.position = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.origin.x)
        ground.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.02))
        ground.physicsBody!.isDynamic = false
        ground.physicsBody!.categoryBitMask = groundCategory
        addChild(ground)
    }
    
    func buildBall() {
        let ball = SKShapeNode(circleOfRadius: 10)
        ball.name = "Ball"
        ball.fillColor = .white
        ball.position = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY * 0.2)
        ball.zPosition = 2
        
        ball.physicsBody = SKPhysicsBody(circleOfRadius: 10)
        ball.physicsBody!.allowsRotation = false
        ball.physicsBody!.friction = 0
        ball.physicsBody!.restitution = 1
        ball.physicsBody!.linearDamping = 0
        ball.physicsBody!.angularDamping = 0
        ball.physicsBody!.categoryBitMask = ballCategory
        ball.physicsBody?.collisionBitMask = blockCategory | groundCategory | paddleCategory | borderCategory
        ball.physicsBody!.contactTestBitMask =  blockCategory | groundCategory | paddleCategory
        
        addChild(ball)
    }
    
    func buildPaddle() {
        let size = CGSize(width: frame.width * 0.25, height: frame.height * 0.025)
        
        paddle = SKSpriteNode(imageNamed: "paddle")
        paddle?.name = "Paddle"
        paddle?.size = size
        paddle?.position = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY * 0.1)
        paddle?.zPosition = 2
        
        paddle?.physicsBody = SKPhysicsBody(rectangleOf: paddle?.size ?? size)
        paddle?.physicsBody!.isDynamic = false
        paddle?.physicsBody!.friction = 0
        paddle?.physicsBody!.restitution = 1
        paddle?.physicsBody!.categoryBitMask = paddleCategory
        
        if let paddle = paddle { addChild(paddle) }
    }
    
    func getBlockRow(of blocks: [String]) -> [SKSpriteNode] {
        var blockRow = [SKSpriteNode]()
        
        let blockSize = CGSize(width: frame.width * 0.15, height: frame.height * 0.04)
        let xOffset = frame.midX / 2.7
        let yOffset = frame.midY / 2.5
        var position = CGPoint(x: frame.minX + xOffset, y: frame.maxY - yOffset)
        
        for block in blocks {
            
            let blockNode = SKSpriteNode(imageNamed: block)
            blockNode.name = "Block"
            blockNode.size = blockSize
            blockNode.zPosition = 2
            blockNode.position = position
            
            blockNode.physicsBody = SKPhysicsBody(rectangleOf: blockNode.frame.size)
            blockNode.physicsBody!.allowsRotation = false
            blockNode.physicsBody!.friction = 0.0
            blockNode.physicsBody!.affectedByGravity = false
            blockNode.physicsBody!.isDynamic = false
            blockNode.physicsBody!.categoryBitMask = blockCategory
            
            position.x += frame.width * 0.16
            
            blockRow.append(blockNode)
        }
        
        return blockRow
    }
    
    func buildBlocks() {
        var heightValue: CGFloat = 0
        
        for row in levels[currentLevel].blocks {
            for block in getBlockRow(of: row) {
                block.position.y -= (frame.height * heightValue)
                addChild(block)
            }
            heightValue += 0.045
        }
    }
    
    func isGameWon() -> Bool {
        var numberOfBricks = 0
        self.enumerateChildNodes(withName: "Block") { node, stop in
            numberOfBricks += 1
        }
        let numberOfMetals = levels[currentLevel].blocks.filter { $0.contains("gray") }.count
        return numberOfBricks == numberOfMetals
    }
    
    func loadNewScene() {
        let newScene = GameScene()
        newScene.currentLevel = currentLevel
        
        if isGameWon() {
            if currentLevel < levels.count - 1 { newScene.currentLevel += 1 }
            else {
                newScene.currentLevel = 0
            }
        }
        //let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
        let crossfade = SKTransition.crossFade(withDuration: 0.5)
        self.view?.presentScene(newScene, transition: crossfade)
    }
    
    override func update(_ currentTime: TimeInterval) {
        gameState.update(deltaTime: currentTime)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        //guard let touch = touches.first else { return }
        //let touchLocation = touch.location(in: self)
        
        switch gameState.currentState {
            
        case is WaitingForTap:
            print("Waiting For Tap")
        case is Playing:
            print("Playing")
        case is GameOver:
            loadNewScene()
            
        default:
            break
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let paddle = self.childNode(withName: "Paddle") as? SKSpriteNode else { return }
        
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        let previousLocation = touch.previousLocation(in: self)
        
        let xLocation = touchLocation.x - previousLocation.x
        var paddleX = paddle.position.x + xLocation
        
        paddleX = max(paddleX, paddle.frame.size.width/2)
        paddleX = min(paddleX, size.width - paddle.frame.size.width/2)
        
        paddle.position = CGPoint(x: paddleX, y: paddle.position.y)
        
        if gameState.currentState is WaitingForTap {
            guard let ball = self.childNode(withName: "Ball") as? SKShapeNode else { return }
            ball.position = CGPoint(x: paddleX, y: ball.position.y)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        gameState.enter(Playing.self)
    }
}

struct Level: Codable {
    var id: Int
    var blocks: [[String]]
}

struct PowerUp: Codable {
    let image: String
    let odds: Int
}
