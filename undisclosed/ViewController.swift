//
//  ViewController.swift
//  undisclosed
//
//  Created by chris on 6/11/18.
//  Copyright © 2018 YSYP. All rights reserved.
//

import UIKit

class TableViewCell: UITableViewCell {
    
    @IBOutlet weak var listLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var items = ["sdfkldsf", "owiejfoijw"]
    
    @IBOutlet weak var tableView: UITableView!
    
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
                guard let item = alert.textFields?.first?.text else {return}
                self.items.append(item)
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        tableView.delegate = self
        tableView.dataSource = self
    }//

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }//
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return items.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! TableViewCell
        cell.listLabel.text = items[indexPath.row]
        return cell
    }


}

