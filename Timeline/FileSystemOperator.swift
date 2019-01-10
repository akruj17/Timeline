//
//  FileSystemOperator.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 9/29/17.
//  Copyright © 2017 Edumacation!. All rights reserved.
//

import UIKit
import ImagePalette

class FileSystemOperator {
    
    let fileManager = FileManager.default
    // directory and plist paths
    var imageDirectory: NSString
    var imagePList: NSString
    //metadata
    var imageCounter: Int
    var imageInfoArray: [ImageInfo]
    var backgroundCollectionHeight: CGFloat = 0
    var timelineCollectionHeight: CGFloat = 0
    
    
    init(timelineName: String) {
        imageDirectory = documents.appendingPathComponent("\(TIMELINE_IMAGE_DIRECTORY)/\(timelineName)") as NSString
        if !fileManager.fileExists(atPath: imageDirectory as String) {
            //does not yet exist
            try! fileManager.createDirectory(atPath: imageDirectory as String, withIntermediateDirectories: true, attributes: nil)
        }
        //Create plist file for image info
        imagePList = imageDirectory.appendingPathComponent("\(IMAGE_INFO_PLIST)") as NSString
        if !fileManager.fileExists(atPath: imagePList as String) {
            imageCounter = 0
            imageInfoArray = [ImageInfo]()
            let data = NSMutableDictionary()
            data.setValue(imageCounter, forKey: IMAGE_COUNTER)
            data.setValue([NSMutableDictionary](), forKey: IMAGE_INFO_ARRAY)
            data.write(toFile: imagePList as String, atomically: false)
        } else {
            let imageInfo = NSMutableDictionary(contentsOfFile: imagePList as String)
            imageCounter = imageInfo?.value(forKey: IMAGE_COUNTER) as! Int
            let imageInfoData = imageInfo?.value(forKey: IMAGE_INFO_ARRAY) as! [NSMutableDictionary]
            imageInfoArray = [ImageInfo]()
            for info in imageInfoData {
                let color = info[COLOR] as! [CGFloat]
                imageInfoArray.append(ImageInfo.init(name: info[NAME] as! String, width: info[WIDTH] as! CGFloat, scaledWidth: info[SCALED_WIDTH] as! CGFloat, color: UIColor(red: color[0], green: color[1], blue: color[2], alpha: 1.0)))
            }
        }
    }
    
    func saveImage(image: UIImage, index: Int, dispatch_group: DispatchGroup) {
            let imagePath = "/image\(self.imageCounter).jpg"
            self.imageCounter += 1
            let imageFile = self.imageDirectory.appendingPathComponent(imagePath)
            // scale the image before saving it
            let scale = timelineCollectionHeight / image.size.height
            UIGraphicsBeginImageContext(CGSize(width: image.size.width * scale, height: image.size.height * scale))
            image.draw(in: CGRect(x: 0, y: 0, width: image.size.width * scale, height: image.size.height * scale))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            let scaledWidth = (self.backgroundCollectionHeight / CGFloat(image.size.height)) * CGFloat(image.size.width)
            let info = ImageInfo.init(name: imagePath, width: newImage!.size.width, scaledWidth: scaledWidth, color: UIColor.darkGray)
            self.imageInfoArray.insert(info, at: index)
            DispatchQueue.global(qos: .background).async {
            // now save the newImage
            self.fileManager.createFile(atPath: imageFile, contents: newImage!.jpegData(compressionQuality: 0.4), attributes: nil)
            Palette.generateWith(configuration: PaletteConfiguration(image: image), queue: DispatchQueue.main) { (palette) in
                    let color = palette.vibrantColor(defaultColor: UIColor.darkGray)
                    info.color = color
                    dispatch_group.leave()
            }

        }
    }
    
    func deleteImage(path: String) {
        DispatchQueue.global(qos: .background).async {
            do {
                let imgPath = self.imageDirectory.appendingPathComponent("\(path)")
                try self.fileManager.removeItem(atPath: imgPath)
            } catch _ as NSError {
                fatalError()
            }
        }
    }
    
    func retrieveImage(named: String, width: CGFloat, completion: @escaping (UIImage?) -> ()) {
        DispatchQueue.global(qos: .background).async {
            var _image = UIImage(contentsOfFile: self.imageDirectory.appendingPathComponent("\(named)"))
            if let image = _image {
                if width != ORIGINAL_WIDTH {
                    let scale = width / image.size.width
                    UIGraphicsBeginImageContext(CGSize(width: image.size.width * scale, height: image.size.height * scale))
                    image.draw(in: CGRect(x: 0, y: 0, width: image.size.width * scale, height: image.size.height * scale))
                    let newImage = UIGraphicsGetImageFromCurrentImageContext()
                    _image = newImage!
                    UIGraphicsEndImageContext()
                }
            }
            DispatchQueue.main.async {
                completion(_image)
            }
        }
    }
    
    func saveMetadata() {
        DispatchQueue.global(qos: .background).async {
            let imageInfo = NSMutableDictionary()
            var imageInfoData = [NSMutableDictionary]()
            for i in 0 ..< self.imageInfoArray.count {
                let info = self.imageInfoArray[i]
                var color = info.color.cgColor.components!
                //if there are not 4 elements (RGBA), just keep repeating the last one present (but not the very last since that is alpha)
                while color.count < 4 {
                    color.insert(color[color.count - 2], at: color.count - 1)
                }
                let dict = NSMutableDictionary()
                dict.addEntries(from: [NAME: info.name, WIDTH: info.width, SCALED_WIDTH: info.scaledWidth, COLOR: color])
                imageInfoData.append(dict)
            }
            imageInfo.setValue(imageInfoData, forKey: IMAGE_INFO_ARRAY)
            imageInfo.setValue(self.imageCounter, forKey: IMAGE_COUNTER)
            imageInfo.write(toFile: self.imagePList as String, atomically: false)
        }
    }
}
