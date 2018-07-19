//
//  VoteViewController.swift
//  undisclosed
//
//  Created by chris on 7/4/18.
//  Copyright © 2018 YSYP. All rights reserved.
//

/*
 // MARK: - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
 // Get the new view controller using segue.destinationViewController.
 // Pass the selected object to the new view controller.
 }
 */

import UIKit
import MultipeerConnectivity

class VoteTableViewCell: UITableViewCell {
    
    @IBOutlet weak var VoteCellLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
}

class VoteViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    var items = [Item]()
    var peers = Int()
    
    var peerID:MCPeerID!
    var mcSession:MCSession!
    var mcAdvertiserAssistant:MCAdvertiserAssistant!
    
    var color1 = UIColor(hexString: "#ff5958")
    var color2 = UIColor(hexString: "#ffffff")

    @IBOutlet weak var voteTableView: UITableView!
    @IBOutlet weak var voteButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        voteTableView.delegate = self
        voteTableView.dataSource = self
        
        self.view.backgroundColor = color2
        voteTableView.backgroundColor = color2
        voteButton.layer.backgroundColor = color1.cgColor
        voteButton.setTitleColor(color2, for: .normal)
        
        if(peers > 0){
            items = DataManager.loadAll(Item.self)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func voteButton(_ sender: Any) {
        let indexPath = voteTableView.indexPathForSelectedRow
        
        self.items[(indexPath?.row)!].votes += 1
        self.items[(indexPath?.row)!].saveItem()
        self.sendItem(self.items[(indexPath?.row)!])
        self.voteTableView.reloadData()

        /*if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ResultViewController") as? ResultViewController
        {
            vc.items = self.items
            vc.peers = self.peers
            vc.modalTransitionStyle = .crossDissolve
            present(vc, animated: true, completion: nil)
        }*/
        
        voteButton.isHidden = true
        voteButton.isEnabled = false
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = voteTableView.dequeueReusableCell(withIdentifier: "voteCell") as! VoteTableViewCell
        cell.backgroundColor = color2
        cell.VoteCellLabel.textColor = UIColor.black
        cell.VoteCellLabel.text = items[indexPath.row].name + " : " + String(items[indexPath.row].votes) + " votes"
        return cell
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
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do{
            
            let item = try JSONDecoder().decode(Item.self, from: data)
            DataManager.save(item, with: item.itemIdentifier.uuidString)
            
            DispatchQueue.main.async {
                self.items = DataManager.loadAll(Item.self)
                self.voteTableView.reloadData()
                print("_______________________")
            }
        }catch{
            fatalError("Unable to process received data")
        }
        
    }

}
