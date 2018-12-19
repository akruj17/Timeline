//
//  ViewController.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 6/15/17.
//  Copyright © 2017 Edumacation!. All rights reserved.
//

import UIKit
import RealmSwift

protocol TitleScreenLayoutDelegate: class {
    func updateNumTitles(numTitles: Int)
}

class TitleScreenVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UINavigationControllerDelegate, TitleScreenLayoutDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var containerLeadingMargin: NSLayoutConstraint!
    @IBOutlet weak var containerTrailingMargin: NSLayoutConstraint!
    
    @IBOutlet weak var collectionLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionTrailingConstraint: NSLayoutConstraint!
    
    var firstImagesDirectory: NSString!
    var imageDataArray: [Data]!
    
    weak var layout: TitleScrnLayout!
    var collectionViewLoadedDetector = 0
    var timelineNames: Results<Timeline>?
    var indicator = UIActivityIndicatorView()
    var updateScratch = 0 // used to store the change in number of timeline titles

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        imageDataArray = [Data]()
        collectionView.dataSource = self
        collectionView.delegate = self
        if let layout = collectionView?.collectionViewLayout as? TitleScrnLayout {
            self.layout = layout
        }
        navigationController?.delegate = self
        
        //Obtain all timeline names from the database, and sort them chronologically
        let realm = try! Realm()
        timelineNames = realm.objects(Timeline.self)
        //Set up long press gesture recognizers for the title cells if the user wants to delete items
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(gestureReconizer:)))
        lpgr.minimumPressDuration = 0.5
        lpgr.delaysTouchesBegan = true
        lpgr.delegate = self
        collectionView.addGestureRecognizer(lpgr)
        
//        firstImagesDirectory = documents.appendingPathComponent("\(TIMELINE_IMAGE_DIRECTORY)/\(FIRST_IMAGES_DIRECTORY)") as NSString
        
//        let fileManager = FileManager.default
//        for timeline in timelineNames! {
//            let path = firstImagesDirectory.appendingPathComponent("/\(timeline.name).jpg")
//            let img = UIImage(contentsOfFile: path)
//            if let backgroundImage = img {
//                let imgData = UIImageJPEGRepresentation(backgroundImage, 0.3)!
//                imageDataArray.append(imgData)
//            } else {
//                imageDataArray.append(nil)
//            }
//        }
        
        
       //setupBackground()
    }
    
    override func viewDidLayoutSubviews() {
        updateCollectionViewLength()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        indicator.stopAnimating()
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewController is TitleScreenVC {
            timelineNames = timelineNames!.sorted(byKeyPath: "createdAt", ascending: true)
            updateLayout()
        }
    }
    
    func updateLayout() {
        if updateScratch != 0 {
            let invalidationContext = UICollectionViewLayoutInvalidationContext()
            let currentItemLength = collectionView.numberOfItems(inSection: 0)
            if updateScratch > 0 {
                invalidationContext.invalidateItems(at: [IndexPath(item: currentItemLength - 1, section: 0)])
            } else if updateScratch < 0 {
                invalidationContext.invalidateItems(at: [IndexPath(item: currentItemLength - 1, section: 0), IndexPath(item: currentItemLength - 2, section: 0)])
            }
            layout.invalidateLayout(with: invalidationContext)
            collectionView.reloadData()
            collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
            collectionView.scrollToItem(at: IndexPath(item: (collectionView.numberOfItems(inSection: 0) - 1), section: 0), at: .right, animated: false)
            updateScratch = 0
        } else {
            collectionView.reloadData()
        }
    }
    
    func updateCollectionViewLength() {
        //set the timeline visual length dependent on the number of collectionview objects.
        if collectionViewLoadedDetector >= 1 {
            let idealContentWidth = collectionView.contentSize.width
            if idealContentWidth < (view.bounds.width - CGFloat(2 * TITLE_TIMELINE_PADDING)) {
                containerLeadingMargin.constant = ((view.bounds.width - idealContentWidth) / 2) - view.layoutMargins.left
                containerTrailingMargin.constant = ((view.bounds.width - idealContentWidth) / 2) - view.layoutMargins.right
                collectionView.isScrollEnabled = false
            } else {
                containerLeadingMargin.constant = 120
                containerTrailingMargin.constant = 120
                collectionView.isScrollEnabled = true
                collectionView.scrollToItem(at: IndexPath(item: (timelineNames?.count)!, section: 0), at: .right, animated: false)
            }
        }
        
        collectionViewLoadedDetector += 1
    }

