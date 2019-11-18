//
//  ListCell.swift
//  unanimous
//
//  Created by chris on 11/18/19.
//  Copyright © 2019 YSYP. All rights reserved.
//

import UIKit

class ListCell: UITableViewCell {
    
    let listLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .black
        return label
    }()
    
    var item: Item?{
        didSet{
            guard let item = item else { return }
            
            if item.votes == 0{
                listLabel.text = item.name
                listLabel.font = UIFont(name: "BloggerSans-Medium", size: listLabel.font.pointSize)
            }else{
                if(item.votes == 1){
                    listLabel.text = item.name + " : " + String(item.votes) + " like"
                    listLabel.font = UIFont(name: "BloggerSans-Medium", size: listLabel.font.pointSize)
                }else{
                    listLabel.text = item.name + " : " + String(item.votes) + " likes"
                    listLabel.font = UIFont(name: "BloggerSans-Medium", size: listLabel.font.pointSize)
                }
            }
            
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    
        self.backgroundColor = UIColor(hexString: "#ffffff")
        self.addSubview(listLabel)
        
        listLabel.translatesAutoresizingMaskIntoConstraints = false
        
        listLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 10).isActive = true
        listLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10).isActive = true
        listLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 10).isActive = true
        listLabel.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -10).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
