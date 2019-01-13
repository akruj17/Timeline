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

    func prepareForImage(size: CGSize, index: Int) -> ImageInfo {
        let imagePath = "/image\(self.imageCounter).jpg"
        imageCounter += 1
        let aspectRatio = size.width / size.height
        let info = ImageInfo.init(name: imagePath, width: timelineCollectionHeight * aspectRatio, scaledWidth: backgroundCollectionHeight * aspectRatio, color: UIColor.darkGray)
        self.imageInfoArray.insert(info, at: index)
        return info
    }
    
    func saveImage(image: UIImage, info: ImageInfo) {
        DispatchQueue.global(qos: .background).async {
            let imageFile = self.imageDirectory.appendingPathComponent(info.name)
            // scale the image before saving it
            let newImage = image.resize(targetSize: CGSize(width: info.width, height: self.timelineCollectionHeight))
            self.fileManager.createFile(atPath: imageFile, contents: newImage.jpegData(compressionQuality: 0.5), attributes: nil)
            Palette.generateWith(configuration: PaletteConfiguration(image: image), queue: DispatchQueue.global(qos: .background)) { (palette) in
                let color = palette.vibrantColor(defaultColor: UIColor.darkGray)
                info.color = color
            }
            DispatchQueue.main.async {
                if let cell = info.cell as? BackgroundModifierImageCell {
                    cell.image = image.resize(targetSize: CGSize(width: info.scaledWidth, height: self.backgroundCollectionHeight))
                }  else if let cell = info.cell as? TimelineImageCell {
                    cell.imgView.image = newImage
                }
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
    
    func retrieveImage(index: Int, widthType: WidthType) {
        DispatchQueue.global(qos: .background).async {
            let info = self.imageInfoArray[index]
            var _image = UIImage(contentsOfFile: self.imageDirectory.appendingPathComponent("\(info.name)"))
            if let image = _image {
                if widthType == .SCALED {
                    _image = image.resize(targetSize: CGSize(width: info.scaledWidth, height: self.backgroundCollectionHeight))
                }
            }
            DispatchQueue.main.async {
                if let cell = info.cell as? BackgroundModifierImageCell {
                    cell.image = _image
                } else if let cell = info.cell as? TimelineImageCell {
                    cell.imgView.image = _image
                }
            }
        }
    }
    
    func imageUnableToDownload(info: ImageInfo) {
        info.width = -1
        imageInfoArray.removeAll { (info) -> Bool in
            return info.width < 0
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

extension UIImage {
    
    func resize(targetSize: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size:targetSize).image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
}
