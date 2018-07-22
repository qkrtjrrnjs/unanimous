//
//  DataManager.swift
//  undisclosed
//
//  Created by chris on 6/17/18.
//  Copyright © 2018 YSYP. All rights reserved.
//

import Foundation

public class DataManager{
    
    //get Document directory
    static fileprivate func getDocumentDirectory() -> URL{
        if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            return url
        }else{
            fatalError("Unable to get document directory")
        }
    }
    
    //saves any kind of codable object
    static func save <T:Encodable> (_ object:T, with fileName:String) {
        let url = getDocumentDirectory().appendingPathComponent(fileName, isDirectory: false)
        
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(object)
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            FileManager.default.createFile(atPath: url.path, contents: data, attributes: nil)
        }catch{
            fatalError(error.localizedDescription)
        }
    }
    
    //load any kind of codable object
    static func load <T:Decodable> (_ fileName:String, with type:T.Type) -> T {
        let url = getDocumentDirectory().appendingPathComponent(fileName, isDirectory: false)
        if !FileManager.default.fileExists(atPath: url.path) {
            fatalError("File not found at path \(url.path)")
        }
        
        if let data = FileManager.default.contents(atPath: url.path) {
            do {
                let model = try JSONDecoder().decode(type, from: data)
                return model
            }catch{
                fatalError(error.localizedDescription)
            }
        }else{
            fatalError("Data unavailable at path \(url.path)")
        }
    }
    
    //load data from a file
    static func loadData (_ fileName:String) -> Data? {
        let url = getDocumentDirectory().appendingPathComponent(fileName, isDirectory: false)
        if !FileManager.default.fileExists(atPath: url.path) {
            fatalError("File not found at path \(url.path)")
        }
        
        if let data = FileManager.default.contents(atPath: url.path) {
            return data
        }else{
            fatalError("Data unavailable at path \(url.path)")
        }
    }
    
    //load all files from directory
    static func loadAll <T:Decodable> (_ type:T.Type) -> [T] {
        
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: getDocumentDirectory().path)
            
            var modelObjects = [T]()
            for fileName in files {
                modelObjects.append(load(fileName, with: type))
            }
            return modelObjects
            
        }catch{
            fatalError("could not load any files")
        }
        
    }
    
    //delete a file
    static func delete (_ fileName:String) {
        let url = getDocumentDirectory().appendingPathComponent(fileName, isDirectory: false)
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
            }catch{
                fatalError(error.localizedDescription)
            }
        }
    }
    
    static func clearAllFile() {
        let fileManager = FileManager.default
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        
        print("Directory: \(paths)")
        
        do
        {
            let fileName = try fileManager.contentsOfDirectory(atPath: paths)
            
            for file in fileName {
                // For each file in the directory, create full path and delete the file
                let filePath = URL(fileURLWithPath: paths).appendingPathComponent(file).absoluteURL
                try fileManager.removeItem(at: filePath)
            }
        }catch let error {
            print(error.localizedDescription)
        }
    }
    
}
