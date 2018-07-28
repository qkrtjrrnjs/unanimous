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
    
    var voted = false
    var showResult = false
    
    var peerID:MCPeerID!
    var mcSession:MCSession!
    var mcAdvertiserAssistant:MCAdvertiserAssistant!
    
    var navigationBarApperance = UINavigationBar.appearance()
    
    //hex to UIColor
    var color1 = UIColor(hexString: "#ff2d55")
    var color2 = UIColor(hexString: "#ffffff")
    
    //referencing outlets
    @IBOutlet weak var navBarTitle: UILabel!
    @IBOutlet weak var endButton: UIBarButtonItem!
    @IBOutlet weak var voteButton: UIBarButtonItem!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var add: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        setupConnectivity()

        //change style
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
        
        DataManager.clearAllFile()
    }//
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }//
    
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
        if(showResult){
            createAlert(title: "Error", message: "Start a new voting session!")
        }else{
            if(items.count < 1){
                createAlert(title: "Error", message: "No items to vote on!")
            }
            else{
                let indexPath = tableView.indexPathForSelectedRow
                
                if(indexPath?.row != nil){
                    
                    if(mcSession.connectedPeers.count > 0){
                        if(!voted){
                            self.items[(indexPath?.row)!].votes += 1
                            self.items[(indexPath?.row)!].addOrDelete = "add"
                            self.items[(indexPath?.row)!].saveItem()
                            self.sendItem(self.items[(indexPath?.row)!])
                            items.sort() { $0.votes > $1.votes }
                            self.tableView.reloadData()
                            voted = true
                            endButton.tintColor = color2
                            endButton.isEnabled = true
                        }else{
                            createAlert(title: "Error", message: "You have already voted!")
                        }
                    }
                    else{
                        self.items[(indexPath?.row)!].votes += 1
                        self.tableView.reloadData()
                        endButton.tintColor = color2
                        endButton.isEnabled = true
                    }
                }else{
                    createAlert(title: "Error", message: "No item is selected!")
                }
            }
        }
    }
    
    //edits items.name
    @IBAction func editButton(_ sender: Any) {
        
        if(showResult){
            createAlert(title: "Error", message: "start a new voting session!")
        }else{
            if(items.count > 0){
                let indexPath = self.tableView.indexPathForSelectedRow
                
                if(indexPath?.row != nil){
                    let alert = UIAlertController(title: "", message: "Edit List Item", preferredStyle: .alert)
                    alert.addTextField{
                        (textfield: UITextField) in textfield.placeholder = self.items[(indexPath?.row)!].name
                    }
                    
                    alert.addAction(UIAlertAction(title: "Update", style: .default, handler: { (updateAction) in
                        if(self.mcSession.connectedPeers.count > 0){
                            self.items[(indexPath?.row)!].name = alert.textFields!.first!.text!
                            self.items[(indexPath?.row)!].addOrDelete = "add"
                            self.items[(indexPath?.row)!].saveItem()
                            self.sendItem(self.items[(indexPath?.row)!])
                            self.items.sort() { $0.votes > $1.votes }
                            self.tableView.reloadRows(at: [indexPath!], with: .fade)
                        }else{
                            self.items[(indexPath?.row)!].name = alert.textFields!.first!.text!
                            self.items.sort() { $0.votes > $1.votes }
                            self.tableView.reloadRows(at: [indexPath!], with: .fade)
                            
                        }
                        }))
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    self.present(alert, animated: false)
                }else{
                    createAlert(title: "Error", message: "No item is selected!")
                }
            }else{
                createAlert(title: "Error", message: "No items to edit!")
            }
        }
    
    }
    
    //deletes selected item
    @IBAction func deleteItem(_ sender: Any) {
        
        if(showResult){
            createAlert(title: "Error", message: "Start a new voting session!")
        }else{
            if(items.count > 0){
                let indexPath = tableView.indexPathForSelectedRow
                
                if(indexPath?.row != nil){
                    let actionSheet = UIAlertController(title: "Delete", message: "Are you sure want to delete this item?", preferredStyle: .actionSheet)
                    
                    actionSheet.addAction(UIAlertAction(
                        title: "Yes",
                        style: .default,
                        handler: { (action:UIAlertAction) in
                            if(indexPath?.row != nil){
                                self.items[(indexPath?.row)!].addOrDelete = "delete"
                                self.items[(indexPath?.row)!].saveItem()
                                self.sendItem(self.items[(indexPath?.row)!])
                                self.items[(indexPath?.row)!].deleteItem()
                                self.items.remove(at: (indexPath?.row)!)
                                self.tableView.deleteRows(at: [indexPath!], with: .automatic)
                            }
                    }))
                    
                    actionSheet.addAction(UIAlertAction(
                        title: "No",
                        style: .default,
                        handler: nil
                    ))
                    
                    popoverPresentation(actionSheet: actionSheet)
                }else{
                    createAlert(title: "Error", message: "Please selected an item!")
                }
            }else{
                createAlert(title: "Error", message: "There are no items to delete!")
            }
        }
        
    }
    
    //host/join button
    @IBAction func connectivityButton(_ sender: Any) {
        let actionSheet = UIAlertController(title: "Connect", message: "Do you want to Host or Join a session?", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(
            title: "Host Session",
            style: .default,
            handler: { (action:UIAlertAction) in
                self.mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "ysyp", discoveryInfo: nil, session: self.mcSession)
                self.mcAdvertiserAssistant.start()
                self.navBarTitle.text = "HOST"
                DataManager.clearAllFile()
                self.deleteAll()
                self.mcSession.disconnect()
                self.voted = false
                self.endButton.tintColor = self.color2
                self.endButton.isEnabled = true
        }))
        
        actionSheet.addAction(UIAlertAction(
            title: "Join Session",
            style: .default,
            handler: { (action:UIAlertAction) in
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
                    if self.mcSession.connectedPeers.count > 0{
                        newItem.saveItem()
                        self.items.append(newItem)
                        self.sendItem(newItem)
                        self.items.sort() { $0.votes > $1.votes }
                        self.tableView.reloadData()
                    }else{
                        self.items.append(newItem)
                        self.items.sort() { $0.votes > $1.votes }
                        self.tableView.reloadData()
                    }
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
        if(showResult){
            self.deleteAll()
            showResult = false
        }
        self.create()
    }//
    
    @IBAction func endButton(_ sender: Any) {
        if(mcSession.connectedPeers.count > 0){
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
                    }
                    self.deleteAll()
                    DataManager.clearAllFile()
                    self.tableView.reloadData()
                    self.mcSession.disconnect()
                    self.endButton.tintColor = .clear
                    self.endButton.isEnabled = false
                    self.navBarTitle.text = "UNANIMOUS"
                    self.voted = false
            }))
            
            actionSheet.addAction(UIAlertAction(
                title: "No",
                style: .default,
                handler: nil
            ))
            
            popoverPresentation(actionSheet: actionSheet)
        }else{
            let actionSheet = UIAlertController(title: "End Voting", message: "Are you sure you want to finish voting?", preferredStyle: .actionSheet)
            
            actionSheet.addAction(UIAlertAction(
                title: "Yes",
                style: .default,
                handler: { (action:UIAlertAction) in
                    if(self.navBarTitle.text == "HOST"){
                        DataManager.clearAllFile()
                        self.deleteAll()
                    }
                    self.showResult = true
                    DataManager.clearAllFile()
                    self.tableView.reloadData()
                    self.endButton.tintColor = .clear
                    self.endButton.isEnabled = false
                    self.navBarTitle.text = "UNANIMOUS"
                    self.voted = false
            }))
            
            actionSheet.addAction(UIAlertAction(
                title: "No",
                style: .default,
                handler: nil
            ))
            
            popoverPresentation(actionSheet: actionSheet)
        }
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return items.count
    }
    
    func customCell(cell: TableViewCell, indexPath: IndexPath){
        
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! TableViewCell
        cell.backgroundColor = color2
        cell.listLabel.textColor = UIColor.black
        if(mcSession.connectedPeers.count > 0){
            if items[indexPath.row].votes == 0{
                cell.listLabel.text = items[indexPath.row].name
                cell.listLabel.font = UIFont(name: "BloggerSans-Medium", size: cell.listLabel.font.pointSize)
            }else{
                if(items[indexPath.row].votes == 1){
                    cell.listLabel.text = items[indexPath.row].name + " : " + String(items[indexPath.row].votes) + " like"
                    cell.listLabel.font = UIFont(name: "BloggerSans-Medium", size: cell.listLabel.font.pointSize)
                }else{
                    cell.listLabel.text = items[indexPath.row].name + " : " + String(items[indexPath.row].votes) + " likes"
                    cell.listLabel.font = UIFont(name: "BloggerSans-Medium", size: cell.listLabel.font.pointSize)
                }
            }
        }else{
            if(!showResult){
                cell.listLabel.text = items[indexPath.row].name
                cell.listLabel.font = UIFont(name: "BloggerSans-Medium", size: cell.listLabel.font.pointSize)
            }else{
                if(items[indexPath.row].votes == 1){
                    cell.listLabel.text = items[indexPath.row].name + " : " + String(items[indexPath.row].votes) + " like"
                    cell.listLabel.font = UIFont(name: "BloggerSans-Medium", size: cell.listLabel.font.pointSize)
                }else{
                    cell.listLabel.text = items[indexPath.row].name + " : " + String(items[indexPath.row].votes) + " likes"
                    cell.listLabel.font = UIFont(name: "BloggerSans-Medium", size: cell.listLabel.font.pointSize)
                }
            }
        }
        return cell
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
    
    //handles received data
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do{
            var item = try JSONDecoder().decode(Item.self, from: data)
            if(item.addOrDelete == "add"){
                item.addOrDelete = "delete"
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
                }))
                
                popoverPresentation(actionSheet: actionSheet)
            }
            
            DispatchQueue.main.async {
                self.loadData()
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

