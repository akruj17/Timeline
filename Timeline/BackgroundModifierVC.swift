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

protocol BackgroundModifierDelegate: class {
    func removeContainerView()
    func timelineName() -> String
    func updateBackgroundImages(imageStatuses: [imageStatusTuple])
}

class BackgroundModifierVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, ImageLayoutDelegate {

    @IBOutlet weak var addToEnd: UIButton!
    @IBOutlet weak var addAfter: UIButton!
    @IBOutlet weak var moveToFront: UIButton!
    @IBOutlet weak var moveToEnd: UIButton!
    @IBOutlet weak var delete: UIButton!
    @IBOutlet weak var lblMessage: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    weak var delegate: BackgroundModifierDelegate?
    var layout: BackgroundModifierLayout!
    var imageStatusesArray: [imageStatusTuple]!
    var deletedPaths: [String]!
    
    @IBAction func item(_ sender: Any) {
        collectionView.reloadData()
        collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
    }
    // Stores a dictionary whose elements are 1. the next int to to use for saving an image
    // and 2. the image ordering array
    var imageInfo: NSMutableDictionary!
    var pListPath: NSString!
    var imgDirectory: NSString!
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
        //initialize variables
        imageStatusesArray = [imageStatusTuple]()
        deletedPaths = [String]()
        //activityIndicator.startAnimating()
        if let layout = collectionView?.collectionViewLayout as? BackgroundModifierLayout {
            self.layout = layout
            self.layout.delegate = self
        }
        
        //set up collectionview
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.allowsMultipleSelection = false
        
        //configure long press gestures
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(BackgroundModifierVC.handleLongGesture(_:)))
        self.collectionView.addGestureRecognizer(longPressGesture)
        
        //set up the background modifier buttons. Only the add to end button should be enabled at this point
        setEnabledButtons()
        
        //set up notifications so that if the user quits the app mid modification, changes will still be saved.
        let notificationCenter = NotificationCenter.default
//        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: Notification.Name.UIApplicationWillResignActive, object: nil)
        
        //this initializes the background in the actual timeline
        delegate!.updateBackgroundImages(imageStatuses: imageStatusesArray)

        


        // Do any additional setup after loading the view.
        
        
        
    }
    
//    @objc func appMovedToBackground() {
//        imageInfo.setValue(imageStatusesArray.map {$0.0}, forKeyPath: IMAGE_ORDERING_ARRAY)
//        imageInfo.write(toFile: pListPath as String, atomically: false)
//    }
    
