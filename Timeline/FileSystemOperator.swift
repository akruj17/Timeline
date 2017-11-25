//
//  FileSystemOperator.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 9/29/17.
//  Copyright © 2017 Edumacation!. All rights reserved.
//

import Foundation
import Photos

class FileSystemOperator {
    
    static let fileManager = FileManager.default
    
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
    
    
    static func updateImagesInFileSystem(imageStatusData: [imageStatusTuple], imagePathsToDelete: [String], imageDirectory: NSString, startCounter: Int) {
        DispatchQueue.global(qos: .background).async {
            //first delete the images no longer needed...doing this first is a bit more efficient because the imagedirectory has fewer files
            for path in imagePathsToDelete {
                do {
                    let imgPath = imageDirectory.appendingPathComponent("\(path)")
                    try fileManager.removeItem(atPath: imgPath)
                }
                catch let error as NSError {
                    fatalError()
                }
            }
            //Now add the images that need to be saved
            for (index, image) in imageStatusData.enumerated() {
                autoreleasepool {
                    // if the image has not already been saved before, it will not already have a file path
                    if image.filePath == nil {
                        let imagePath = "/image\(startCounter + index).jpg"
                        let imageFile = imageDirectory.appendingPathComponent(imagePath)
                        fileManager.createFile(atPath: imageFile, contents: image.data, attributes: nil)
                        print("cOngrats you saved an image")
                    }
                }
            }
        }
    }
    
    static func resizeImage(image: UIImage, height: CGFloat) -> UIImage {
        let size = image.size
        let scale = height / size.height
        UIGraphicsBeginImageContext(CGSize(width: size.width * scale, height: size.height * scale))
        image.draw(in: CGRect(x: 0, y: 0, width: size.width * scale, height: size.height * scale))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}


