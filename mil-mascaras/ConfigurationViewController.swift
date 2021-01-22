//
//  ConfigurationViewController.swift
//  mil-mascaras
//
//  Created by John Gallaugher on 1/22/21.
//

import UIKit

class ConfigurationViewController: UIViewController {
    
    @IBOutlet weak var changeButton: UIButton!
    @IBOutlet weak var moveButton: UIButton!
    @IBOutlet weak var addButton: UIButton!
    
    @IBOutlet weak var hostNameTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    var hostAndSounds: HostAndSounds!
    var passedBackHostsAndSounds: ((HostAndSounds) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        hostNameTextField.text = hostAndSounds.hostName
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        passedBackHostsAndSounds?(hostAndSounds)
    }
    
    func saveData() {
        let directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let documentURL = directoryURL.appendingPathComponent("hostAndSounds").appendingPathExtension("json")
        
        let jsonEncoder = JSONEncoder()
        let data = try? jsonEncoder.encode(hostAndSounds)
        do {
            try data?.write(to: documentURL, options: .noFileProtection)
        } catch {
            print("😡 ERROR: Could not save data \(error.localizedDescription)")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "AddSound":
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                tableView.deselectRow(at: selectedIndexPath, animated: true)
            }
        case "EditSound":
            let destination = segue.destination as! SoundNameViewController
            let selectedIndexPath = tableView.indexPathForSelectedRow!
            destination.soundName = hostAndSounds.sounds[selectedIndexPath.row]
        case "EditHostName":
            let destination = segue.destination as! HostNameViewController
            destination.hostName = hostAndSounds.hostName
        default:
            print("😡 ERROR: Invalid segue.identifier detected. \(segue.identifier ?? "Identifier = nil")")
        }
    }
    
    @IBAction func unwindFromHostNameViewController(segue: UIStoryboardSegue) {
        let source = segue.source as! HostNameViewController
        hostAndSounds.hostName = source.hostName
        hostNameTextField.text = hostAndSounds.hostName
        saveData()
    }
    
    @IBAction func unwindFromSoundNameViewController(segue: UIStoryboardSegue) {
        let source = segue.source as! SoundNameViewController
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            hostAndSounds.sounds[selectedIndexPath.row] = source.soundName
            tableView.reloadRows(at: [selectedIndexPath], with: .automatic)
            saveData()
        } else {
            let newIndexPath = IndexPath(row: hostAndSounds.sounds.count, section: 0)
            hostAndSounds.sounds.append(source.soundName)
            tableView.insertRows(at: [newIndexPath], with: .bottom)
            tableView.scrollToRow(at: newIndexPath, at: .bottom, animated: true)
            saveData()
        }
    }
    
    @IBAction func moveButtonPressed(_ sender: UIButton) {
        if tableView.isEditing {
            tableView.setEditing(false, animated: true)
            moveButton.setTitle("Move", for: .normal)
            addButton.isEnabled = true
            changeButton.isEnabled = true
        } else {
            tableView.setEditing(true, animated: true)
            moveButton.setTitle("Done", for: .normal)
            addButton.isEnabled = false
            changeButton.isEnabled = false
            print("changeButton.isEnabled = \(changeButton.isEnabled)")
        }
    }
    
}

extension ConfigurationViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return hostAndSounds.sounds.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! SoundNameTableViewCell
        cell.soundNumber = indexPath.row
        cell.sound = hostAndSounds.sounds[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            hostAndSounds.sounds.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.reloadData()
            saveData()
        }
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let itemToMove = hostAndSounds.sounds[sourceIndexPath.row]
        hostAndSounds.sounds.remove(at: sourceIndexPath.row)
        hostAndSounds.sounds.insert(itemToMove, at: destinationIndexPath.row)
        tableView.reloadData()
        saveData()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
}
