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
    
    private var adjacentDots: [String: [SKShapeNode]] = [:] // Maps dot names to their adjacent dots
    private var selectedPiece: SKShapeNode?
    private var movablePieces: [SKShapeNode] = []
    private var removablePieces: [SKShapeNode] = []
    
    enum Player {
        case player1
        case player2
    }

    class GameState {
        var currentPlayer: Player = .player1
        var player1Pieces: [SKShapeNode] = []
        var player2Pieces: [SKShapeNode] = []
        var piecesRemaining: [Player: Int] = [.player1: 5, .player2: 5]
        var occupiedDots: [String: Player] = [:] // Track which player occupies each dot
        var isRemovalPhase = false
        
        var gamePhase: GamePhase = .placement
            
        enum GamePhase {
            case placement
            case movement
        }
        
        // Add this to check if all pieces are placed
        func checkPhaseTransition() {
            if piecesRemaining[.player1] == 0 && piecesRemaining[.player2] == 0 {
                gamePhase = .movement
                print("Game phase changed to movement")
            }
        }
        
        var dadiFormedThisTurn = false
        var piecesCaptured: [Player: Int] = [.player1: 0, .player2: 0]
        
        func checkWinCondition() -> Player? {
            // Win if opponent has less than 3 pieces remaining
            if piecesCaptured[.player1]! > 9 {
                return .player1
            }
            if piecesRemaining[.player2]! > 9 {
                return .player2
            }
            return nil
        }
    }
    
    var gameState: GameState!
    
    override func didMove(to view: SKView) {
        backgroundColor = .white
        
        gameState = GameState()
        
        // Create game board
        createGameBoard()
        
        // Setup UI
        setupGameUI()
        
        setupAdjacentDots()
        
        // Add any other initialization code
    }
    
    // ****************************************** Players Display Logic ****************************************************************
    private func updateTurnIndicator() {
        guard let indicator = childNode(withName: "playerIndicator") as? SKLabelNode,
              let p1Counter = childNode(withName: "player1Counter") as? SKLabelNode,
              let p2Counter = childNode(withName: "player2Counter") as? SKLabelNode else { return }
        
        indicator.text = gameState.currentPlayer == .player1 ? "Player 1's Turn" : "Player 2's Turn"
        indicator.fontColor = gameState.currentPlayer == .player1 ? .blue : .red
        
        p1Counter.text = "Player 1: \(gameState.piecesRemaining[.player1]!) pieces"
        p2Counter.text = "Player 2: \(gameState.piecesRemaining[.player2]!) pieces"
    }
    
    private func setupGameUI() {
        // Current player indicator
        let playerIndicator = SKLabelNode(text: "Player 1's Turn")
        playerIndicator.name = "playerIndicator"
        playerIndicator.fontSize = 24
        playerIndicator.fontColor = .black
        playerIndicator.position = CGPoint(x: size.width/2, y: size.height - 80)
        addChild(playerIndicator)
        
        // Piece counters
        let player1Counter = SKLabelNode(text: "Player 1: 11 pieces")
        player1Counter.name = "player1Counter"
        player1Counter.fontSize = 18
        player1Counter.fontColor = .blue
        player1Counter.position = CGPoint(x: 100, y: size.height - 100)
        addChild(player1Counter)
        
        let player2Counter = SKLabelNode(text: "Player 2: 11 pieces")
        player2Counter.name = "player2Counter"
        player2Counter.fontSize = 18
        player2Counter.fontColor = .red
        player2Counter.position = CGPoint(x: size.width - 100, y: size.height - 100)
        addChild(player2Counter)
    }
    
    // *************************************** Piece Placement Logic *************************************************************
    private func createPiece(for player: Player) -> SKShapeNode {
        let piece = SKShapeNode(circleOfRadius: 10)
        piece.fillColor = player == .player1 ? .blue : .red
        piece.strokeColor = .black
        piece.lineWidth = 2
        piece.zPosition = 5 // Above dots but below UI elements
        return piece
    }
    
    private func placePiece(at dot: SKShapeNode, for player: Player) {
        guard let dotName = dot.name,
              gameState.piecesRemaining[player]! > 0,
              gameState.occupiedDots[dotName] == nil else { return }
        
        // Create and position the piece
        let piece = createPiece(for: player)
        piece.position = dot.position
        piece.name = dot.name
        dot.parent?.addChild(piece) // Add to dot's parent (the rectangle)
        
        // Update game state
        if player == .player1 {
            gameState.player1Pieces.append(piece)
        } else {
            gameState.player2Pieces.append(piece)
        }
        gameState.piecesRemaining[player]! -= 1
        gameState.occupiedDots[dotName] = player
        
        let isDadi = checkForDadi(piece, player: gameState.currentPlayer)
        if (isDadi) {
            onDadiFormed(for: gameState.currentPlayer)
        }
        else {
            // Switch turns
            gameState.currentPlayer = (player == .player1) ? .player2 : .player1
            updateTurnIndicator()
            gameState.checkPhaseTransition()
            
            if gameState.gamePhase == .movement {
                highlightMovablePieces(for: gameState.currentPlayer)
            }
        }
    }
    
    // **************************************** Game Board Setup Logic ************************************************************
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
            addDotsToRectangle(rect: rect)
        }
        
        connectRectangles(outerRect: rectangles[0], innerRect: rectangles[1])
        connectRectangles(outerRect: rectangles[1], innerRect: rectangles[2])
    }
    
    private func addDotsToRectangle(rect: SKShapeNode) {
        guard let rectSize = rect.path?.boundingBox.size else { return }
        
        let dotRadius: CGFloat = 7
        let dotPositions: [CGPoint] = [
            // Corners
            CGPoint(x: -rectSize.width/2, y: rectSize.height/2),    // Top-left
            CGPoint(x: -rectSize.width/2, y: 0),                     // Left center
            CGPoint(x: -rectSize.width/2, y: -rectSize.height/2),   // Bottom-left
            CGPoint(x: 0, y: -rectSize.height/2),                   // Bottom center
            CGPoint(x: rectSize.width/2, y: -rectSize.height/2),    // Bottom-right
            CGPoint(x: rectSize.width/2, y: 0),                     // Right center
            CGPoint(x: rectSize.width/2, y: rectSize.height/2),     // Top-right
            CGPoint(x: 0, y: rectSize.height/2)                    // Top center
            
            
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
        
    }
    
    //*********************************************** Piece Movement Logic ****************************************************************
    
    private func setupAdjacentDots() {
        adjacentDots.removeAll()
        
        // Create a dictionary to quickly find dots by name
        var dotDictionary = [String: SKShapeNode]()
        for dot in dots {
            if let name = dot.name {
                dotDictionary[name] = dot
            }
        }
        
        for dot in dots {
            guard let dotName = dot.name else { continue }
            
            // Parse the dot name "dot_rectangle_index"
            let components = dotName.components(separatedBy: "_")
            guard components.count == 3,
                  let rectangle = Int(components[1]),
                  let index = Int(components[2]) else {
                continue
            }
            
            var adjacentDotNames = [String]()
            
            // Calculate same-rectangle adjacents (for both corners and centers)
            let adjacentIndex1 = (index + 7) % 8
            let adjacentIndex2 = (index + 9) % 8
            adjacentDotNames.append("dot_\(rectangle)_\(adjacentIndex1)")
            adjacentDotNames.append("dot_\(rectangle)_\(adjacentIndex2)")
            
            // For center dots (even index), add cross-rectangle adjacents
            if index % 2 == 1 {
                if rectangle == 0 {  // Outer rectangle
                    // Connect to middle rectangle (rectangle +1)
                    adjacentDotNames.append("dot_\(rectangle + 1)_\(index)")
                }
                else if rectangle == 1 {  // Middle rectangle
                    // Connect to both outer and inner
                    adjacentDotNames.append("dot_\(rectangle - 1)_\(index)")  // Outer
                    adjacentDotNames.append("dot_\(rectangle + 1)_\(index)")  // Inner
                }
                else if rectangle == 2 {  // Inner rectangle
                    // Connect to middle rectangle (rectangle -1)
                    adjacentDotNames.append("dot_\(rectangle - 1)_\(index)")
                }
            }
            
            // Filter out invalid dot names and get the actual dot nodes
            let validAdjacentDots = adjacentDotNames.compactMap { dotDictionary[$0] }
            adjacentDots[dotName] = validAdjacentDots
            
        }
    }
    
    private func resetHighlights() {
        movablePieces.removeAll()
        children.filter { $0.name?.hasPrefix("highlight_") == true }.forEach {
            $0.removeFromParent()
        }
    }
    
    private func highlightMovablePieces(for player: Player) {
        // Reset all highlights
        resetHighlights()
        
        // Find all pieces belonging to current player that can move
        let playerPieces = (player == .player1) ? gameState.player1Pieces : gameState.player2Pieces
        
        for piece in playerPieces {
            // Find the dot this piece is on
            if let dot = dots.first(where: { $0.frame.contains(piece.position) }),
               let dotName = dot.name,
               let adjacent = adjacentDots[dotName] {
                
                // Check if any adjacent dot is unoccupied
                let hasVacantAdjacent = adjacent.contains { adjacentDot in
                    guard let adjacentDotName = adjacentDot.name else { return false }
                    return gameState.occupiedDots[adjacentDotName] == nil
                }
                
                if hasVacantAdjacent {
                    // Highlight this piece as movable
                    let highlight = SKShapeNode(circleOfRadius: 15)
                    highlight.fillColor = .clear
                    highlight.strokeColor = .black
                    highlight.lineWidth = 3
                    highlight.position = piece.parent?.convert(piece.position, to: self) ?? piece.position
                    highlight.name = "highlight_\(piece.hash)"
                    addChild(highlight)
                    movablePieces.append(piece)
                }
            }
        }
        
    }
    
    private func showAvailableMoves(for piece: SKShapeNode) {
        // Find the current dot
        resetMoveIndicators()
        selectedPiece = piece
        guard let currentDot = dots.first(where: { $0.frame.contains(piece.position) }),
              let currentDotName = currentDot.name,
              let adjacent = adjacentDots[currentDotName] else { return }
        
        // Highlight available adjacent dots
        for dot in adjacent {
            guard let dotName = dot.name,
                  gameState.occupiedDots[dotName] == nil else { continue }
            
            let moveIndicator = SKShapeNode(circleOfRadius: 10)
            moveIndicator.fillColor = .green
            moveIndicator.strokeColor = .white
            moveIndicator.lineWidth = 2
            moveIndicator.position = dot.parent?.convert(dot.position, to: self) ?? dot.position
            moveIndicator.name = "moveIndicator_\(dotName)"
            moveIndicator.zPosition = 5
            addChild(moveIndicator)
        }
    }
    
    //*********************************************** Touches Began Logic *****************************************************************
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       
        // Debug all nodes at touch location
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        if gameState.isRemovalPhase {
            handleRemovalPhaseTouch(at: location)
            return
        }
        
        switch gameState.gamePhase {
            case .placement:
                handlePlacementPhaseTouch(at: location)
            case .movement:
                handleMovementPhaseTouch(at: location)
            }
    }
    
    private func handlePlacementPhaseTouch(at location: CGPoint) {
        // Check if a dot was touched
        for dot in dots {
            if let parent = dot.parent {
                let dotPositionInScene = parent.convert(dot.position, to: self)
                let distance = hypot(dotPositionInScene.x - location.x, dotPositionInScene.y - location.y)
                
                if distance < dot.frame.width/2 * 1.5 { // 1.5x radius for easier touching
                    // Visual feedback
                    dot.run(SKAction.sequence([
                        SKAction.scale(to: 1.3, duration: 0.1),
                        SKAction.scale(to: 1.0, duration: 0.1)
                    ]))
                    
                    // Handle piece placement
                    placePiece(at: dot, for: gameState.currentPlayer)
                    break
                }
            }
        }
        
    }
    
    private func handleMovementPhaseTouch(at location: CGPoint) {
        // Check if tapping a valid move location
        if let piece = selectedPiece,
                let moveIndicator = nodes(at: location).first(where: { $0.name?.hasPrefix("moveIndicator_") == true }) {
            // Move the piece
            movePiece(piece, to: moveIndicator.position)
            selectedPiece = nil
        }
        else {
            // Deselect if tapping elsewhere
            selectedPiece = nil
            resetMoveIndicators()
            for piece in movablePieces {
                let piecePosition = piece.parent?.convert(piece.position, to: self) ?? piece.position
                let distance = hypot(piecePosition.x - location.x, piecePosition.y - location.y)
                
                if distance < 20 { // Adjust this threshold to your piece size
                    // Clear any existing move indicators
                    //resetMoveIndicators()
                    
                    // Show available moves for this piece
                    showAvailableMoves(for: piece)
                    return
                }
            }
            highlightMovablePieces(for: gameState.currentPlayer)
        }
    }
    
    private func movePiece(_ piece: SKShapeNode, to position: CGPoint) {
        // Convert all positions to scene coordinates for accurate comparison
        let scenePosition = piece.parent?.convert(piece.position, to: self) ?? piece.position
        
        // Find old dot (where piece currently is)
        guard let oldDot = dots.first(where: { dot in
            let dotPosInScene = dot.parent?.convert(dot.position, to: self) ?? dot.position
            let distance = hypot(dotPosInScene.x - scenePosition.x, dotPosInScene.y - scenePosition.y)
            return distance < 20 // Adjust based on your dot size
        }), let oldDotName = oldDot.name else {
            print("Error: Couldn't find old dot for piece at \(scenePosition)")
            return
        }
        
        // Find new dot (target position)
        guard let newDot = dots.first(where: { dot in
            let dotPosInScene = dot.parent?.convert(dot.position, to: self) ?? dot.position
            let distance = hypot(dotPosInScene.x - position.x, dotPosInScene.y - position.y)
            return distance < 20 // Adjust based on your dot size
        }), let newDotName = newDot.name else {
            print("Error: Couldn't find new dot at target position \(position)")
            return
        }
        
        
        // Update game state
        gameState.occupiedDots[oldDotName] = nil
        gameState.occupiedDots[newDotName] = gameState.currentPlayer
        piece.name = newDotName
        
        // Animate movement
        let moveAction = SKAction.move(to: newDot.position, duration: 0.2)
        moveAction.timingMode = .easeOut
        piece.run(moveAction)
        
        let isDadi = checkForDadi(piece, player: gameState.currentPlayer)
        if (isDadi) {
            resetMoveIndicators()
            resetHighlights()
            onDadiFormed(for: gameState.currentPlayer)
        }
        else {
            // Clean up and switch turns
            resetMoveIndicators()
            resetHighlights()
            
            // Switch players
            gameState.currentPlayer = (gameState.currentPlayer == .player1) ? .player2 : .player1
            updateTurnIndicator()
            
            // Highlight movable pieces for new player
            highlightMovablePieces(for: gameState.currentPlayer)
        }
    }
    
    private func resetMoveIndicators() {
        children.filter { $0.name?.hasPrefix("moveIndicator_") == true }.forEach {
            $0.removeFromParent()
        }
    }

    // **************************************** Dadi Logic ****************************************
    
    private func checkForDadi(_ piece: SKShapeNode, player: Player) -> Bool {
        guard let pieceName = piece.name,
              pieceName.components(separatedBy: "_").count == 3 else {
            return false
        }
        
        // Extract components with proper error handling
        let components = pieceName.components(separatedBy: "_")
        guard components.count == 3 else {
            return false
        }
        
        // Get the components without optional binding since they're guaranteed to exist
        guard let rectangleNum = Int(components[1]) else {
            return false
        }// This is now safe because we checked count == 3
        guard let indexNum = Int(components[2]) else {
            return false
        }
        if indexNum % 2 == 0 {
            // Calculate adjacent positions safely
            let nextPos1 = (indexNum + 1) % 8
            let nextPos2 = (indexNum + 2) % 8
            let prevPos1 = (indexNum - 1 + 8) % 8  // +8 before % to avoid negative numbers
            let prevPos2 = (indexNum - 2 + 8) % 8
            
            // Check both directions
            let forwardDadi = isOccupiedByPlayer("dot_\(rectangleNum)_\(nextPos1)", player: player) &&
                             isOccupiedByPlayer("dot_\(rectangleNum)_\(nextPos2)", player: player)
            
            let backwardDadi = isOccupiedByPlayer("dot_\(rectangleNum)_\(prevPos1)", player: player) &&
                              isOccupiedByPlayer("dot_\(rectangleNum)_\(prevPos2)", player: player)
            
            return forwardDadi || backwardDadi
        }
        else{
            // Calculate adjacent positions safely
            let nextPos1 = (indexNum + 1) % 8
            let nextPos2 = (indexNum - 1 + 8) % 8
            let rectPos1 = (rectangleNum + 1) % 3  // +8 before % to avoid negative numbers
            let rectPos2 = (rectangleNum + 2) % 3
            
            // Check both directions
            let forwardDadi = isOccupiedByPlayer("dot_\(rectangleNum)_\(nextPos1)", player: player) &&
                             isOccupiedByPlayer("dot_\(rectangleNum)_\(nextPos2)", player: player)
            
            let backwardDadi = isOccupiedByPlayer("dot_\(rectPos1)_\(indexNum)", player: player) &&
            isOccupiedByPlayer("dot_\(rectPos2)_\(indexNum)", player: player)
            
            return forwardDadi || backwardDadi
        }
    }
    
    private func isOccupiedByPlayer(_ dotName: String, player: Player) -> Bool {
        return gameState.occupiedDots[dotName] == player
    }
    
    
    private func showDadiFormedMessage() {
        // Remove any existing message first
        removeDadiMessage()
        
        // Create message label
        let message = SKLabelNode(text: "DADI FORMED! Select opponent's piece to remove")
        message.fontName = "Avenir-Bold"
        message.fontColor = .red
        message.horizontalAlignmentMode = .center
        message.position = CGPoint(x: size.width/2, y: 50) // Bottom center
        message.zPosition = 100
        message.name = "dadiMessage"
        
        // Calculate dynamic font size based on screen width
        let baseFontSize: CGFloat = 24
        let minFontSize: CGFloat = 12
        let maxFontSize: CGFloat = 36
        let targetWidth = size.width * 0.9 // Use 90% of screen width
        
        // Adjust font size to fit
        var fontSize = baseFontSize
        var textWidth: CGFloat = 0
        
        repeat {
            message.fontSize = fontSize
            textWidth = message.frame.width
            if textWidth > targetWidth {
                fontSize -= 1
            }
        } while textWidth > targetWidth && fontSize > minFontSize
        
        // Ensure we don't go below minimum size
        message.fontSize = max(fontSize, minFontSize)
        // And don't exceed maximum size
        message.fontSize = min(message.fontSize, maxFontSize)
        
        // Add pulsing animation
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])
        message.run(SKAction.repeatForever(pulse))
        
        // Add to scene
        addChild(message)
    }
    // Also add this to clean up when done
    private func removeDadiMessage() {
        childNode(withName: "dadiMessage")?.removeFromParent()
    }
    
    // ************************************************************* Piece Removal Logic ***************************************************
    
    private func highlightRemovableOpponentPieces(for currentPlayer: Player) {
        resetHighlights()
        
        let opponent: Player = (currentPlayer == .player1) ? .player2 : .player1
        let opponentPieces = (opponent == .player1) ? gameState.player1Pieces : gameState.player2Pieces
        
        for piece in opponentPieces {
            if checkForDadi(piece, player: opponent) {
                continue
            }
            let highlight = SKShapeNode(circleOfRadius: 15)
            highlight.fillColor = .clear
            highlight.strokeColor = .systemRed // Different color for removable pieces
            highlight.lineWidth = 3
            highlight.position = piece.parent?.convert(piece.position, to: self) ?? piece.position
            highlight.name = "Removable_highlight_\(piece.hash)"
            highlight.zPosition = piece.zPosition + 1
            addChild(highlight)
            removablePieces.append(piece)
        }
    }
    
    private func handleRemovalPhaseTouch(at location: CGPoint) {
        // Find if a removable piece was tapped
        
        for piece in removablePieces {
            let piecePosition = piece.parent?.convert(piece.position, to: self) ?? piece.position
            let distance = hypot(piecePosition.x - location.x, piecePosition.y - location.y)
            
            if distance < 20 { // Adjust this threshold to your piece size
                // Clear any existing move indicators
                //resetMoveIndicators()
                
                // Show available moves for this piece
                removeOpponentPiece(piece)
                return
            }
        }
        // If tap wasn't on a removable piece, show error feedback
        showInvalidSelectionFeedback(at: location)
    }
    
    private func removeOpponentPiece(_ piece: SKShapeNode) {
        // Determine which player this piece belongs to
        let isPlayer1Piece = gameState.player1Pieces.contains(piece)
        //let opponent: Player = isPlayer1Piece ? .player1 : .player2
        
        // Update game state
        if isPlayer1Piece {
            if let index = gameState.player1Pieces.firstIndex(of: piece) {
                gameState.player1Pieces.remove(at: index)
            }
        } else {
            if let index = gameState.player2Pieces.firstIndex(of: piece) {
                gameState.player2Pieces.remove(at: index)
            }
        }
        
        // Find and clear the occupied dot
        if let dot = dots.first(where: { $0.frame.contains(piece.position) }),
           let dotName = dot.name {
            gameState.occupiedDots[dotName] = nil
        }
        
        // Animate removal
        piece.run(SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.1),
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent()
        ]))
        
        // Clear highlights and end removal phase
        resetRemovableHighlights()
        removeDadiMessage()
        gameState.isRemovalPhase = false
        
        // Check win condition
        if gameState.gamePhase == .placement {
            // Switch turns
            gameState.currentPlayer = (gameState.currentPlayer == .player1) ? .player2 : .player1
            updateTurnIndicator()
            gameState.checkPhaseTransition()
            
            if gameState.gamePhase == .movement {
                highlightMovablePieces(for: gameState.currentPlayer)
            }

        }
        else {
            if let winner = checkWinCondition() {
                showGameOver(winner: winner)
            } else {
                // Switch turns
                gameState.currentPlayer = (gameState.currentPlayer == .player1) ? .player2 : .player1
                updateTurnIndicator()
                
                // If in movement phase, highlight movable pieces
                if gameState.gamePhase == .movement {
                    highlightMovablePieces(for: gameState.currentPlayer)
                }
            }
        }
    }
    
    private func showInvalidSelectionFeedback(at position: CGPoint) {
        let feedback = SKLabelNode(text: "Select opponent's piece!")
        feedback.fontColor = .red
        feedback.fontSize = 24
        feedback.position = position
        feedback.zPosition = 1000
        addChild(feedback)
        
        feedback.run(SKAction.sequence([
            SKAction.wait(forDuration: 1),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
    }

    // 6. Update your Dadi check to start removal phase
    private func onDadiFormed(for player: Player) {
        gameState.isRemovalPhase = true
        highlightRemovableOpponentPieces(for: player)
        showDadiFormedMessage()
    }
    
    private func resetRemovableHighlights() {
        // Remove all highlight nodes
        movablePieces.removeAll()
        children.filter { $0.name?.hasPrefix("Removable_highlight_") == true }.forEach {
            $0.removeFromParent()
        }
    }
    
    
    //********************************************************** Game Completion and restart Logic ************************************************************
    
    private func restartGame() {
        // Create new scene to restart game
        if let scene = SKScene(fileNamed: "GameScene") {
            scene.scaleMode = .aspectFill
            view?.presentScene(scene, transition: SKTransition.flipHorizontal(withDuration: 0.5))
        }
    }
    
    private func showGameOver(winner: Player) {
        // Create game over background
        let background = SKShapeNode(rectOf: CGSize(width: size.width * 0.7, height: size.height * 0.3))
        background.fillColor = UIColor(white: 0, alpha: 0.7)
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.zPosition = 100
        
        // Create winner text
        let winnerText = SKLabelNode(text: "\(winner == .player1 ? "Player 1" : "Player 2") Wins!")
        winnerText.fontName = "Avenir-Bold"
        winnerText.fontSize = 48
        winnerText.fontColor = winner == .player1 ? .blue : .red
        winnerText.position = CGPoint(x: 0, y: 20)
        winnerText.zPosition = 101
        
        // Create restart button
        let restartButton = SKLabelNode(text: "Play Again")
        restartButton.fontName = "Avenir-Medium"
        restartButton.fontSize = 36
        restartButton.fontColor = .white
        restartButton.position = CGPoint(x: 0, y: -50)
        restartButton.name = "restartButton"
        restartButton.zPosition = 101
        
        // Add elements to background
        background.addChild(winnerText)
        background.addChild(restartButton)
        
        // Add to scene with animation
        background.alpha = 0
        addChild(background)
        background.run(SKAction.fadeIn(withDuration: 0.5))
        
        // Disable further moves
        isUserInteractionEnabled = false
    }
    
    private func checkWinCondition() -> Player? {
        // Player wins if opponent has less than 3 pieces remaining
        if gameState.player2Pieces.count < 3 {
            return .player1
        }
        if gameState.player1Pieces.count < 3 {
            return .player2
        }
        return nil
    }
}
