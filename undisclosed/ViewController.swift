//
//  ViewController.swift
//  undisclosed
//
//  Created by chris on 6/11/18.
//  Copyright © 2018 YSYP. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class TableViewCell: UITableViewCell {
    
    @IBOutlet weak var listLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MCSessionDelegate, MCBrowserViewControllerDelegate  {
    
    var items = [Item]()
    var peerID:MCPeerID!
    var mcSession:MCSession!
    var mcAdvertiserAssistant:MCAdvertiserAssistant!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        tableView.delegate = self
        tableView.dataSource = self
        setupConnectivity()
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(sender:)))
        self.view.addGestureRecognizer(longPressRecognizer)
    }//
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }//
    
    func loadData(){
        items = [Item]()
        items = DataManager.loadAll(Item.self)
        self.tableView.reloadData()
    }
    
    func sendItem (_ item: Item){
        if mcSession.connectedPeers.count > 0{
            if let itemData = DataManager.loadData(item.itemIdentifier.uuidString){
                do{
                    try mcSession.send(itemData, toPeers: mcSession.connectedPeers, with: .reliable)
                }catch{
                    fatalError("could not send item")
                }
            }
        }else{
            print("not connected to other device")
        }
    }
    
    @objc func longPressed(sender: UILongPressGestureRecognizer) {
        
        if sender.state == UIGestureRecognizerState.began {
            
            let touchPoint = sender.location(in: self.tableView)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                
                print("Long pressed row: \(indexPath.row)")
            }
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func showConnectivityAction(_ sender: Any) {
        let actionSheet = UIAlertController(title: "Share Item List", message: "Do you want to Host or Join a session?", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(
            title: "Host Session",
            style: .default,
            handler: { (action:UIAlertAction) in
                self.mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "ysyp", discoveryInfo: nil, session: self.mcSession)
                self.mcAdvertiserAssistant.start()
        }))
        
        actionSheet.addAction(UIAlertAction(
            title: "Join Session",
            style: .default,
            handler: { (action:UIAlertAction) in
                let mcBrowser = MCBrowserViewController(serviceType: "ysyp", session: self.mcSession)
                mcBrowser.delegate = self
                self.present(mcBrowser, animated: true, completion: nil)
        }))
        
        actionSheet.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: nil
        ))
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    @IBAction func addItem(_ sender: Any) {
        //create alert controller
        let alert = UIAlertController(
            title: "New Item",
            message: "Enter an item",
            preferredStyle: .alert
        )
        //add textfield
        alert.addTextField{
            (textfield: UITextField) in textfield.placeholder = "item"
        }
        
        //add create btn
        alert.addAction(UIAlertAction(
            title: "Create",
            style: .default,
            handler: {(action:UIAlertAction) in
                guard let name = alert.textFields?.first?.text else {return}
                let newItem = Item(name: name, itemIdentifier: UUID())
                newItem.saveItem()
                self.items.append(newItem)
                self.sendItem(newItem)
                self.tableView.reloadData()
            }
        ))
        
        //add cancel btn
        alert.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: nil
        ))
        
        self.present(alert, animated: true, completion: nil)
    }//
    
    
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return items.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! TableViewCell
        cell.listLabel.text = items[indexPath.row].name
        return cell
    }
    
    func setupConnectivity(){
        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
    }
    
    //MC Delegate functions
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case MCSessionState.connected:
            print("Connected: \(peerID.displayName)")
            
        case MCSessionState.connecting:
            print("Connecting: \(peerID.displayName)")
            
        case MCSessionState.notConnected:
            print("Not Connected: \(peerID.displayName)")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do{
            let item = try JSONDecoder().decode(Item.self, from: data)
            DataManager.save(item, with: item.itemIdentifier.uuidString)
            
            DispatchQueue.main.async {
                self.loadData()
            }
        }catch{
            fatalError("Unable to process received data")
        }
        
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
    }


}

