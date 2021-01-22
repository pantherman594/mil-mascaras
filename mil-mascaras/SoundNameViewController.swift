//
//  SoundNameViewController.swift
//  mil-mascaras
//
//  Created by John Gallaugher on 1/22/21.
//

import UIKit

class SoundNameViewController: UIViewController {
    @IBOutlet weak var soundNameTextView: UITextView!
    
    var soundName: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        soundNameTextView.text = soundName
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        soundName = soundNameTextView.text
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        let isPresentingInAddMode = presentingViewController is UINavigationController
        if isPresentingInAddMode {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
}