////// IB ACTION METHODS
    
    @IBAction func addToEndPressed(_ sender: Any) {
        let imagePicker = BSImagePickerViewController()
        insertionIndex = imageStatusesArray.count
        addImagesToBackground(imagePicker: imagePicker)
    }
    
    @IBAction func addAfterPressed(_ sender: Any) {
        let imagePicker = BSImagePickerViewController()
        //The user is only allowed to press addAfter when the selectedItems array has exactly one element
        insertionIndex = selectedIndices.first!.item + 1
        addImagesToBackground(imagePicker: imagePicker)
    }
    
    @IBAction func moveToFrontPressed(_ sender: Any) {
        updateImageStatusesArray(updateType: .moveToFront)
        reloadLayout(updateType: .moveToFront)
    }
    
    @IBAction func moveToEndPressed(_ sender: Any) {
        updateImageStatusesArray(updateType: .moveToEnd)
        reloadLayout(updateType: .moveToEnd)
    }
    
    @IBAction func deleteImagesPressed(_ sender: Any) {
        updateImageStatusesArray(updateType: .delete)
        reloadLayout(updateType: .delete)
    }
    
    @IBAction func donePressed(_ sender: Any) {
        
            self.delegate!.updateBackgroundImages(imageStatuses: self.imageStatusesArray)


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
    
    private func updateImageStatusesArray(updateType: UpdateAction) {
        var tempImageData = [imageStatusTuple]()
        //this has to be done very delicately...first add the objects at the new indices, THEN remove the old objects all at once
        for indexPath in selectedIndices {
            tempImageData.append(imageStatusesArray[indexPath.item])
            imageStatusesArray[indexPath.item].filePath = nil
        }
        imageStatusesArray = imageStatusesArray.filter({
            !($0.0 == nil)
        })

        if updateType == .moveToFront {
            imageStatusesArray.insert(contentsOf: tempImageData, at: 0)
        } else if updateType == .moveToEnd {
            imageStatusesArray.append(contentsOf: tempImageData)
        } else if updateType == .delete {
            for image in tempImageData {
                if let path = image.filePath {
                    deletedPaths.append(path)
                }
            }
        }
    }
    
    func getDeletedPaths() -> [String] {
        return deletedPaths
    }
    
    private func reloadLayout(updateType: UpdateAction) {
        if updateType != UpdateAction.insert {
            //insertion requires extra work and isn't handled here
            let invalidationContext = BackgroundModifierInvalidationContext()
            invalidationContext.updateType = updateType
            invalidationContext.invalidateItems(at: selectedIndices)
            layout.invalidateLayout(with: invalidationContext)
        }
        //reset all images to unselected
        for i in 0 ..< imageStatusesArray.count {
            imageStatusesArray[i].selectedStat = false
        }
        selectedIndices.removeAll()
        selectedCount = 0
        //reset the buttons. At this point, only the add to end button should be enabled
        setEnabledButtons()
        //now reload the collectionview
        collectionView.reloadData()
        collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
    }


//////COLLECTION VIEW METHODS
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageStatusesArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as? BackgroundModifierImageCell {
            cell.imgView.image = FileSystemOperator.resizeImage(image: UIImage(data: imageStatusesArray[indexPath.item].data)!,
                                                                height: collectionView.frame.height)
            cell.didSelect = imageStatusesArray[indexPath.item].selectedStat
            cell.layer.zPosition = 100
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? BackgroundModifierImageCell {
            cell.didSelect = !cell.didSelect
            imageStatusesArray[indexPath.item].selectedStat = !imageStatusesArray[indexPath.item].selectedStat
            if cell.didSelect {
                selectedIndices.append(indexPath)
            } else {
                selectedIndices.remove(at: selectedIndices.index(of: indexPath)!)
            }
            if (selectedIndices.count == 0) {
                lblMessage.text = "Hold and drag to reorder images"
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
            let tuple = imageStatusesArray.remove(at: sourceIndexPath.item)
            imageStatusesArray.insert(tuple, at: destinationIndexPath.item)
        }
    }


/////IMAGE INFO DELEGATE METHODS
    func getSizeAtIndexPath(indexPath: IndexPath) -> CGSize {
        return imageStatusesArray[indexPath.item].largeSize
    }
    
    
    func setShouldRefresh() {
        shouldRefresh = true
    }
    
//IMAGE PICKER DELEGATE
    func addImagesToBackground(imagePicker: BSImagePickerViewController) {
        bs_presentImagePickerController(imagePicker, animated: true,
            select: nil,
            deselect: nil,
            cancel: nil,
            finish: {[unowned self](assets) in
                let photoManager = PHImageManager.default()
                var indexPaths = [IndexPath]()
                let options = PHImageRequestOptions()
                options.isSynchronous = true
                for (index, asset) in assets.enumerated() {
                    autoreleasepool {
                    let newWidth = (collectionHeight / CGFloat(asset.pixelHeight)) * CGFloat(asset.pixelWidth)
                    photoManager.requestImage(for: asset, targetSize: CGSize(width: newWidth, height: collectionHeight), contentMode: PHImageContentMode.aspectFit, options: options, resultHandler: {[unowned self] (result, info) in
                        let imageData = UIImageJPEGRepresentation(result!, 0.3)!
                        self.imageStatusesArray.insert((filePath: nil, data: imageData, selectedStat: false, largeSize: result!.size), at: self.insertionIndex + index)
                            indexPaths.append(IndexPath(item: self.insertionIndex + index, section: 0))
                        })
                    }
                }
                DispatchQueue.main.async {
                    if assets.count > 0 {
                    //the following code updates the layout if images were added to the background
                        let invalidationContext = BackgroundModifierInvalidationContext()
                        invalidationContext.updateType = .insert
                        invalidationContext.insertionCount = indexPaths.count
                        invalidationContext.invalidateItems(at: [IndexPath(item: self.insertionIndex, section: 0)])
                        self.layout.invalidateLayout(with: invalidationContext)
                        self.reloadLayout(updateType: .insert)
                    }
                }

            }, completion: nil)
    }
}
