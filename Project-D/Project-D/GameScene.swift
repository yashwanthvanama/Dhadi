//
//  GameScene.swift
//  Project-D
//
//  Created by Yashwanth Vanama on 4/15/25.
//

import SpriteKit
import GameplayKit

class BoardGameScene: SKScene {
    private var rectangles: [SKShapeNode] = []
    private var connectionLines: [SKShapeNode] = []
    private var dots: [SKShapeNode] = []
    
    // Colors
    private let rectangleColor = UIColor(red: 0.9, green: 0.8, blue: 0.7, alpha: 1.0)
    private let lineColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
    private let dotColor = UIColor.green
    private let selectedDotColor = UIColor.red
    
    override func didMove(to view: SKView) {
        backgroundColor = .white
        createGameBoard()
    }
    
    private func createGameBoard() {
        // Clear any existing elements
        rectangles.forEach { $0.removeFromParent() }
        connectionLines.forEach { $0.removeFromParent() }
        dots.forEach { $0.removeFromParent() }
        rectangles.removeAll()
        connectionLines.removeAll()
        dots.removeAll()
        
        // Create 3 rectangles
        let rectSizes = [
            CGSize(width: size.width * 0.8, height: size.height * 0.7),
            CGSize(width: size.width * 0.6, height: size.height * 0.55),
            CGSize(width: size.width * 0.4, height: size.height * 0.4)
        ]
        let rectPositions = [
            CGPoint(x: size.width * 0.5, y: size.height * 0.5),
            CGPoint(x: size.width * 0.5, y: size.height * 0.5),
            CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        ]
        
        for (index, (size, position)) in zip(rectSizes, rectPositions).enumerated() {
            let rect = SKShapeNode(rectOf: size, cornerRadius: 10)
            rect.fillColor = rectangleColor
            rect.strokeColor = .darkGray
            rect.lineWidth = 2
            rect.position = position
            rect.name = "rectangle_\(index)"
            addChild(rect)
            rectangles.append(rect)
            
            // Add dots to each rectangle (pawn positions)
            //addDotsToRectangle(rect: rect)
        }
        
        connectRectangles(outerRect: rectangles[0], innerRect: rectangles[1])
        connectRectangles(outerRect: rectangles[1], innerRect: rectangles[2])
    }
    
