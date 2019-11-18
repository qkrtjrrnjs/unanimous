//
//  ViewController.swift
//  undisclosed
//
//  Created by chris on 6/11/18.
//  Copyright © 2018 YSYP. All rights reserved.
//
import UIKit
import MultipeerConnectivity

class ViewController: UIViewController{
    
    var items = [Item]()
    
    let cellId = "cellId"

    var host = false
    var voted = false
    var prevVote = UUID()
    
    var peerID:MCPeerID!
    var mcSession:MCSession!
    var mcAdvertiserAssistant:MCAdvertiserAssistant!
    
    var navigationBarApperance = UINavigationBar.appearance()
    var logoButton = UIBarButtonItem()

    var color1 = UIColor(hexString: "#ff2d55")
    var color2 = UIColor(hexString: "#ffffff")
    
    //referencing outlets
    @IBOutlet weak var navBarTitle: UILabel!
    @IBOutlet weak var endButton: UIBarButtonItem!
    @IBOutlet weak var voteButton: UIBarButtonItem!
    @IBOutlet weak var voteButton2: UIBarButtonItem!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var add: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var toolbar2: UIToolbar!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupConnectivity()
        setUpTableView()
        setUpLongPressGesture()
        setUpUI()
        DataManager.clearAllFile()
    }
    
    func setUpTableView(){
        tableView.register(ListCell.self, forCellReuseIdentifier: cellId)
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func setUpLongPressGesture(){
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(sender:)))
        self.view.addGestureRecognizer(longPressRecognizer)
    }
    
    func setUpUI(){
        self.view.backgroundColor = color2
        
        toolbar.barTintColor = color1
        toolbar.tintColor = color2
        
        navigationBarApperance.barTintColor = color1
        navigationBarApperance.tintColor = color2
        
        tableView.backgroundColor = color2
        
        navBarTitle.textColor = color2
        navBarTitle.textAlignment = .center
        
        endButton.tintColor = .clear
        endButton.isEnabled = false
        
        toolbar2.isHidden = true
        toolbar2.barTintColor = color1
        toolbar2.tintColor = color2
    }
    
    @objc func longPressed(sender: UILongPressGestureRecognizer) {
        
        if sender.state == UIGestureRecognizer.State.began {
            
            let touchPoint = sender.location(in: self.tableView)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                
                let actionSheet = UIAlertController(title: "Share", message: "Are you sure you want to share this item?", preferredStyle: .actionSheet)
                
                actionSheet.addAction(UIAlertAction(
                    title: "Yes",
                    style: .default,
                    handler: { (action:UIAlertAction) in
                        self.sendItem(self.items[indexPath.row])
                        
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
                popoverPresentation(actionSheet: actionSheet)
            }
        }
        
    }
    
    //presents UIAlertControllers in popover presentation style
    func popoverPresentation(actionSheet: UIAlertController){
        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width:0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        self.present(actionSheet, animated: true, completion: nil)
    }

    //template for creating alerts
    func createAlert(title:String, message: String){
        let actionSheet = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(
            title: "OK",
            style: .default,
            handler: nil
        ))
        
        popoverPresentation(actionSheet: actionSheet)
    }
    
    //delete all items prior to session and reload tableview
    func deleteAll(){
        items.removeAll()
        tableView.reloadData()
    }
    
    //method called Asynchronously
    func loadData(){
        items = DataManager.loadAll(Item.self)
        items.sort() { $0.votes > $1.votes }
        self.tableView.reloadData()
    }
    
    //handles votes
    @IBAction func voteButton(_ sender: Any) {
        guard let indexPath = tableView.indexPathForSelectedRow else {
            createAlert(title: "Error", message: "No item is selected!")
            return
        }
        let indexPathRow = indexPath.row
        
        if(!voted){
            prevVote = self.items[indexPathRow].itemIdentifier
            self.items[indexPathRow].votes += 1
            self.items[indexPathRow].saveItem()
            self.sendItem(self.items[indexPathRow])
            items.sort() { $0.votes > $1.votes }
            self.tableView.reloadData()
            voted = true
            endButton.tintColor = color2
            endButton.isEnabled = true
        }else{
            let actionSheet = UIAlertController(title: "Warning", message: "You have already voted, are you sure you want to change your vote?", preferredStyle: .actionSheet)
            
            actionSheet.addAction(UIAlertAction(
                title: "Yes",
                style: .default,
                handler: { (action:UIAlertAction) in
                    //removing previous vote
                    for i in 0..<self.items.count{
                        if self.items[i].itemIdentifier == self.prevVote{
                            self.items[i].votes -= 1
                            self.items[i].saveItem()
                            self.sendItem(self.items[i])
                            break
                        }
                    }
                    self.items.sort() { $0.votes > $1.votes }
                    self.tableView.reloadData()
                    
                    //casting new vote
                    self.prevVote = self.items[indexPathRow].itemIdentifier
                    self.items[indexPathRow].votes += 1
                    self.items[indexPathRow].saveItem()
                    self.sendItem(self.items[indexPathRow])
                        
                        self.items.sort() { $0.votes > $1.votes }
                        self.tableView.reloadData()
            }))
            
            actionSheet.addAction(UIAlertAction(
                title: "No",
                style: .default,
                handler: nil
            ))
            
            popoverPresentation(actionSheet: actionSheet)
        }
      
    }
    
    @IBAction func voteButton2(_ sender: Any) {
        guard let indexPath = tableView.indexPathForSelectedRow else {
            createAlert(title: "Error", message: "No item is selected!")
            return
        }
        let indexPathRow = indexPath.row
        
        if(!voted){
            prevVote = self.items[indexPathRow].itemIdentifier
            self.items[indexPathRow].votes += 1
            self.items[indexPathRow].saveItem()
            self.sendItem(self.items[indexPathRow])
            items.sort() { $0.votes > $1.votes }
            self.tableView.reloadData()
            voted = true
            endButton.tintColor = color2
            endButton.isEnabled = true
        }else{
            let actionSheet = UIAlertController(title: "Warning", message: "You have already voted, are you sure you want to change your vote?", preferredStyle: .actionSheet)
            
            actionSheet.addAction(UIAlertAction(
                title: "Yes",
                style: .default,
                handler: { (action:UIAlertAction) in
                    //removing previous vote
                    for i in 0..<self.items.count{
                        if self.items[i].itemIdentifier == self.prevVote{
                            self.items[i].votes -= 1
                            self.items[i].saveItem()
                            self.sendItem(self.items[i])
                            break
                        }
                    }
                    self.items.sort() { $0.votes > $1.votes }
                    self.tableView.reloadData()
                    
                    //casting new vote
                    self.prevVote = self.items[indexPathRow].itemIdentifier
                    self.items[indexPathRow].votes += 1
                    self.items[indexPathRow].saveItem()
                    self.sendItem(self.items[indexPathRow])
                    
                    self.items.sort() { $0.votes > $1.votes }
                    self.tableView.reloadData()
            }))
            
            actionSheet.addAction(UIAlertAction(
                title: "No",
                style: .default,
                handler: nil
            ))
            
            popoverPresentation(actionSheet: actionSheet)
        }
 
    }
    
    
    //edits items.name
    @IBAction func editButton(_ sender: Any) {
        if(items.count > 0){
            guard let indexPath = self.tableView.indexPathForSelectedRow else {
                createAlert(title: "Error", message: "No item is selected!")
                return
            }
            let indexPathRow = indexPath.row
            
            let alert = UIAlertController(title: "", message: "Edit List Item", preferredStyle: .alert)
            alert.addTextField{
                (textfield: UITextField) in textfield.placeholder = self.items[indexPathRow].name
            }
            
            alert.addAction(UIAlertAction(title: "Update", style: .default, handler: { (updateAction) in
                self.items[indexPathRow].name = alert.textFields!.first!.text!
                self.items[indexPathRow].saveItem()
                self.sendItem(self.items[indexPathRow])
                self.items.sort() { $0.votes > $1.votes }
                self.tableView.reloadRows(at: [indexPath], with: .fade)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: false)
            
        }else{
            createAlert(title: "Error", message: "No items to edit!")
        }
    
    }
    
    //deletes selected item
    @IBAction func deleteItem(_ sender: Any) {
        
        if(items.count > 0){
            guard let indexPath = tableView.indexPathForSelectedRow else {
                createAlert(title: "Error", message: "Please selected an item!")
                return
            }
            
            let indexPathRow = indexPath.row
            
            let actionSheet = UIAlertController(title: "Delete", message: "Are you sure want to delete this item?", preferredStyle: .actionSheet)
            
            actionSheet.addAction(UIAlertAction(
                title: "Yes",
                style: .default,
                handler: { (action:UIAlertAction) in
                    self.items[indexPathRow].addOrDelete = "delete"
                    self.items[indexPathRow].saveItem()
                    self.sendItem(self.items[indexPathRow])
                    self.items[indexPathRow].deleteItem()
                    self.items.remove(at: indexPathRow)
                    self.tableView.deleteRows(at: [indexPath], with: .automatic)
            }))
            
            actionSheet.addAction(UIAlertAction(
                title: "No",
                style: .default,
                handler: nil
            ))
            
            popoverPresentation(actionSheet: actionSheet)
         
        }else{
            createAlert(title: "Error", message: "There are no items to delete!")
        }
    }
    
    //host/join button
    @IBAction func connectivityButton(_ sender: Any) {
        let actionSheet = UIAlertController(title: "Connect", message: "Do you want to Host or Join a session?", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(
            title: "Host Session",
            style: .default,
            handler: { (action:UIAlertAction) in
                if(self.navBarTitle.text == "HOST"){
                    self.createAlert(title: "ERROR", message: "You are already hosting a session, terminate current session to host another session!")
                }else{
                    self.mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "ysyp", discoveryInfo: nil, session: self.mcSession)
                    self.mcAdvertiserAssistant.start()
                    self.navBarTitle.text = "HOST"
                    DataManager.clearAllFile()
                    self.deleteAll()
                    self.mcSession.disconnect()
                    self.voted = false
                    self.endButton.tintColor = self.color2
                    self.endButton.isEnabled = true
                }
        }))
        
        actionSheet.addAction(UIAlertAction(
            title: "Join Session",
            style: .default,
            handler: { (action:UIAlertAction) in
                if(self.navBarTitle.text == "HOST"){
                    self.createAlert(title: "ERROR", message: "You are a host, terminate current session to join a session!")
                }else{
                    let mcBrowser = MCBrowserViewController(serviceType: "ysyp", session: self.mcSession)
                    mcBrowser.delegate = self
                    self.present(mcBrowser, animated: true, completion: nil)
                    DataManager.clearAllFile()
                    self.deleteAll()
                    self.navBarTitle.text = "UNANIMOUS"
                    self.mcSession.disconnect()
                    self.voted = false
                    self.endButton.tintColor = .clear
                    self.endButton.isEnabled = false
                }
        }))
        
        actionSheet.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: nil
        ))
        
        popoverPresentation(actionSheet: actionSheet)
    }
    
    func setupConnectivity(){
        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
        mcSession.delegate = self
    }
    
    //asks for item and adds to array
    func create(){
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
                let newItem = Item(name: name, itemIdentifier: UUID(), addOrDelete: "add", votes: 0)
                if name == ""{
                    let actionSheet = UIAlertController(title: "Error", message: "Nothing was entered!", preferredStyle: .actionSheet)
                 
                    actionSheet.addAction(UIAlertAction(
                        title: "OK",
                        style: .default,
                        handler: { (action:UIAlertAction) in
                                self.create()
                    }))
                    
                    self.popoverPresentation(actionSheet: actionSheet)
                }else{
                    newItem.saveItem()
                    self.items.append(newItem)
                    self.sendItem(newItem)
                    self.items.sort() { $0.votes > $1.votes }
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
    }
    
    //adds and saves created items
    @IBAction func addItem(_ sender: Any) {
        if(mcSession.connectedPeers.count > 0 || self.navBarTitle.text == "HOST"){
            self.create()
        }else{
            self.createAlert(title: "Error", message: "Please host a session first!")
        }
    }//
    
    @IBAction func endButton(_ sender: Any) {
        let actionSheet = UIAlertController(title: "Leave session", message: "Are you sure you want to leave this voting session?", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(
            title: "Yes",
            style: .default,
            handler: { (action:UIAlertAction) in
                if(self.navBarTitle.text == "HOST"){
                    let newItem = Item(name: "end", itemIdentifier: UUID(), addOrDelete: "end", votes: 0)
                    newItem.saveItem()
                    self.items.append(newItem)
                    self.sendItem(newItem)
                    self.mcAdvertiserAssistant.stop()
                }
                self.deleteAll()
                DataManager.clearAllFile()
                self.tableView.reloadData()
                self.mcSession.disconnect()
                self.endButton.tintColor = .clear
                self.endButton.isEnabled = false
                self.navBarTitle.text = "UNANIMOUS"
                self.voted = false
                self.toolbar2.isHidden = true
                self.toolbar.isHidden = false
                self.add.tintColor = self.color2
                self.add.isEnabled = true
        }))
        
        actionSheet.addAction(UIAlertAction(
            title: "No",
            style: .default,
            handler: nil
        ))
        
        popoverPresentation(actionSheet: actionSheet)
    }
    
    //sends item to connected peers
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
}

