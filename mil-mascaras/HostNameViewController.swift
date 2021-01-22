//
//  HostNameViewController.swift
//  mil-mascaras
//
//  Created by John Gallaugher on 1/22/21.
//

import UIKit

class HostNameViewController: UIViewController {
    @IBOutlet weak var hostNameTextField: UITextField!
    
    var hostName: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        hostNameTextField.text = hostName
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        hostName = hostNameTextField.text
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
