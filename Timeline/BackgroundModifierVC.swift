//
//  BackgroundModifierVC.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 7/24/17.
//  Copyright © 2017 Edumacation!. All rights reserved.
//

import UIKit
import BSImagePicker
import Photos

protocol BackgroundModifierDelegate {
    func removeContainerView()
    func timelineName() -> String
    func updateImageCache(imagePaths: [String])
}

class BackgroundModifierVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, ImageLayoutDelegate {

    @IBOutlet weak var addToEnd: UIButton!
    @IBOutlet weak var addAfter: UIButton!
    @IBOutlet weak var moveToFront: UIButton!
    @IBOutlet weak var moveToEnd: UIButton!
    @IBOutlet weak var delete: UIButton!
    @IBOutlet weak var lblMessage: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var delegate: BackgroundModifierDelegate!
    var layout: BackgroundModifierLayout!
    var filePaths = [String]()
    var cacheImages: CacheArray<Data>!
    
    @IBAction func item(_ sender: Any) {
        collectionView.reloadData()
        collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
    }
    // Stores a dictionary whose elements are 1. the next int to to use for saving an image
    // and 2. the image ordering array
    var imageInfo: NSMutableDictionary!
    var pListPath: NSString!
    var imgDirectory: NSString!
    // Each element in the selectedStatuses array corresponds to whether the image at the
    // index is selected
    var selectedStatuses = [Bool]()
    // For order preservation purposes, the selectedIndices array stores which elements have
    // selected and the order in which they were selected
    var selectedIndices = [IndexPath]()
    var selectedCount: Int {
        set {
            if newValue == 0 {
                lblMessage.text = "Hold and drag to reorder images"
                lblMessage.textColor = UIColor.black
            }
        } get {
            return selectedIndices.count
        }
    }
    
    var insertionIndex = 0
    var shouldRefresh = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.allowsMultipleSelection = false
        if let layout = collectionView?.collectionViewLayout as? BackgroundModifierLayout {
            self.layout = layout
            self.layout.delegate = self
        }
        //create references for the filesystem and current timeline directory
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        imgDirectory = documents.appendingPathComponent("\(TIMELINE_IMAGE_DIRECTORY)/\(delegate.timelineName())") as NSString
        print("\(imgDirectory)")
        //retrieve imageInfo plist from directory
        pListPath = imgDirectory.appendingPathComponent("\(IMAGE_INFO_PLIST)") as NSString
        imageInfo = NSMutableDictionary(contentsOfFile: pListPath as String)
    
        //retrieve all image paths for the specific timeline from the filesystem
//        for imagePath in (imageInfo?.value(forKey: IMAGE_ORDERING_ARRAY) as! [String]) {
//            filePaths.append(imagePath)
//        }
        delegate.updateImageCache(imagePaths: filePaths)
        cacheImages = CacheArray<Data>(beginningCounter: 0)
        
        //configure long press gestures
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(BackgroundModifierVC.handleLongGesture(_:)))
        self.collectionView.addGestureRecognizer(longPressGesture)

        // Do any additional setup after loading the view.
        setEnabledButtons()
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: Notification.Name.UIApplicationWillResignActive, object: nil)
    }
    
    @objc func appMovedToBackground() {
        imageInfo.setValue(filePaths, forKeyPath: IMAGE_ORDERING_ARRAY)
        imageInfo.write(toFile: pListPath as String, atomically: false)
    }
    
