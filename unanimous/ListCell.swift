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
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    
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
