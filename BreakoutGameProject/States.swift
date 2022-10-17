//
//  GameOver.swift
//  BreakoutGameProject
//
//  Created by Yann Christophe Maertens on 31/12/2021.
//

import GameplayKit

// unowned: https://docs.swift.org/swift-book/LanguageGuide/AutomaticReferenceCounting.html

// isValidNextState : Define the next state when will exit.
// willExit : Execute the code block when the game exit this state.
// didEnter : Execute the code block when the game enter in this state.
// update : While in this state, execute the code block each frame.

class WaitingForTap: GKState {
    unowned let scene: GameScene
    
    init(scene: SKScene) {
        self.scene = scene as! GameScene
        super.init()
    }
    
    override func didEnter(from previousState: GKState?) {
        guard let gameMessage = scene.childNode(withName: "Game Message") as? SKLabelNode else { return }
        let scale = SKAction.scale(to: 1, duration: 0)
        gameMessage.run(scale)
    }
    
    override func willExit(to nextState: GKState) {
        guard let gameMessage = scene.childNode(withName: "Game Message") as? SKLabelNode else { return }
        let scale = SKAction.scale(to: 0, duration: 0)
        gameMessage.run(scale)
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass is Playing.Type
    }
}

class Playing: GKState {
    
    unowned let scene: GameScene
    
    init(scene: SKScene) {
        self.scene = scene as! GameScene
        super.init()
    }
    
    override func didEnter(from previousState: GKState?) {
        if previousState is WaitingForTap {
            guard let ball = scene.childNode(withName: "Ball") as? SKShapeNode else { return }
            ball.physicsBody!.applyImpulse(CGVector(dx: randomDirection(), dy: randomDirection()))
        }
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        
        guard let ball = scene.childNode(withName: "Ball") as? SKShapeNode else { return }
        
        let xSpeed = sqrt(ball.physicsBody!.velocity.dx * ball.physicsBody!.velocity.dx)
        let ySpeed = sqrt(ball.physicsBody!.velocity.dy * ball.physicsBody!.velocity.dy)
        
        if xSpeed <= 10.0 {
            ball.physicsBody?.applyImpulse(CGVector(dx: randomDirection(), dy: 0.0))
        }
        if ySpeed <= 10.0 {
            ball.physicsBody?.applyImpulse(CGVector(dx: 0.0, dy: randomDirection()))
        }
    }
    
    func randomFloat(from: CGFloat, to: CGFloat) -> CGFloat {
        CGFloat.random(in: from...to)
    }
    
    func randomDirection() -> CGFloat {
        let speedFactor: CGFloat = 5.0
        if randomFloat(from: 0.0, to: 100.0) >= 50 {
            return -speedFactor
        } else {
            return speedFactor
        }
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass is GameOver.Type
    }
}

class GameOver: GKState {
    unowned let scene: GameScene
    
    init(scene: SKScene) {
        self.scene = scene as! GameScene
        super.init()
    }
    
    override func didEnter(from previousState: GKState?) {
        guard let gameMessage = scene.childNode(withName: "Game Message") as? SKLabelNode else { return }
        let scale = SKAction.scale(to: 1, duration: 0)
        
        if scene.isGameWon() {
            scene.loadNewScene()
        } else {
            gameMessage.text = "Try again"
            gameMessage.run(scale)
        }
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass is WaitingForTap.Type
    }
}
