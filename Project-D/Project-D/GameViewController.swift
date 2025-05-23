//
//  GameViewController.swift
//  Project-D
//
//  Created by Yashwanth Vanama on 4/15/25.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {
    
    var player1Name: String = ""
    var player2Name: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        if let view = self.view as! SKView? {
            /*// Load the SKScene from 'GameScene.sks'
            if let scene = SKScene(fileNamed: "GameScene") {
                // Set the scale mode to scale to fit the window
                //scene.scaleMode = .aspectFill
                
                // Present the scene
                view.presentScene(scene)
            }*/
            let scene = BoardGameScene(size: view.bounds.size)
            scene.scaleMode = .aspectFill
            scene.player1Name = player1Name
            scene.player2Name = player2Name
            view.presentScene(scene)
            
        }
        // Add Back button
        addBackButton()
    }
    
    func addBackButton() {
        let backButton = UIButton(type: .system)

        // Use SF Symbol for a back arrow
        let image = UIImage(systemName: "chevron.left")
        backButton.setImage(image, for: .normal)
        backButton.tintColor = .black // Adjust color as needed

        // Optional: Add some title text next to it
        // backButton.setTitle("Back", for: .normal)

        // Position safely below the notch
        let buttonSize: CGFloat = 40
        backButton.frame = CGRect(x: 20, y: view.safeAreaInsets.top + 20, width: buttonSize, height: buttonSize)

        // Action
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)

        // Add to view
        view.addSubview(backButton)

    }

    @objc func backButtonTapped() {
        // Go back to the previous view controller
        self.dismiss(animated: true, completion: nil)
        // Or use navigationController?.popViewController(animated: true) if using a navigation controller
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