extension ViewController: UITableViewDelegate, UITableViewDataSource{
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return items.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId) as! ListCell
        
        cell.item = items[indexPath.row]
        
        return cell
    }
    
}

extension ViewController: MCSessionDelegate, MCBrowserViewControllerDelegate{
    //MC Delegate functions
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case MCSessionState.connected:
            print("Connected: \(peerID.displayName)")
            if(self.navBarTitle.text != "HOST"){
                toolbar.isHidden = true
                add.isEnabled = false
                add.tintColor = .clear
                toolbar2.isHidden = false
            }else{
                for i in 0..<items.count{
                    self.sendItem(items[i])
                }
            }
        case MCSessionState.connecting:
            print("Connecting: \(peerID.displayName)")
            
        case MCSessionState.notConnected:
            print("Not Connected: \(peerID.displayName)")
        @unknown default:
            fatalError("unknown error")
        }
    }
    
    //handles received data
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do{
            let item = try JSONDecoder().decode(Item.self, from: data)
            if(item.addOrDelete == "add"){
                DataManager.save(item, with: item.itemIdentifier.uuidString)
            }
            else if(item.addOrDelete == "delete"){
                DataManager.delete(item.itemIdentifier.uuidString)
            }
            else{
                let actionSheet = UIAlertController(title: "WARNING", message: "Host has left the session, this session is terminated!", preferredStyle: .actionSheet)
                
                actionSheet.addAction(UIAlertAction(
                    title: "OK",
                    style: .default,
                    handler: { (action:UIAlertAction) in
                        DataManager.clearAllFile()
                        self.items.removeAll()
                        self.tableView.reloadData()
                        self.endButton.isEnabled = false
                        self.endButton.tintColor = .clear
                        self.voted = false
                        self.mcSession.disconnect()
                        self.toolbar2.isHidden = true
                        self.toolbar.isHidden = false
                        self.add.tintColor = self.color2
                        self.add.isEnabled = true
                }))
                
                popoverPresentation(actionSheet: actionSheet)
            }
            
            DispatchQueue.main.async {
                self.loadData()//should not load data on main thread
            }
            
        }catch{
            print("Unable to process received data")
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
