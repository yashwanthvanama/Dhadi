//
//  MenuViewController.swift
//  Project-D
//
//  Created by Yashwanth Vanama on 5/16/25.
//

import UIKit

class MenuViewController: UIViewController {
    @IBOutlet weak var player1Field: UITextField!
    @IBOutlet weak var player2Field: UITextField!

    @IBAction func startGameTapped(_ sender: UIButton) {
        // 1. Grab the names
        guard let name1 = player1Field.text, !name1.trimmingCharacters(in: .whitespaces).isEmpty else {
            showAlert(message: "Please enter Player 1’s name.")
            return
          }
          guard let name2 = player2Field.text, !name2.trimmingCharacters(in: .whitespaces).isEmpty else {
            showAlert(message: "Please enter Player 2’s name.")
            return
          }

        // 2. Instantiate GameViewController (which hosts your SKView)
        guard let gameVC = storyboard?.instantiateViewController(
                withIdentifier: "GameViewController"
              ) as? GameViewController else {
            return
        }

        // 3. Pass names along
        gameVC.player1Name = name1
        gameVC.player2Name = name2
        // 4. Present (or push, if you’re in a nav controller)
        gameVC.modalPresentationStyle = .fullScreen
        present(gameVC, animated: true)
    }
    
    private func showAlert(message: String) {
      let alert = UIAlertController(
        title: "Oops!",
        message: message,
        preferredStyle: .alert
      )
      alert.addAction(UIAlertAction(title: "OK", style: .default))
      present(alert, animated: true)
    }
    
    override func viewDidLoad() {
      super.viewDidLoad()

      // existing setup…
      let tap = UITapGestureRecognizer(
        target: self,
        action: #selector(dismissKeyboard)
      )
      tap.cancelsTouchesInView = false    // so buttons still receive taps
      view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
      view.endEditing(true)
    }

}
