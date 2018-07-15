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
    
    var color1 = UIColor(hexString: "#ffffff")
    
    @IBOutlet weak var voteTableView: UITableView!
    @IBOutlet weak var voteButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        voteTableView.delegate = self
        voteTableView.dataSource = self
        
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
        
        voteButton.isEnabled = false
        voteButton.isHidden = true
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = voteTableView.dequeueReusableCell(withIdentifier: "voteCell") as! VoteTableViewCell
        cell.backgroundColor = color1
        cell.VoteCellLabel.textColor = UIColor.black
        cell.VoteCellLabel.text = items[indexPath.row].name
        return cell
    }

}