////// IB ACTION METHODS
    
    @IBAction func addToEndPressed(_ sender: Any) {
//        let blubber = OpalImagePickerController()
//        blubber.imagePickerDelegate = self
//        insertionIndex = filePaths.count
//        present(blubber, animated: true, completion: nil)
        let imagePicker = BSImagePickerViewController()
        insertionIndex = filePaths.count
        saveSelectedImages(imagePicker: imagePicker)
    }
    
    @IBAction func addAfterPressed(_ sender: Any) {
        let imagePicker = BSImagePickerViewController()
        //The user is only allowed to press addAfter when the selectedItems array has exactly one element
        insertionIndex = selectedIndices.first!.item
        saveSelectedImages(imagePicker: imagePicker)
    }
    
    @IBAction func moveToFrontPressed(_ sender: Any) {
       updateFilePathArray(updateType: .moveToFront)
        reloadLayout(updateType: .moveToFront)
    }
    
    @IBAction func moveToEndPressed(_ sender: Any) {
        updateFilePathArray(updateType: .moveToEnd)
        reloadLayout(updateType: .moveToEnd)
    }
    
    @IBAction func deleteImagesPressed(_ sender: Any) {
        let tempFileNames = updateFilePathArray(updateType: .delete)
        reloadLayout(updateType: .delete)
        deleteImageFiles(imagePaths: tempFileNames!)
    }
    
    @IBAction func donePressed(_ sender: Any) {
        delegate.removeContainerView()
        delegate.updateImageCache(imagePaths: filePaths)
        
        imageInfo.setValue(filePaths, forKeyPath: IMAGE_ORDERING_ARRAY)
        imageInfo.write(toFile: pListPath as String, atomically: false)
    }
    
    func setEnabledButtons() {
        if selectedCount == 0 {
            addToEnd.isEnabled = true
            moveToFront.isEnabled = false
            moveToEnd.isEnabled = false
            delete.isEnabled = false
        } else {
            addToEnd.isEnabled = false
            moveToFront.isEnabled = true
            moveToEnd.isEnabled = true
            delete.isEnabled = true
            
            if selectedCount == 1 {
                addAfter.isEnabled = true
                return
            }
        }
        addAfter.isEnabled = false
    }
    
    private func updateFilePathArray(updateType: UpdateAction) -> [String]? {
        var tempFileNames = [String]()
        
        for indexPath in selectedIndices {
            tempFileNames.append(filePaths[indexPath.item])
            filePaths[indexPath.item] = ""
        }
        
        filePaths = filePaths.filter({
            !($0 == "")
        })
        
        if updateType == .moveToFront {
            filePaths.insert(contentsOf: tempFileNames, at: 0)
        } else if updateType == .moveToEnd {
            filePaths.append(contentsOf: tempFileNames)
        } else if updateType == .delete {
            return tempFileNames
        }
        
        return nil
    }
    
    private func reloadLayout(updateType: UpdateAction) {
        
        if updateType != UpdateAction.insert {
            let invalidationContext = BackgroundModifierInvalidationContext()
            invalidationContext.updateType = updateType
            invalidationContext.invalidateItems(at: selectedIndices)
            layout.invalidateLayout(with: invalidationContext)
        }
        
        collectionView.reloadData()
        selectedStatuses = [Bool](repeatElement(false, count: filePaths.count))
        selectedIndices.removeAll()
        selectedCount = 0
        setEnabledButtons()
        collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
    }
    
    func deleteImageFiles(imagePaths: [String]) {
        let fileManager = FileManager.default
        for path in imagePaths {
            do {
                let imgPath = imgDirectory.appendingPathComponent("\(path)")
                try fileManager.removeItem(atPath: imgPath)
            }
            catch let error as NSError {
                fatalError()
            }

        }
    }
  

