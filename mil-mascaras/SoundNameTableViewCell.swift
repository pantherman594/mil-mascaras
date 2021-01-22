//
//  SoundNameTableViewCell.swift
//  mil-mascaras
//
//  Created by John Gallaugher on 1/22/21.
//

import UIKit

class SoundNameTableViewCell: UITableViewCell {
    @IBOutlet weak var soundNameLabel: UILabel!
    @IBOutlet weak var soundMessageLabel: UILabel!
    
    var soundNumber: Int!
    var sound: String! {
        didSet {
            soundNameLabel.text = "\(soundNumber!).mp3"
            soundMessageLabel.text = sound
        }
    }
}
