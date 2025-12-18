//
//  GameScene.swift
//  AsteroidDodge
//
//  Created by Ogulcan Serbest on 18.12.25.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    private let playerSize = CGSize(width: 96, height: 96)
    private let asteroidRadius: CGFloat = 24
    private let spawnInterval: TimeInterval = 1.0
    private let asteroidSpeed: CGFloat = 220

    private var playerNode: SKSpriteNode!
    private var scoreLabel: SKLabelNode!
    private var gameOverLabel: SKLabelNode?
    private var finalScoreLabel: SKLabelNode?
    private var restartLabel: SKLabelNode?
    private var gameOverOverlay: SKNode?
    private var restartButton: SKShapeNode?
    private var overlayBackdrop: SKSpriteNode?

    private var lastUpdateTime: TimeInterval = 0
    private var scoreAccumulator: TimeInterval = 0
    private var score: Int = 0
    private var isGameOver = false

    private struct PhysicsCategory {
        static let player: UInt32 = 0x1 << 0
        static let asteroid: UInt32 = 0x1 << 1
    }

    private var playerRadius: CGFloat {
        min(playerSize.width, playerSize.height) * 0.5
    }

    override func didMove(to view: SKView) {
        removeAllChildren()
        backgroundColor = SKColor(red: 0.32, green: 0.2, blue: 0.55, alpha: 1.0)

        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        createPlayer()
        createScoreLabel()
        layoutUI()
        startSpawning()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutUI()
    }

    private func createPlayer() {
        let player = SKSpriteNode(imageNamed: "Raumschiff")
        player.size = playerSize
        player.position = CGPoint(x: frame.midX, y: frame.minY + playerRadius + 40)
        player.name = "player"

        let body = SKPhysicsBody(circleOfRadius: playerRadius)
        body.isDynamic = false
        body.categoryBitMask = PhysicsCategory.player
        body.contactTestBitMask = PhysicsCategory.asteroid
        body.collisionBitMask = 0
        player.physicsBody = body

        addChild(player)
        playerNode = player
    }

    private func createScoreLabel() {
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.fontSize = 20
        label.fontColor = SKColor.white
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .top
        label.text = "Score: 0"
        addChild(label)
        scoreLabel = label
    }

    private func layoutUI() {
        scoreLabel?.position = CGPoint(x: 16, y: frame.maxY - 16)

        if let backdrop = overlayBackdrop {
            backdrop.size = frame.size
            backdrop.position = CGPoint(x: frame.midX, y: frame.midY)
        }

        gameOverLabel?.position = CGPoint(x: frame.midX, y: frame.midY + 80)
        finalScoreLabel?.position = CGPoint(x: frame.midX, y: frame.midY)
        restartButton?.position = CGPoint(x: frame.midX, y: frame.midY - 60)
    }

    private func startSpawning() {
        removeAction(forKey: "spawn")
        let spawn = SKAction.run { [weak self] in
            self?.spawnAsteroid()
        }
        let wait = SKAction.wait(forDuration: spawnInterval)
        let sequence = SKAction.sequence([spawn, wait])
        run(SKAction.repeatForever(sequence), withKey: "spawn")
    }

    private func spawnAsteroid() {
        guard !isGameOver else { return }

        let asteroid = SKShapeNode(circleOfRadius: asteroidRadius)
        asteroid.fillColor = SKColor(red: 0.95, green: 0.55, blue: 0.15, alpha: 1.0)
        asteroid.strokeColor = SKColor.clear
        asteroid.name = "asteroid"

        let minX = frame.minX + asteroidRadius
        let maxX = frame.maxX - asteroidRadius
        let randomX = CGFloat.random(in: minX...maxX)
        asteroid.position = CGPoint(x: randomX, y: frame.maxY + asteroidRadius)

        let body = SKPhysicsBody(circleOfRadius: asteroidRadius)
        body.isDynamic = true
        body.affectedByGravity = false
        body.velocity = CGVector(dx: 0, dy: -asteroidSpeed)
        body.linearDamping = 0
        body.categoryBitMask = PhysicsCategory.asteroid
        body.contactTestBitMask = PhysicsCategory.player
        body.collisionBitMask = 0
        asteroid.physicsBody = body

        addChild(asteroid)
    }

    private func movePlayer(to position: CGPoint) {
        let minX = frame.minX + playerRadius
        let maxX = frame.maxX - playerRadius
        let minY = frame.minY + playerRadius
        let maxY = frame.maxY - playerRadius
        let clampedX = min(max(position.x, minX), maxX)
        let clampedY = min(max(position.y, minY), maxY)
        playerNode.position = CGPoint(x: clampedX, y: clampedY)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGameOver {
            guard let touch = touches.first else { return }
            let location = touch.location(in: self)
            if let button = restartButton, button.contains(location) {
                restartGame()
            }
            return
        }

        if let touch = touches.first {
            movePlayer(to: touch.location(in: self))
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isGameOver, let touch = touches.first else { return }
        movePlayer(to: touch.location(in: self))
    }

    override func update(_ currentTime: TimeInterval) {
        let delta = currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        guard !isGameOver else { return }

        if delta > 0 {
            scoreAccumulator += delta
            while scoreAccumulator >= 1.0 {
                score += 1
                scoreAccumulator -= 1.0
            }
            scoreLabel.text = "Score: \(score)"
        }

        for node in children where node.name == "asteroid" {
            if node.position.y < frame.minY - asteroidRadius * 2 {
                node.removeFromParent()
            }
        }
    }

    func didBegin(_ contact: SKPhysicsContact) {
        if isGameOver { return }

        let a = contact.bodyA.categoryBitMask
        let b = contact.bodyB.categoryBitMask
        let hitPlayer = (a == PhysicsCategory.player && b == PhysicsCategory.asteroid) ||
            (a == PhysicsCategory.asteroid && b == PhysicsCategory.player)

        if hitPlayer {
            endGame()
        }
    }

    private func endGame() {
        isGameOver = true
        removeAction(forKey: "spawn")
        playerNode.isHidden = true

        for node in children where node.name == "asteroid" {
            node.physicsBody?.velocity = .zero
            node.physicsBody?.isDynamic = false
        }

        let overlay = SKNode()
        overlay.zPosition = 100
        let backdrop = SKSpriteNode(
            color: SKColor(red: 0.02, green: 0.03, blue: 0.05, alpha: 0.88),
            size: frame.size
        )
        backdrop.position = CGPoint(x: frame.midX, y: frame.midY)
        overlay.addChild(backdrop)
        addChild(overlay)
        gameOverOverlay = overlay
        overlayBackdrop = backdrop

        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
        title.fontSize = 40
        title.fontColor = SKColor(red: 0.98, green: 0.85, blue: 0.2, alpha: 1.0)
        title.text = "Game Over"
        title.zPosition = 101
        overlay.addChild(title)
        gameOverLabel = title

        let final = SKLabelNode(fontNamed: "AvenirNext-Regular")
        final.fontSize = 22
        final.fontColor = SKColor.white
        final.text = "Score: \(score)"
        final.zPosition = 101
        overlay.addChild(final)
        finalScoreLabel = final

        let buttonWidth: CGFloat = 180
        let buttonHeight: CGFloat = 44
        let button = SKShapeNode(
            rectOf: CGSize(width: buttonWidth, height: buttonHeight),
            cornerRadius: 10
        )
        button.fillColor = SKColor(red: 0.12, green: 0.62, blue: 0.98, alpha: 1.0)
        button.strokeColor = SKColor.clear
        button.zPosition = 101
        overlay.addChild(button)
        restartButton = button

        let restart = SKLabelNode(fontNamed: "AvenirNext-Bold")
        restart.fontSize = 22
        restart.fontColor = SKColor(red: 0.92, green: 0.86, blue: 1.0, alpha: 1.0)
        restart.text = "New Game"
        restart.position = .zero
        restart.zPosition = 102
        button.addChild(restart)
        restartLabel = restart

        layoutUI()
    }

    private func restartGame() {
        for node in children where node.name == "asteroid" {
            node.removeFromParent()
        }

        gameOverOverlay?.removeFromParent()
        gameOverOverlay = nil
        overlayBackdrop = nil
        gameOverLabel = nil
        finalScoreLabel = nil
        restartLabel = nil
        restartButton = nil

        score = 0
        scoreAccumulator = 0
        lastUpdateTime = 0
        scoreLabel.text = "Score: 0"

        playerNode.position = CGPoint(x: frame.midX, y: frame.minY + playerRadius + 40)
        playerNode.isHidden = false
        isGameOver = false
        startSpawning()
    }
}
