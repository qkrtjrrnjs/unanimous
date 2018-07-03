//
//  ViewController.swift
//  undisclosed
//
//  Created by chris on 6/11/18.
//  Copyright © 2018 YSYP. All rights reserved.
//
import UIKit
import MultipeerConnectivity

extension UIColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

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
    
    var navigationBarApperance = UINavigationBar.appearance()
    
    //hex to UIColor
    var color1 = UIColor(hexString: "#ff5958")
    var color2 = UIColor(hexString: "#ffffff")
    var color3 = UIColor(hexString: "ff88a4")

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        setupConnectivity()
        
        //add Long press Gesture
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(sender:)))
        self.view.addGestureRecognizer(longPressRecognizer)

        //change style
        self.view.backgroundColor = color2
        navigationBarApperance.barTintColor = color1
        navigationBarApperance.tintColor = color2
        tableView.backgroundColor = color2
        voteButton.layer.backgroundColor = color1.cgColor
        voteButton.setTitleColor(color2, for: .normal)
        
        items = DataManager.loadAll(Item.self)
        if(items.count != 0){
            for i in 0...items.count{
                items[i].deleteItem()
            }
        }
    }//
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }//
    
    @IBOutlet weak var voteButton: UIButton!
    
    @IBAction func voteButton(_ sender: Any) {
        if(items.count == 0){
            let actionSheet = UIAlertController(title: "ERROR", message: "You must add an item before you can vote", preferredStyle: .actionSheet)
            
            actionSheet.addAction(UIAlertAction(
                title: "OK",
                style: .default,
                handler: nil
            ))
            
            if let popoverController = actionSheet.popoverPresentationController {
                popoverController.sourceView = self.view
                popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            self.present(actionSheet, animated: true, completion: nil)
        }
    }
    
    func loadData(){
        //items = [Item]()
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
                
                let actionSheet = UIAlertController(title: "Delete", message: "Are you sure want to delete this item?", preferredStyle: .actionSheet)
                
                actionSheet.addAction(UIAlertAction(
                    title: "Yes",
                    style: .default,
                    handler: { (action:UIAlertAction) in
                        self.items[indexPath.row].addOrDelete = "delete"
                        self.items[indexPath.row].saveItem()
                        self.sendItem(self.items[indexPath.row])
                        self.items[indexPath.row].deleteItem()
                        self.items.remove(at: indexPath.row)
                        self.tableView.deleteRows(at: [indexPath], with: .automatic)
                }))
                
                actionSheet.addAction(UIAlertAction(
                    title: "No",
                    style: .default,
                    handler: nil
                ))
                
                if let popoverController = actionSheet.popoverPresentationController {
                    popoverController.sourceView = self.view
                    popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                    popoverController.permittedArrowDirections = []
                }
                
                self.present(actionSheet, animated: true, completion: nil)
            }
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    //connect button
    @IBAction func showConnectivityAction(_ sender: Any) {
        let actionSheet = UIAlertController(title: "Share Item List", message: "Do you want to Host or Join a session?", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(
            title: "Host Session",
            style: .default,
            handler: { (action:UIAlertAction) in
                self.mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "ysyp", discoveryInfo: nil, session: self.mcSession)
                self.mcAdvertiserAssistant.start()
                self.voteButton.isHidden = false
                self.voteButton.isEnabled = true
        }))
        
        actionSheet.addAction(UIAlertAction(
            title: "Join Session",
            style: .default,
            handler: { (action:UIAlertAction) in
                let mcBrowser = MCBrowserViewController(serviceType: "ysyp", session: self.mcSession)
                mcBrowser.delegate = self
                self.present(mcBrowser, animated: true, completion: nil)
                self.voteButton.isHidden = true
                self.voteButton.isEnabled = false
        }))
        
        actionSheet.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: nil
        ))
        
        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func setupConnectivity(){
        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
        mcSession.delegate = self
    }
    
    //add itme button
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
                let newItem = Item(name: name, itemIdentifier: UUID(), addOrDelete: "add")
                if self.mcSession.connectedPeers.count > 0{
                    newItem.saveItem()
                    self.items.append(newItem)
                    self.sendItem(newItem)
                    self.tableView.reloadData()
                }else{
                    self.items.append(newItem)
                    self.tableView.reloadData()
                }
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
        cell.backgroundColor = color2
        cell.listLabel.textColor = UIColor.black
        cell.listLabel.text = items[indexPath.row].name
        return cell
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
            var item = try JSONDecoder().decode(Item.self, from: data)
            if(item.addOrDelete == "add"){
                item.addOrDelete = "delete"
                DataManager.save(item, with: item.itemIdentifier.uuidString)
            }
            else{
                DataManager.delete(item.itemIdentifier.uuidString)
            }
            
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

