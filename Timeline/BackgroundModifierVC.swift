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

class BackgroundModifierVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var addToEnd: UIButton!
    @IBOutlet weak var addAfter: UIButton!
    @IBOutlet weak var moveToFront: UIButton!
    @IBOutlet weak var moveToEnd: UIButton!
    @IBOutlet weak var delete: UIButton!
    @IBOutlet weak var lblMessage: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    var fileSystemOperator: FileSystemOperator!
    weak var delegate: BackgroundModifierDelegate!
    
    //keep track of both my collection view and regular timeline height
    var editorHeight: CGFloat!
    var timelineHeight: CGFloat!
    //selectedImages keeps track of which images were selected, selectedIndices keeps tracks of
    //the order of the selected images
    var selectedImages = [Bool]()
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
    var updateIndex = 0
    var insertionIndex = 0
    var semaphore = 0   //hehe lame, but used for keeping track of color completions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //initialize layout
        contentView.layer.borderColor = UIColor.lightGray.cgColor
        contentView.layer.borderWidth = TEXT_FIELD_BORDER
        contentView.layer.cornerRadius = TEXT_FIELD_RADIUS
        //set up collectionview
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.allowsMultipleSelection = false
        
        //configure long press gestures
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(BackgroundModifierVC.handleLongGesture(_:)))
        self.collectionView.addGestureRecognizer(longPressGesture)
        
        //set up the background modifier buttons. Only the add to end button should be enabled at this point
        setEnabledButtons()
        editorHeight = collectionView.frame.height
    }
    
    override func viewWillAppear(_ animated: Bool) {
        updateIndex = fileSystemOperator.imageInfoArray.count
    }
    