//////COLLECTION VIEW METHODS
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filePaths.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as? BackgroundModifierImageCell {
            if indexPath.item < cacheImages.beginningCounter {
                let path = imgDirectory.appendingPathComponent("\(filePaths[indexPath.item])")
                cell.imgView.image = resizeImage(image: UIImage(contentsOfFile: path)!)
            } else {
                cell.imgView.image = resizeImage(image: UIImage(data: cacheImages.cacheArray[indexPath.item - cacheImages.beginningCounter])!)
            }
            
            cell.didSelect = selectedStatuses[indexPath.item]
            cell.layer.zPosition = 100
            return cell
        }
        
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? BackgroundModifierImageCell {
            cell.didSelect = !cell.didSelect
            selectedStatuses[indexPath.item] = !selectedStatuses[indexPath.item]
            if cell.didSelect {
                selectedIndices.append(indexPath)
            } else {
                selectedIndices.remove(at: selectedIndices.index(of: indexPath)!)
            }
            if (selectedIndices.count == 0) {
                lblMessage.text = "Hold and drag to reorder images"
                lblMessage.textColor = UIColor.black
            }
            setEnabledButtons()
        }
    }
    
    @objc func handleLongGesture(_ gesture: UILongPressGestureRecognizer) {
        switch(gesture.state) {
        case UIGestureRecognizerState.began:
            guard let selectedIndexPath = self.collectionView.indexPathForItem(at: gesture.location(in: self.collectionView)) else {
                break
            }
            if selectedCount == 0 {
                collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
            } else {
                lblMessage.text = "❗️Make sure all images are unselected before reordering ❗️"
                lblMessage.textColor = UIColor.red
            }
        case UIGestureRecognizerState.changed:
            if true {
                collectionView.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
            }
        case UIGestureRecognizerState.ended:
            shouldRefresh = false
            collectionView.endInteractiveMovement()
            collectionView.reloadData()
            
        default:
            collectionView.cancelInteractiveMovement()
        }

        
    }
    
    func collectionView(_ collectionView: UICollectionView, targetIndexPathForMoveFromItemAt originalIndexPath: IndexPath, toProposedIndexPath proposedIndexPath: IndexPath) -> IndexPath {
        let currentAttr = collectionView.layoutAttributesForItem(at: originalIndexPath)!
        let destAttr = collectionView.layoutAttributesForItem(at: proposedIndexPath)!
        if originalIndexPath.item != proposedIndexPath.item {
            if ((proposedIndexPath.item > originalIndexPath.item) && (currentAttr.frame.maxX > destAttr.frame.maxX)) {
                return proposedIndexPath
            } else if ((proposedIndexPath.item < originalIndexPath.item) && (currentAttr.frame.minX < destAttr.frame.minX)) {
                return proposedIndexPath
            } else {
                return originalIndexPath
            }
        } else {
            return originalIndexPath
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if shouldRefresh {
            let file = filePaths.remove(at: sourceIndexPath.item)
            filePaths.insert(file, at: destinationIndexPath.item)
        }
    }
    
    func resizeImage(image: UIImage) -> UIImage {
        let size = image.size
        let scale = collectionView.frame.height / size.height
        UIGraphicsBeginImageContext(CGSize(width: size.width * scale, height: size.height * scale))
        image.draw(in: CGRect(x: 0, y: 0, width: size.width * scale, height: size.height * scale))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }


/////IMAGE INFO DELEGATE METHODS
    
    func getSizeAtIndexPath(indexPath: IndexPath) -> CGSize {
        var tempImg: UIImage
        if indexPath.item < cacheImages.beginningCounter {
            let path = imgDirectory.appendingPathComponent("\(filePaths[indexPath.item])")
            tempImg = UIImage(contentsOfFile: path)!
        } else {
            tempImg = UIImage(data: cacheImages.cacheArray[indexPath.item - cacheImages.beginningCounter])!
        }

        return tempImg.size
    }
    
    func setShouldRefresh() {
        shouldRefresh = true
    }
    
//IMAGE PICKER DELEGATE
    
    func saveSelectedImages(imagePicker: BSImagePickerViewController) {
        bs_presentImagePickerController(imagePicker, animated: true,
            select: nil,
            deselect: nil,
            cancel: nil,
            finish: {(assets) in
                let photoManager = PHImageManager.default()
                var counter = self.imageInfo?.value(forKey: IMAGE_COUNTER) as! Int
                var indexPaths = [IndexPath]()
                let options = PHImageRequestOptions()
                options.isSynchronous = true
                for (index, asset) in assets.enumerated() {
                    photoManager.requestImageData(for: asset, options: options, resultHandler: {(data, title, orientation, info) -> Void in
                        let tempImage = UIImage(data: data!)
                        let imageData = UIImageJPEGRepresentation(tempImage!, 0.9)
                        let imagePath = "/image\(counter + index).jpg"
                        self.cacheImages.cacheArray.append(imageData!)
                        
                        self.filePaths.insert(imagePath, at: self.insertionIndex + index)
                        self.selectedStatuses.append(false)
                        indexPaths.append(IndexPath(item: self.insertionIndex + index, section: 0))
                    })
                }
                self.cacheImages.beginningCounter = counter
                self.imageInfo.setValue(counter + assets.count, forKeyPath: IMAGE_COUNTER)
                
                DispatchQueue.main.async {
                    if self.insertionIndex != self.filePaths.count {
                        let invalidationContext = BackgroundModifierInvalidationContext()
                        invalidationContext.updateType = .insert
                        invalidationContext.insertionCount = indexPaths.count
                        invalidationContext.invalidateItems(at: [IndexPath(item: self.insertionIndex, section: 0)])
                        self.layout.invalidateLayout(with: invalidationContext)
                        self.reloadLayout(updateType: .insert)
                    }
                    FileSystemOperator.saveImages(cachedImageData: self.cacheImages, imageDirectory: self.imgDirectory, startCounter: counter)
                }
        }, completion: nil)
    }
    
    
    
//    func imagePicker(_ picker: OpalImagePickerController, didFinishPickingAssets assets: [PHAsset]) {
//        picker.dismiss(animated: true, completion: nil)
//    
//        let photoManager = PHImageManager.default()
//        let fileManager = FileManager.default
//        var counter = imageInfo?.value(forKey: IMAGE_COUNTER) as! Int
//        var paths = [IndexPath]()
//        
//        let backgroundThread = DispatchQueue.global(qos: .userInitiated)
//        let options = PHImageRequestOptions()
//        options.isSynchronous = true
//        
//        backgroundThread.sync {
//            for (index, asset) in assets.enumerated() {
//                photoManager.requestImageData(for: asset, options: options, resultHandler: {(data, title, orientation, info) -> Void in
//                    let tempImage = UIImage(data: data!)
//                    let imageData = UIImageJPEGRepresentation(tempImage!, 0.9)
//                    
//                    let imagePath = "/image\(counter).jpg"
//                    let imageFile = self.imgDirectory.appendingPathComponent(imagePath)
//                    fileManager.createFile(atPath: imageFile, contents: imageData, attributes: nil)
//                    
//                    self.filePaths.insert(imagePath, at: self.insertionIndex + index)
//                    self.selectedStatuses.append(false)
//                    paths.append(IndexPath(item: self.insertionIndex + index, section: 0))
//                    
//                    counter += 1
//                })
//            }
//            imageInfo.setValue(counter, forKeyPath: IMAGE_COUNTER)
//        }
//        
//        if self.insertionIndex != self.filePaths.count {
//            let invalidationContext = BackgroundModifierInvalidationContext()
//            invalidationContext.updateType = .insert
//            invalidationContext.insertionCount = paths.count
//            invalidationContext.invalidateItems(at: [IndexPath(item: self.insertionIndex, section: 0)])
//            self.layout.invalidateLayout(with: invalidationContext)
//        }
//                
//        self.reloadLayout(updateType: .insert)
//    }
}
