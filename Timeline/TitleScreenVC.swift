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

class TitleScreenVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UINavigationControllerDelegate, TitleScreenLayoutDelegate, UIGestureRecognizerDelegate, CollectionReloadDelegate, TitleCollectionDelegate {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var containerLeadingMargin: NSLayoutConstraint!
    @IBOutlet weak var containerTrailingMargin: NSLayoutConstraint!
    
    @IBOutlet weak var collectionLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionTrailingConstraint: NSLayoutConstraint!
    
    var firstImagesDirectory: NSString!
    var imageDataArray: [Data]!
    var names = ["A", "B", "C"]
    
    weak var layout: TitleScrnLayout!
    var timelineNames: Results<Timeline>?
    var indicator = UIActivityIndicatorView()
    var updateScratch = 0 // used to store the change in number of timeline titles
    var loadingIndex = -1

    struct TimelineArgs {
        var mode: Int
        var events: [Event]?
        var timeline: Timeline?
        var editsTracker: [[Bool]]?
        var titleInvalid: Bool?
        var requiresEdits: Bool?
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        self.navigationController?.delegate = self
        imageDataArray = [Data]()
        collectionView.dataSource = self
        collectionView.delegate = self
        if let layout = collectionView?.collectionViewLayout as? TitleScrnLayout {
            self.layout = layout
            self.layout.delegate = self
        }
        
        //Obtain all timeline names from the database, and sort them chronologically
        let realm = try! Realm()
        timelineNames = realm.objects(Timeline.self)
        print ("-----------\(String(describing: Realm.Configuration.defaultConfiguration.fileURL))")
        //Set up long press gesture recognizers for the title cells if the user wants to delete items
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(gestureReconizer:)))
        lpgr.minimumPressDuration = 0.5
        lpgr.delaysTouchesBegan = true
        lpgr.delegate = self
        collectionView.addGestureRecognizer(lpgr)

    }

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewController is TitleScreenVC {
            timelineNames = timelineNames!.sorted(byKeyPath: "createdAt", ascending: true)
        }
    }
    
    func updateCollectionWidth(newWidth: CGFloat) {
        //set the timeline visual length dependent on the number of collectionview objects.
        if newWidth < (view.bounds.width - CGFloat(2 * TITLE_TIMELINE_PADDING)) {
            containerLeadingMargin.constant = ((view.bounds.width - newWidth) / 2) - view.layoutMargins.left
            containerTrailingMargin.constant = ((view.bounds.width - newWidth) / 2) - view.layoutMargins.right
            collectionView.isScrollEnabled = false
        } else {
            containerLeadingMargin.constant = TITLE_TIMELINE_PADDING
            containerTrailingMargin.constant = TITLE_TIMELINE_PADDING
            collectionView.isScrollEnabled = true
            collectionView.scrollToItem(at: IndexPath(item: (timelineNames!.count), section: 0), at: .right, animated: false)
        }
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
            cell.configure(isTopRow: isTopRow, title: title, isLoading: indexPath.item == loadingIndex)
            cell.layoutIfNeeded()
            return cell
        }
        // control should not reach here
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == (collectionView.numberOfItems(inSection: 0) - 1) {
            // user clicked on create new timeline
            let args = TimelineArgs(mode: NEW, events: nil, timeline: nil, editsTracker: nil, titleInvalid: nil, requiresEdits: nil)
            self.performSegue(withIdentifier: "titleScrnToEditor", sender: args)
        } else if let cell = collectionView.cellForItem(at: indexPath) as? TitleScreenCell {
            self.loadingIndex = indexPath.item
            cell.setLoading(isLoading: true)
            RealmOperator.retrieveEvents(timeline: timelineNames![indexPath.item].name) { (events, timeline) in
                var editsTracker = [[Bool]]()
                let valid = DataValidator.performValidation(events: &events, editsTracker: &editsTracker, title: timeline)
                if valid.requiresEdits || valid.titleTaken {
                    //edits are required, switch to editor
                    let timelineInvalid = valid.titleEmpty || valid.titleTaken
                    let args = TimelineArgs(mode: INVALID, events: events, timeline: timeline, editsTracker: editsTracker, titleInvalid: timelineInvalid, requiresEdits: valid.requiresEdits)
                    self.performSegue(withIdentifier: "titleScrnToEditor", sender: args)
                } else {
                    //TIMELINE IS VALID SWITCH TO TIMELINE VC
                    let args = TimelineArgs(mode: -1, events: events, timeline: timeline, editsTracker: nil, titleInvalid: nil, requiresEdits: nil)
                    self.performSegue(withIdentifier: "titleScrnToTimeline", sender: args)
                }
            }
        }
    }
    
    // A user holds down on a timeline title. This means they want to delete the timeline
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
//                    self.updateLayout()
                    self.collectionView.reloadItems(at: self.collectionView.indexPathsForVisibleItems)
                    self.collectionView.reloadData()
                }))
                incompleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                incompleteAlert.title = "Are you sure you want to delete this timeline? This action cannot be undone later."
                self.present(incompleteAlert, animated: true, completion: nil)
            }
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "titleScrnToEditor" {
            if let editorVC = segue.destination as? TimelineEditorVC {
                let args = sender as! TimelineArgs
                editorVC.mode = args.mode
                if editorVC.mode == INVALID {
                    editorVC.eventInfoArray = args.events
                    editorVC.timelineTitle = args.timeline
                    editorVC.titleInvalid = args.titleInvalid!
                    editorVC.editsTracker = args.editsTracker!
                    editorVC.requiresEdits = args.requiresEdits!
                }
                editorVC.titleDelegate = self
            }
        } else if segue.identifier == "titleScrnToTimeline" {
            if let timelineVC = segue.destination as? TimelineVC {
                let args = sender as! TimelineArgs
                timelineVC.timeline = args.timeline
                timelineVC.events = args.events
                timelineVC.titleDelegate = self
            }
        }
    }
    

    
    func updateNumTitles(numTitles: Int) {
        updateScratch = numTitles
    }
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if viewController is TimelineEditorVC || viewController is TimelineVC {
            loadingIndex = -1
        }
    }
    
    func updateCollection(updateType: UpdateAction, completion: ((Bool) -> ())?) {
        collectionView.reloadData()
        collectionView.performBatchUpdates(nil, completion: completion)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    

    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        names.append("A")
        collectionView.reloadData()
        collectionView.performBatchUpdates({
            

        }, completion: nil)
    }
}
    
    // code to add images to timeline title backgrounds. This feature
    // is not currently supported because it looks UGLY