////// IB ACTION METHODS
    @IBAction func addToEndPressed(_ sender: Any) {
        let imagePicker = BSImagePickerViewController()
        insertionIndex = fileSystemOperator.imageInfoArray.count
        addImagesToBackground(imagePicker: imagePicker)
    }
    
    @IBAction func addAfterPressed(_ sender: Any) {
        let imagePicker = BSImagePickerViewController()
        //The user is only allowed to press addAfter when the selectedItems array has exactly one element
        insertionIndex = selectedIndices.first!.item + 1
        addImagesToBackground(imagePicker: imagePicker)
        updateIndex = insertionIndex < updateIndex ? insertionIndex : updateIndex
    }
    
    @IBAction func moveToFrontPressed(_ sender: Any) {
        updateImageOrdering(updateType: .MOVE_FRONT)
        reloadLayout()
    }
    
    @IBAction func moveToEndPressed(_ sender: Any) {
        updateImageOrdering(updateType: .MOVE_END)
        reloadLayout()
    }
    
    @IBAction func deleteImagesPressed(_ sender: Any) {
        updateImageOrdering(updateType: .DELETE)
        reloadLayout()
    }
    
    @IBAction func donePressed(_ sender: Any) {
        delegate.backgroundModifierDonePressed(updateAt: updateIndex)
        fileSystemOperator.saveMetadata()
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
    
    private func updateImageOrdering(updateType: UpdateAction) {
        var tempIndices = [ImageInfo]()
        //this has to be done very delicately...first add the objects at the new indices, THEN remove the old objects all at once
        for indexPath in selectedIndices {
            tempIndices.append(fileSystemOperator.imageInfoArray[indexPath.item])
            updateIndex = indexPath.item < updateIndex ? indexPath.item : updateIndex
            //use to identify invalid indices
            fileSystemOperator.imageInfoArray[indexPath.item].width = -1
        }
        fileSystemOperator.imageInfoArray = fileSystemOperator.imageInfoArray.filter { (info) -> Bool in
            return info.width != -1
        }
        
        if updateType == .MOVE_FRONT {
            fileSystemOperator.imageInfoArray.insert(contentsOf: tempIndices, at: 0)
            updateIndex = 0
        } else if updateType == .MOVE_END {
            fileSystemOperator.imageInfoArray.append(contentsOf: tempIndices)
        } else if updateType == .DELETE {
            for info in tempIndices {
                fileSystemOperator.deleteImage(path: info.name)
            }
        }
        fileSystemOperator.saveMetadata()
    }
    
    private func reloadLayout() {
        //reset all images to unselected
        selectedImages = [Bool](repeating: false, count: fileSystemOperator.imageInfoArray.count)
        selectedIndices.removeAll()
        selectedCount = 0
        //reset the buttons. At this point, only the add to end button should be enabled
        setEnabledButtons()
        //now reload the collectionview
        collectionView.reloadData()
    }


//////COLLECTION VIEW METHODS
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fileSystemOperator.imageInfoArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as? BackgroundModifierImageCell {
            fileSystemOperator.retrieveImage(named: fileSystemOperator.imageInfoArray[indexPath.item].name, width: fileSystemOperator.imageInfoArray[indexPath.item].scaledWidth) { (image) in
                cell.image = image
            }
            cell.didSelect = selectedImages[indexPath.item]
//            cell.layer.zPosition = 100
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? BackgroundModifierImageCell {
            cell.didSelect = !cell.didSelect
            selectedImages[indexPath.item] = !selectedImages[indexPath.item]
            if cell.didSelect {
                selectedIndices.append(indexPath)
            } else {
                selectedIndices.remove(at: selectedIndices.index(of: indexPath)!)
            }
            if (selectedIndices.count == 0) {
                lblMessage.text = "Hold and drag to reorder images"
                lblMessage.textColor = UIColor.darkGray
            }
            setEnabledButtons()
        }
    }
    
    
    @objc func handleLongGesture(_ gesture: UILongPressGestureRecognizer) {
        switch(gesture.state) {
        case UIGestureRecognizer.State.began:
            guard let selectedIndexPath = self.collectionView.indexPathForItem(at: gesture.location(in: self.collectionView)) else {
                break
            }
            if selectedCount == 0 {
                collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
            } else {
                lblMessage.text = "❗️Make sure all images are unselected before reordering ❗️"
                lblMessage.textColor = UIColor.red
            }
        case UIGestureRecognizer.State.changed:
            collectionView.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
        case UIGestureRecognizer.State.ended:
            collectionView.endInteractiveMovement()
        default:
            collectionView.cancelInteractiveMovement()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, targetIndexPathForMoveFromItemAt originalIndexPath: IndexPath, toProposedIndexPath proposedIndexPath: IndexPath) -> IndexPath {
        if originalIndexPath.item != proposedIndexPath.item {
            let info = fileSystemOperator.imageInfoArray.remove(at: originalIndexPath.item)
            fileSystemOperator.imageInfoArray.insert(info, at: proposedIndexPath.item)
            return proposedIndexPath
        }
        return originalIndexPath
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
       
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: fileSystemOperator.imageInfoArray[indexPath.item].scaledWidth , height: collectionView.frame.height)
    }

    
//IMAGE PICKER DELEGATE
    func addImagesToBackground(imagePicker: BSImagePickerViewController) {
        bs_presentImagePickerController(imagePicker, animated: true,
            select: nil,
            deselect: nil,
            cancel: nil,
            finish: {[unowned self](assets) in
                let photoManager = PHImageManager.default()
                let options = PHImageRequestOptions()
                options.isSynchronous = true
                let dispatch_group = DispatchGroup()
                for _ in 0 ..< assets.count {
                    dispatch_group.enter()
                }
                self.doneButton.isEnabled = false   //do not let the user leave during this delicate time
                autoreleasepool {
                    for (index, asset) in assets.enumerated() {
                        photoManager.requestImage(for: asset, targetSize: CGSize(width: CGFloat(asset.pixelWidth), height: CGFloat(asset.pixelHeight)), contentMode: .aspectFit, options: options, resultHandler:
                            {[unowned self] (result, info) in
                                if let image = result {
                                    self.fileSystemOperator.saveImage(image: image, index: self.insertionIndex + index, dispatch_group: dispatch_group)
                                    self.selectedImages.append(false)
                                }
                            })
                    }
                }
                    DispatchQueue.main.async {
                        self.reloadLayout()
                    }
                    dispatch_group.notify(queue: DispatchQueue.main, work: DispatchWorkItem {
                        //now all the colors have been loaded from this particular transaction
                        self.reloadLayout()
                        self.doneButton.isEnabled = true
                        self.fileSystemOperator.saveMetadata()
                    })
            }, completion: nil)
    }
}
