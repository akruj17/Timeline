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
    
    //create an image directory for a a new timeline. Returns true if created; false if already existing
    static func createImageDirectory(name: String) -> Bool {
        var created = false
        let direc = documents.appendingPathComponent("\(TIMELINE_IMAGE_DIRECTORY)/\(name)") as NSString
        if !fileManager.fileExists(atPath: direc as String) {
            //does not yet exist
            try! fileManager.createDirectory(atPath: direc as String, withIntermediateDirectories: true, attributes: nil)
            created = true
        }
        //Create plist file for image info
        let imageInfoFile = direc.appendingPathComponent("\(IMAGE_INFO_PLIST)") as NSString
        if !fileManager.fileExists(atPath: imageInfoFile as String) {
            let data = NSMutableDictionary()
            data.setValue(0, forKey: IMAGE_COUNTER)
            data.setValue([String](), forKey: IMAGE_ORDERING_ARRAY)
            data.write(toFile: imageInfoFile as String, atomically: false)
            created = true
        }
        return created
    }
    
//    static func retrieveImages(name: String) ->
    
    
    
    
    static func updateImagesInFileSystem(imageStatusData: [imageStatusTuple], imagePathsToDelete: [String], imageDirectory: NSString, startCounter: Int, imageInfo: NSMutableDictionary, pListPath: NSString, timelineTitle: String) {
        DispatchQueue.global(qos: .background).async {
            //first delete the images no longer needed...doing this first is a bit more efficient because the imagedirectory has fewer files
            for path in imagePathsToDelete {
                do {
                    let imgPath = imageDirectory.appendingPathComponent("\(path)")
                    try fileManager.removeItem(atPath: imgPath)
                }
                catch _ as NSError {
                    fatalError()
                }
            }
            //Now add the images that need to be saved
            var filePathOrdering = [String]()
            let randomIndex = Int(arc4random_uniform(UInt32(imageStatusData.count)))
            for (index, image) in imageStatusData.enumerated() {
                autoreleasepool {
                    // if the image has not already been saved before, it will not already have a file path
                    if image.filePath == nil {
                        let imagePath = "/image\(startCounter + index).jpg"
                        let imageFile = imageDirectory.appendingPathComponent(imagePath)
                        fileManager.createFile(atPath: imageFile, contents: image.data, attributes: nil)
                        filePathOrdering.append(imagePath)
                    } else {
                        filePathOrdering.append(image.filePath!)
                    }
                    if index == randomIndex {
                        let firstImageDirectory = documents.appendingPathComponent("\(TIMELINE_IMAGE_DIRECTORY)/\(FIRST_IMAGES_DIRECTORY)") as NSString
                        let imageFile = firstImageDirectory.appendingPathComponent("\(timelineTitle).jpg")
                        fileManager.createFile(atPath: imageFile, contents: UIImage(data: image.data)!.jpegData(compressionQuality: 0.3)!, attributes: nil)
                    }
                }
            }
            // now update the image info plist
            imageInfo.setValue(filePathOrdering, forKey: IMAGE_ORDERING_ARRAY)
            imageInfo.setValue(startCounter + imageStatusData.count, forKey: IMAGE_COUNTER)
            imageInfo.write(toFile: pListPath as String, atomically: false)
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
    
    static func deleteTimelineImages(imgDirectory: NSString, imageInfo: NSMutableDictionary) {
        autoreleasepool {
            do {
                for imagePath in (imageInfo.value(forKey: IMAGE_ORDERING_ARRAY) as! [String]) {
                    try fileManager.removeItem(atPath: imgDirectory.appendingPathComponent("\(imagePath)"))
                }
                try fileManager.removeItem(atPath: imgDirectory as String)
            } catch _ as NSError {
                fatalError()
            }
        }
    }

}
