//
//  ResultViewController.swift
//  undisclosed
//
//  Created by chris on 7/14/18.
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

class ResultTableViewCell: UITableViewCell {
    
    @IBOutlet weak var ResultCellLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
}

class ResultViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    var items = [Item]()
    
    var color1 = UIColor(hexString: "#ffffff")

    @IBOutlet weak var ResultTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ResultTableView.delegate = self
        ResultTableView.dataSource = self
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = ResultTableView.dequeueReusableCell(withIdentifier: "resultCell") as! ResultTableViewCell
        cell.backgroundColor = color1
        cell.ResultCellLabel.textColor = UIColor.black
        cell.ResultCellLabel.text = items[indexPath.row].name + String(items[indexPath.row].votes)
        return cell
    }
}