//////////////////COLLECTIONVIEW METHODS
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return timelineNames!.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "titleCell", for: indexPath) as? TitleScreenCell {
            let isTopRow = indexPath.item % 2 == 0 ? true: false
            
            //Configure collectionview cells to appear as timeline objects. Last index has a special configuration to say "New Timeline"
            let title = (indexPath.item < timelineNames!.count) ? timelineNames![indexPath.item].name : "New Timeline"
            if indexPath.item < imageDataArray.count {
                cell.configure(isTopRow: isTopRow, title: title, color: UIColor.darkGray, image: nil)
            } else {
                cell.configure(isTopRow: isTopRow, title: title, color: UIColor.darkGray, image: nil)
            }
            cell.layoutIfNeeded()
         //   cell.backgroundColor = UIColor.red
            return cell
        }
        
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //Segue to either the actual timeline or new timeline editor depending on the collectionview cell clicked
        if indexPath.row == (collectionView.numberOfItems(inSection: 0) - 1) {
            performSegue(withIdentifier: "titleScrnToEditor", sender: nil)
        } else {
                performSegue(withIdentifier: "titleScrnToTimeline", sender: indexPath.item)
        }
    }
    
    @objc func handleLongPress(gestureReconizer: UILongPressGestureRecognizer) {
        let p = gestureReconizer.location(in: self.collectionView)
        let indexPath = self.collectionView.indexPathForItem(at: p)
        if let index = indexPath {
            if index.item != collectionView.numberOfItems(inSection: 0) - 1 {
                let incompleteAlert = UIAlertController(title: "Warning", message: nil, preferredStyle: .alert)
                incompleteAlert.addAction(UIAlertAction(title: "OK", style: .destructive, handler: {[unowned self] action in
                    DispatchQueue.global(qos: .background).sync {
                        RealmOperator.deleteTimelineFromDatabase(timeline: self.timelineNames![index.item])
                    }
                    self.updateScratch = -1
                    self.updateLayout()
                    self.updateCollectionViewLength()
                    self.collectionView.reloadItems(at: self.collectionView.indexPathsForVisibleItems)
                    self.collectionView.reloadData()
                }))
                incompleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                incompleteAlert.title = "Are you sure you want to delete this timeline? This action cannot be undone later."
                self.present(incompleteAlert, animated: true, completion: nil)
            }
        }
    }
    
    //not used right now
    func setupBackground() {
        firstImagesDirectory = documents.appendingPathComponent("\(TIMELINE_IMAGE_DIRECTORY)/\(FIRST_IMAGES_DIRECTORY)") as NSString
        let fileManager = FileManager.default
        let directoryContents = try! fileManager.contentsOfDirectory(atPath: firstImagesDirectory as String)

        var numbersToChoose = Set<Int>()
        // add a maximum of 5 images
        while (numbersToChoose.count < 5 && numbersToChoose.count < directoryContents.count) {
            numbersToChoose.insert(Int(arc4random_uniform(UInt32(directoryContents.count))))
            }

        if (numbersToChoose.count != 0) {
            let imageSize = (self.view.frame.width / CGFloat(numbersToChoose.count)) * (1 / 0.85)
            var xPosition: CGFloat = 0
            for path in directoryContents {
                let image = UIImage(contentsOfFile: firstImagesDirectory.appendingPathComponent(path))
                let imageView = UIImageView(frame: CGRect(x: xPosition, y: 0, width: imageSize, height: self.view.frame.height))
                xPosition += imageSize * 0.85
                imageView.image = image
                imageView.layer.zPosition = -1
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true

                let gradientLayer = CAGradientLayer()
                gradientLayer.frame = CGRect(x: 0, y: 0, width: imageView.frame.width, height: imageView.frame.height)
                gradientLayer.colors = [
                    UIColor(red: 0, green: 0, blue: 0, alpha: 0.01).cgColor,
                    UIColor(red: 0, green: 0, blue: 0, alpha: 0.7).cgColor,
                    UIColor(red: 0, green: 0, blue: 0, alpha: 0.01).cgColor]
                
                gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0);
                gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.0);
                imageView.layer.mask = gradientLayer
                
                self.view.addSubview(imageView)
            }
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "titleScrnToEditor" {
            if let editorVC = segue.destination as? TimelineEditorVC {
                editorVC.isNewTimeline = true
                editorVC.titleDelegate = self
            }
        } else if segue.identifier == "titleScrnToTimeline" {
            if let timelineVC = segue.destination as? TimelineVC {
                let timelineName = timelineNames![sender as! Int]
                timelineVC.timeline = timelineName.copy() as! Timeline
                timelineVC.titleDelegate = self
            }
        }
    }
    
    func updateNumTitles(numTitles: Int) {
        updateScratch = numTitles
    }
}

