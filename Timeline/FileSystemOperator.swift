//
//  FileSystemOperator.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 9/29/17.
//  Copyright © 2017 Edumacation!. All rights reserved.
//

import Foundation

class FileSystemOperator {
    
    //create an image directory for a a new timeline
    static func createImageDirectory(name: String) {
        let direc = documents.appendingPathComponent("\(TIMELINE_IMAGE_DIRECTORY)/\(name)") as NSString
        try! fileManager.createDirectory(atPath: direc as String, withIntermediateDirectories: true, attributes: nil)
        //Create plist file for image info
        let imageInfoFile = direc.appendingPathComponent("\(IMAGE_INFO_PLIST)") as NSString
        let data = NSMutableDictionary()
        data.setValue(0, forKey: IMAGE_COUNTER)
        data.setValue([String](), forKey: IMAGE_ORDERING_ARRAY)
        data.write(toFile: imageInfoFile as String, atomically: false)
        print("\(direc)")
    }
}