//    func addTitleBackgrounds() {
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
//        setupBackground()
//    }
    
//    //not used right now
//    func setupBackground() {
//        firstImagesDirectory = documents.appendingPathComponent("\(TIMELINE_IMAGE_DIRECTORY)/\(FIRST_IMAGES_DIRECTORY)") as NSString
//        let fileManager = FileManager.default
//        let directoryContents = try! fileManager.contentsOfDirectory(atPath: firstImagesDirectory as String)
//
//        var numbersToChoose = Set<Int>()
//        // add a maximum of 5 images
//        while (numbersToChoose.count < 5 && numbersToChoose.count < directoryContents.count) {
//            numbersToChoose.insert(Int(arc4random_uniform(UInt32(directoryContents.count))))
//            }
//
//        if (numbersToChoose.count != 0) {
//            let imageSize = (self.view.frame.width / CGFloat(numbersToChoose.count)) * (1 / 0.85)
//            var xPosition: CGFloat = 0
//            for path in directoryContents {
//                let image = UIImage(contentsOfFile: firstImagesDirectory.appendingPathComponent(path))
//                let imageView = UIImageView(frame: CGRect(x: xPosition, y: 0, width: imageSize, height: self.view.frame.height))
//                xPosition += imageSize * 0.85
//                imageView.image = image
//                imageView.layer.zPosition = -1
//                imageView.contentMode = .scaleAspectFill
//                imageView.clipsToBounds = true
//
//                let gradientLayer = CAGradientLayer()
//                gradientLayer.frame = CGRect(x: 0, y: 0, width: imageView.frame.width, height: imageView.frame.height)
//                gradientLayer.colors = [
//                    UIColor(red: 0, green: 0, blue: 0, alpha: 0.01).cgColor,
//                    UIColor(red: 0, green: 0, blue: 0, alpha: 0.7).cgColor,
//                    UIColor(red: 0, green: 0, blue: 0, alpha: 0.01).cgColor]
//
//                gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0);
//                gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.0);
//                imageView.layer.mask = gradientLayer
//
//                self.view.addSubview(imageView)
//            }
//        }
//    }

