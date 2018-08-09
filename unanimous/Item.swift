//
//  Item.swift
//  undisclosed
//
//  Created by chris on 6/17/18.
//  Copyright © 2018 YSYP. All rights reserved.
//

import Foundation

struct Item : Codable{
    var name:String
    var itemIdentifier:UUID
    var addOrDelete:String
    var votes: Int

    func saveItem() {
        DataManager.save(self, with: "\(itemIdentifier.uuidString)")
    }
    
    func deleteItem() {
        DataManager.delete(itemIdentifier.uuidString)
    }
}
