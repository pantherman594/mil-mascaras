//
//  ViewController.swift
//  mil-mascaras
//
//  Created by John Gallaugher on 1/21/21.
//

// If your pi's hostname is something different than "mil-mascaras", see comments below the line labeled *** IMPORTANT *** below.

import UIKit
import CocoaMQTT

class ViewController: UIViewController {
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var tableView: UITableView!
    
    var hostAndSounds = HostAndSounds()
    var stop = "stop"
    let initialHostName = "mil-mascaras"
    let initialSounds = ["I'm Mil Mascaras - robot of a thousand masks. And I'd like you to take one and put it on. Thanks!",
                         "Hello friend. Masks are required. Take one if you need one, and thank you!",
                         "I've got a mask for you. Please take one and put it on",
                         "If you want to hang out here, then you've got to wear a mask",
                         "Please take a mask. They're free and they keep us safe",
                         "Looks like you could use a mask. Take one. Be safe my friend.",
                         "Don't you look great in your mask. Nice job!",
                         "Look at you rockin' the mask. Nice work!",
                         "You look so good in that mask. Thanks for helping!",
                         "Dude. What's wrong with you_ The mask goes over your nose"]
// To add the phrases below, remove the ] above, add a comma to the end of that line, then uncomment the lines below.
//                         ,"Hey - COVID bro! It's time to mask up!",
//                         "Yo - plague princess - can you wear a mask_ Take one if you need one"]
    
    var direction: [Int: String] = [0: "forward",
                                    1: "backward",
                                    2: "left",
                                    3: "right"]
    
    // *** IMPORTANT ***
    // If your Pi's host name is NOT mil-mascaras, then be sure to update the line below with the correct hostname.
    var mqttClient = CocoaMQTT(clientID: "PiBotApp", host: "mil-mascaras.local", port: 1883)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        
        loadData()
    }
    
    func loadData() {
        let directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let documentURL = directoryURL.appendingPathComponent("hostAndSounds").appendingPathExtension("json")
        
        guard let data = try? Data(contentsOf: documentURL) else {
            // couldn't find any UserDefaults data for custom hostname or sounds, so use hard-coded values
            loadInitialHostAndSounds()
            return
        }
        let jsonDecoder = JSONDecoder()
        do {
            hostAndSounds = try jsonDecoder.decode(HostAndSounds.self, from: data)
            navigationItem.title = hostAndSounds.hostName
            tableView.reloadData()
        } catch {
            print("😡 ERROR: Could not load data \(error.localizedDescription)")
        }
    }
    
    func loadInitialHostAndSounds() {
        hostAndSounds.hostName = initialHostName
        hostAndSounds.sounds = initialSounds
        navigationItem.title = hostAndSounds.hostName
        mqttClient = CocoaMQTT(clientID: "PiBotApp", host: "\(hostAndSounds.hostName).local", port: 1883)

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowConfiguration" {
            let destination = segue.destination as! ConfigurationViewController
            destination.hostAndSounds = hostAndSounds
            // The trick below will get data back from viewWillDisappear in ConfigurationViewController
            // Also note that that view controller also has a value
            // defined as: var passedBackHostsAndSounds: ((HostAndSounds) -> Void)?
            destination.passedBackHostsAndSounds = { passedValue in
                self.hostAndSounds = passedValue
                self.navigationItem.title = self.hostAndSounds.hostName
                self.tableView.reloadData()
                self.mqttClient = CocoaMQTT(clientID: "PiBotApp", host: "\(self.hostAndSounds.hostName).local", port: 1883)
                _ = self.mqttClient.connect()
            }
        }
    }
    
    @IBAction func buttonDown(_ sender: UIButton) {
        print("Sending message: \(direction[sender.tag]!)")
        mqttClient.publish("pibot/move", withString: direction[sender.tag]!)
    }
    
    @IBAction func buttonUp(_ sender: UIButton) {
        print("Sending message: \(stop)")
        mqttClient.publish("pibot/move", withString: stop)
    }
    
    @IBAction func slideValueChanged(_ sender: UISlider) {
        let volNumber = ((sender.value)*10).rounded()/10
        let volume = "Vol=\(volNumber)"
        mqttClient.publish("pibot/move", withString: volume)
        print("\(volume)")
    }
    
    @IBAction func connectButtonPressed(_ sender: UIButton) {
        print("connect results in \(mqttClient.connect())")
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return hostAndSounds.sounds.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = hostAndSounds.sounds[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // animate selection
        let cell = tableView.cellForRow(at: indexPath)!
        cell.textLabel?.alpha = 0.0
        UIView.animate(withDuration: 1.0, animations: { cell.textLabel!.alpha = 1.0 })
        
        print("You selected row \(indexPath.row): \(hostAndSounds.sounds[indexPath.row])")
        print("Sending message: \(hostAndSounds.sounds[indexPath.row])")
        mqttClient.publish("pibot/move", withString: "\(indexPath.row)")
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
}