    private func addDotsToRectangle(rect: SKShapeNode) {
        guard let rectSize = rect.path?.boundingBox.size else { return }
        
        let dotRadius: CGFloat = 8
        let dotPositions: [CGPoint] = [
            // Corners
            CGPoint(x: -rectSize.width/2, y: rectSize.height/2),    // Top-left
            CGPoint(x: rectSize.width/2, y: rectSize.height/2),     // Top-right
            CGPoint(x: rectSize.width/2, y: -rectSize.height/2),    // Bottom-right
            CGPoint(x: -rectSize.width/2, y: -rectSize.height/2),   // Bottom-left
            
            // Centers of sides
            CGPoint(x: 0, y: rectSize.height/2),                    // Top center
            CGPoint(x: rectSize.width/2, y: 0),                     // Right center
            CGPoint(x: 0, y: -rectSize.height/2),                   // Bottom center
            CGPoint(x: -rectSize.width/2, y: 0)                     // Left center
        ]
        
        for (index, position) in dotPositions.enumerated() {
            let dot = SKShapeNode(circleOfRadius: dotRadius)
            dot.fillColor = dotColor
            dot.strokeColor = .darkGray
            dot.lineWidth = 1
            dot.name = "dot_\(rect.name?.replacingOccurrences(of: "rectangle_", with: "") ?? "0")_\(index)"
            dot.zPosition = 1
            dot.position = position
            rect.addChild(dot)
            dots.append(dot)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Check if a dot was touched
        for dot in dots {
            if let parent = dot.parent {
                let dotPositionInScene = parent.convert(dot.position, to: self)
                if abs(dotPositionInScene.x - location.x) < 15 && abs(dotPositionInScene.y - location.y) < 15 {
                    // Dot was tapped - change its color to indicate selection
                    dot.fillColor = (dot.fillColor == dotColor) ? selectedDotColor : dotColor
                    
                    // Add visual feedback
                    let scaleAction = SKAction.sequence([
                        SKAction.scale(to: 1.3, duration: 0.1),
                        SKAction.scale(to: 1.0, duration: 0.1)
                    ])
                    dot.run(scaleAction)
                    
                    // Here you would add your game logic for pawn placement
                    return
                }
            }
        }
    }
        
    
    // Example pawn placement function
    private func placePawn(at position: CGPoint, player: Int) {
        let pawn = SKShapeNode(circleOfRadius: 10)
        pawn.fillColor = player == 1 ? .blue : .red
        pawn.strokeColor = .black
        pawn.lineWidth = 1.5
        pawn.position = position
        pawn.zPosition = 2
        addChild(pawn)
    }
    
    private func connectRectangles(outerRect: SKShapeNode, innerRect: SKShapeNode) {
        // Clear any existing connection lines between these rectangles
        //connectionLines.forEach { $0.removeFromParent() }
        //connectionLines.removeAll()
        
        // Get the sizes of both rectangles
        guard let outerSize = outerRect.path?.boundingBox.size,
              let innerSize = innerRect.path?.boundingBox.size else { return }
        
        // Define the connection points for all four sides
        let outerPoints = [
            CGPoint(x: 0, y: outerSize.height/2),           // Top center (outer)
            CGPoint(x: outerSize.width/2, y: 0),            // Right center (outer)
            CGPoint(x: 0, y: -outerSize.height/2),          // Bottom center (outer)
            CGPoint(x: -outerSize.width/2, y: 0)            // Left center (outer)
        ]
        
        let innerPoints = [
            CGPoint(x: 0, y: innerSize.height/2),           // Top center (inner)
            CGPoint(x: innerSize.width/2, y: 0),            // Right center (inner)
            CGPoint(x: 0, y: -innerSize.height/2),          // Bottom center (inner)
            CGPoint(x: -innerSize.width/2, y: 0)            // Left center (inner)
        ]
        
        // Create connection lines for all four sides
        for i in 0..<4 {
            let line = SKShapeNode()
            let path = CGMutablePath()
            
            // Convert points to scene coordinates
            let outerPointInScene = outerRect.convert(outerPoints[i], to: self)
            let innerPointInScene = innerRect.convert(innerPoints[i], to: self)
            
            path.move(to: outerPointInScene)
            path.addLine(to: innerPointInScene)
            
            line.path = path
            line.strokeColor = .darkGray
            line.lineWidth = 2
            line.zPosition = 0.5
            
            addChild(line)
            connectionLines.append(line)
        }
        
        // Add visual markers at connection points (optional)
        addConnectionMarkers(outerRect: outerRect, innerRect: innerRect)
    }
    
    private func addConnectionMarkers(outerRect: SKShapeNode, innerRect: SKShapeNode) {
        // Get the sizes of both rectangles
        guard let outerSize = outerRect.path?.boundingBox.size,
              let innerSize = innerRect.path?.boundingBox.size else { return }
        
        // Define marker positions for all four sides
        let positions = [
            (CGPoint(x: 0, y: outerSize.height/2), CGPoint(x: 0, y: innerSize.height/2)),   // Top
            (CGPoint(x: outerSize.width/2, y: 0), CGPoint(x: innerSize.width/2, y: 0)),      // Right
            (CGPoint(x: 0, y: -outerSize.height/2), CGPoint(x: 0, y: -innerSize.height/2)),  // Bottom
            (CGPoint(x: -outerSize.width/2, y: 0), CGPoint(x: -innerSize.width/2, y: 0))    // Left
        ]
        
        for (outerPos, innerPos) in positions {
            let outerMarker = createConnectionMarker(at: outerPos, parent: outerRect)
            let innerMarker = createConnectionMarker(at: innerPos, parent: innerRect)
            addChild(outerMarker)
            addChild(innerMarker)
        }
    }

    private func createConnectionMarker(at position: CGPoint, parent: SKShapeNode) -> SKShapeNode {
        let marker = SKShapeNode(circleOfRadius: 4)
        marker.fillColor = lineColor
        marker.strokeColor = .white
        marker.lineWidth = 1
        marker.position = parent.convert(position, to: self)
        marker.zPosition = 0
        return marker
    }
}
