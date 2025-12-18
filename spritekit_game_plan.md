# Simple 2D SpriteKit Game Plan

## Game Concept (Minimal)
A top-down “dodge the asteroids” game. The player controls a small ship that moves left/right to avoid falling asteroids. Survive as long as possible; score increases over time.

## Core Loop
- Spawn asteroids at random x positions at the top of the screen.
- Move asteroids downward at a constant speed.
- Let the player move left/right.
- If an asteroid hits the player, end the run and show final score.

## Assets (Keep Simple)
- Player: single colored square or circle (SpriteKit shape node).
- Asteroids: same as player, but smaller circles.
- Background: solid color.

## Technical Step-by-Step Implementation (SpriteKit)
1. Create a new SpriteKit project in Xcode.
2. In `GameScene.swift`, set up the scene background color in `didMove(to:)`.
3. Create a player node:
   - Use `SKShapeNode` with a simple shape.
   - Position it near the bottom center.
   - Add it to the scene.
4. Enable touch input:
   - Override `touchesMoved` (or `touchesBegan`) to update the player’s x position.
   - Clamp the x position so the player stays within the screen bounds.
5. Add physics bodies:
   - Give the player a static `SKPhysicsBody` (not affected by gravity).
   - Set `categoryBitMask` for the player.
   - Configure the scene’s `physicsWorld.contactDelegate`.
6. Create an asteroid spawn function:
   - Create an `SKShapeNode` for each asteroid.
   - Set its position at the top with a random x.
   - Give it a dynamic physics body with downward velocity.
   - Set its `categoryBitMask` and `contactTestBitMask` to detect player contact.
7. Use an `SKAction` or timer to spawn asteroids on a fixed interval (e.g., every 1 second).
8. Move asteroids downward:
   - Either set a constant velocity on the physics body.
   - Or run an `SKAction` to move to the bottom and remove the node.
9. Track score:
   - Add a score label (`SKLabelNode`).
   - Increment score each second using a timer or `update(_:)`.
10. Detect collision:
   - Implement `didBegin(_:)` in `SKPhysicsContactDelegate`.
   - If player contacts asteroid, end the game.
11. Game over:
   - Stop spawning asteroids.
   - Show a “Game Over” label and final score.
   - Optionally add a “Tap to restart” that resets the scene.

## Minimal Requirements
- One scene.
- One player node.
- One enemy type.
- One collision rule.
- One score counter.

## Validation (Truth Check)
- All steps use standard SpriteKit APIs (`SKScene`, `SKShapeNode`, `SKAction`, physics contact delegates).
- No external libraries needed.
- Uses only built-in Xcode SpriteKit template and common Swift code.
