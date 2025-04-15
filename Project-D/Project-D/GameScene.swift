//
//  GameScene.swift
//  Project-D
//
//  Created by Yashwanth Vanama on 4/15/25.
//

/*import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    
    override func didMove(to view: SKView) {
        
        // Get label node from scene and store it for use later
        self.label = self.childNode(withName: "//helloLabel") as? SKLabelNode
        if let label = self.label {
            label.alpha = 0.0
            label.run(SKAction.fadeIn(withDuration: 2.0))
        }
        
        // Create shape node to use during mouse interaction
        let w = (self.size.width + self.size.height) * 0.05
        self.spinnyNode = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w), cornerRadius: w * 0.3)
        
        if let spinnyNode = self.spinnyNode {
            spinnyNode.lineWidth = 2.5
            
            spinnyNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
            spinnyNode.run(SKAction.sequence([SKAction.wait(forDuration: 0.5),
                                              SKAction.fadeOut(withDuration: 0.5),
                                              SKAction.removeFromParent()]))
        }
    }
    
    
    func touchDown(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.green
            self.addChild(n)
        }
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.blue
            self.addChild(n)
        }
    }
    
    func touchUp(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.red
            self.addChild(n)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let label = self.label {
            label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
        }
        
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
*/
import SpriteKit
import GameplayKit

class GameScene: SKScene {

    var cornerLabels: [SKLabelNode] = []

    override func didMove(to view: SKView) {
        backgroundColor = .white
        drawRectangleWithCorners()
    }

    func drawRectangleWithCorners() {
        let path = CGMutablePath()
        path.addRect(CGRect(x: -30, y: -15, width: 60, height: 90)) // Draws a rectangle centered at (0,0)

        let rectangle = SKShapeNode(path: path)
        rectangle.lineWidth = 1
        rectangle.strokeColor = .black
        rectangle.glowWidth = 0.5
        addChild(rectangle)
        
        let path1 = CGMutablePath()
        path1.addRect(CGRect(x: -60, y: -45, width: 120, height: 150))
        
        let rectangle1 = SKShapeNode(path: path1)
        rectangle1.lineWidth = 1
        rectangle1.strokeColor = .black
        rectangle1.glowWidth = 0.5
        addChild(rectangle1)
        
        let path2 = CGMutablePath()
        path2.addRect(CGRect(x: -90, y: -75, width: 180, height: 210))
        
        let rectangle2 = SKShapeNode(path: path2)
        rectangle2.lineWidth = 1
        rectangle2.strokeColor = .black
        rectangle2.glowWidth = 0.5
        addChild(rectangle2)
        
        // Coordinates of the rectangles (based on your sizes and center)
        let inner = CGRect(x: -30, y: -15, width: 60, height: 90)
        let middle = CGRect(x: -60, y: -45, width: 120, height: 150)
        let outer = CGRect(x: -90, y: -75, width: 180, height: 210)

        // Midpoints of sides and corners
        let points: [CGPoint] = [
            CGPoint(x: inner.minX, y: inner.minY), // bottom-left
            CGPoint(x: inner.maxX, y: inner.minY), // bottom-right
            CGPoint(x: inner.minX, y: inner.maxY), // top-left
            CGPoint(x: inner.maxX, y: inner.maxY), // top-right
            CGPoint(x: inner.midX, y: inner.minY), // bottom-center
            CGPoint(x: inner.midX, y: inner.maxY), // top-center
            CGPoint(x: inner.minX, y: inner.midY), // left-center
            CGPoint(x: inner.maxX, y: inner.midY)  // right-center
        ]

        // Draw lines from inner → middle → outer
        for point in points {
            let scaleToMiddle = CGPoint(
                x: point.x * 2,
                y: point.y * 2
            )
            let scaleToOuter = CGPoint(
                x: point.x * 3,
                y: point.y * 3
            )
            connectPoints(from: point, to: scaleToMiddle)
            connectPoints(from: scaleToMiddle, to: scaleToOuter)
        }
    }
    
    func connectPoints(from: CGPoint, to: CGPoint) {
        let connectionPath = CGMutablePath()
        connectionPath.move(to: from)
        connectionPath.addLine(to: to)
        
        let connection = SKShapeNode(path: connectionPath)
        connection.strokeColor = .black
        connection.lineWidth = 1
        addChild(connection)
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        for label in cornerLabels {
            if label.contains(location) {
                label.text = "0"
            }
        }
    }
}

