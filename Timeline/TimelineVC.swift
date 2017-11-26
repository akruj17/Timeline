//
//  TimelineVC.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 7/10/17.
//  Copyright © 2017 Edumacation!. All rights reserved.
//

import UIKit
import RealmSwift
import ImagePalette

var collectionHeight: CGFloat!

class TimelineVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, BackgroundModifierDelegate, ImageLayoutDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var backgroundModifierContainer: UIView!
    @IBOutlet weak var eventDetailedContainer: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var loadingBlurContainer: UIView!
    
    var timeline: Timeline!
    var events: [Event]!
    var eventDetailedVC: EventDetailedVC!
    var backgroundModifierVC: BackgroundModifierVC!
    var imageStatusesArray: [imageStatusTuple]!
    var colorCache = [UIColor]()
    var isInitialized = false
    var imgDirectory: NSString!
    var layout: TimelineLayout!
    var pListPath: NSString!
    var imageInfo: NSMutableDictionary!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.startAnimating()
        //initialize variables
        //let tuple = RealmOperator.retrieveEventsFromDatabase(timeline: timeline.name)
        //events = tuple.0
        events = [Event]()
        imageStatusesArray = [imageStatusTuple]()
        if let layout = collectionView?.collectionViewLayout as? TimelineLayout {
            self.layout = layout
            self.layout.delegate = self
        }
        collectionView.delegate = self
        collectionView.dataSource = self
        
        if let layout = collectionView?.collectionViewLayout as? TimelineLayout {
            self.layout = layout
            self.layout.delegate = self
        }
        //set the title to store the title of the timeline
        navBar.titleTextAttributes = [ NSAttributedStringKey.font: UIFont(name: "AvenirNext-Regular", size: 30)!, NSAttributedStringKey.foregroundColor: UIColor.darkGray]
    
        //create references for the filesystem and current timeline directory
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        imgDirectory = documents.appendingPathComponent("\(TIMELINE_IMAGE_DIRECTORY)/\(timeline.name)") as NSString
        
        //retrieve imageInfo plist from directory
        pListPath = imgDirectory.appendingPathComponent("\(IMAGE_INFO_PLIST)") as NSString
        imageInfo = NSMutableDictionary(contentsOfFile: pListPath as String)
        
        //retrieve all image paths for the specific timeline from the filesystem
//        for imagePath in (imageInfo?.value(forKey: IMAGE_ORDERING_ARRAY) as! [String]) {
//            autoreleasepool {
//                let img = UIImage(contentsOfFile: imgDirectory.appendingPathComponent("\(imagePath)"))
//                let imgData = UIImageJPEGRepresentation(img!, 0.3)!
//                imageStatusesArray.append((imagePath, imgData, false, img!.size))
//            }
//        }
//        updateColorCache()
//        collectionView.reloadData()
        
        //set up properties of the container views
        backgroundModifierContainer.layer.borderColor = UIColor.lightGray.cgColor
        backgroundModifierContainer.layer.borderWidth = 2
        backgroundModifierContainer.layer.cornerRadius = 4
        
        //this initializes the background in the background modifier
        backgroundModifierVC.imageStatusesArray = self.imageStatusesArray
        
        //initialize this global variable
        collectionHeight = collectionView.frame.height
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        navBar.topItem?.title = timeline.name.uppercased()
        //if the user entered the timeline for the first time, the else statement runs. If they entered from a VC being
        //dismissed, the if portion runs.
        if isInitialized {
            events.sort(by: {$0.year.value! < $1.year.value!})
            if events.count < collectionView.numberOfItems(inSection: 0)
            {
                let invalidationContext = TimelineInvalidationContext()
                invalidationContext.numberOfEventsToDrop = collectionView.numberOfItems(inSection: 0) - events.count
                invalidationContext.invalidateEvents = true
                layout.invalidateLayout(with: invalidationContext)
            }
            collectionView.reloadData()
            collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
        } else {
            isInitialized = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let tuple = RealmOperator.retrieveEventsFromDatabase(timeline: timeline.name)
        events = tuple.0
       // retrieve all image paths for the specific timeline from the filesystem
                for imagePath in (imageInfo?.value(forKey: IMAGE_ORDERING_ARRAY) as! [String]) {
                    autoreleasepool {
                        let img = UIImage(contentsOfFile: imgDirectory.appendingPathComponent("\(imagePath)"))
                        let imgData = UIImageJPEGRepresentation(img!, 0.3)!
                        imageStatusesArray.append((imagePath, imgData, false, img!.size))
                    }
                }
                updateColorCache()
                collectionView.reloadData()
        collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
        let when = DispatchTime.now() + 0.5 // change 2 to desired number of seconds
        DispatchQueue.main.asyncAfter(deadline: when) { [unowned self] in
            self.activityIndicator.stopAnimating()
            self.loadingBlurContainer.isHidden = true
        }
    }
    
/////IB ACTION METHODS
    
    @IBAction func backBtnPressed(_ sender: Any) {
        let currentCounter = imageInfo.value(forKey: IMAGE_COUNTER) as! Int
        FileSystemOperator.updateImagesInFileSystem(imageStatusData: imageStatusesArray, imagePathsToDelete: backgroundModifierVC.deletedPaths, imageDirectory: imgDirectory, startCounter: currentCounter, imageInfo: imageInfo, pListPath: pListPath)
       
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func modifyBackgroundPressed(_ sender: Any) {
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.view.frame
        self.view.insertSubview(blurEffectView, at: 2)
        backgroundModifierContainer.backgroundColor = UIColor.clear
        backgroundModifierContainer.isHidden = false
    }
    
/////COLLECTIONVIEW METHODS
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return events.count
        }
        else if section == 1 {
            return imageStatusesArray.count
        }
        else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "eventCell", for: indexPath) as? TimelineEventBoxCell {
                let isTopRow = indexPath.item % 2 == 0 ? true: false
                // firstYear will store whether the event is the first of its year, nil otherwise
                let firstYear = (indexPath.item == 0 || (events[indexPath.item].year.value! > events[indexPath.item - 1].year.value!)) ? events[indexPath.item].year.value! : nil
                
                var color: UIColor
                if indexPath.item < colorCache.count {
                    color = colorCache[indexPath.item]
                } else {
                    color = UIColor.gray
                }
                cell.configure(isTopRow: isTopRow, title: events[indexPath.item].overview, color: color, year: firstYear)
                cell.layer.zPosition = 100
                return cell
            }
        }
        else if indexPath.section == 1 {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as? TimelineImageCell {
                cell.imgView.image = FileSystemOperator.resizeImage(image: UIImage(data: imageStatusesArray[indexPath.item].data)!, height: collectionHeight)
                cell.layer.zPosition = 50
                return cell
            }
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if let cell = collectionView.cellForItem(at: indexPath) {
                eventDetailedVC.updateEventFields(event: events[indexPath.item])
                eventDetailedContainer.isHidden = false
            }
        }
    }
    
    
//////BACKGROUND MODIFIER DELEGATE METHODS
    
    func timelineName() -> String {
        return timeline.name
    }
    
    func updateBackgroundImages(imageStatuses: [imageStatusTuple]) {
        self.imageStatusesArray = imageStatuses
        // if the layout has already been created, it must be updated
        if layout != nil {
            let invalidationContext = TimelineInvalidationContext()
            invalidationContext.invalidateImages = true
            layout.invalidateLayout(with: invalidationContext)
            updateColorCache()
        }
        
        //removeContainerView()
        
    }
    
    func removeContainerView() {
        self.view.subviews[2].removeFromSuperview()
        backgroundModifierContainer.isHidden = true
    }
    
/////IMAGE LAYOUT DELEGATE METHODS
    
    func getSizeAtIndexPath(indexPath: IndexPath) -> CGSize {
        return imageStatusesArray[indexPath.item].largeSize
    }
    
/////HELPER METHODS
    
    func updateColorCache() {
        colorCache.removeAll()
        let eventLength = collectionView.frame.height * 0.9
        
        for image in imageStatusesArray {
            let imageLength: CGFloat = image.largeSize.width * 0.8
            let im = UIImage(data: image.data)
            var colorSwatch = UIColor.darkGray
            Palette.generateWith(configuration: PaletteConfiguration(image: UIImage(data: image.data)!), completion: {[unowned self] in
                var img = image
                colorSwatch = $0.vibrantColor(defaultColor: UIColor.darkGray)
                //DispatchQueue.global(qos: .background).sync {[unowned self] in
                    var currentPosition: CGFloat = 0
                    while currentPosition < imageLength {
                        self.colorCache.append(colorSwatch)
                        currentPosition += eventLength
                    }
                    DispatchQueue.main.async {
                        //self.collectionView.reloadItems(at: self.collectionView.indexPathsForVisibleItems)
                        self.collectionView.reloadData()
                        if !self.backgroundModifierContainer.isHidden {
                            self.removeContainerView()
                        }
                    }
            })
        }
    }
//
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "initializeBackgroundModifier" {
            if let backgroundModifierVC = segue.destination as? BackgroundModifierVC {
                self.backgroundModifierVC = backgroundModifierVC
                backgroundModifierVC.delegate = self
            }
        } else if segue.identifier == "timelineToEditor" {
            if let editorVC = segue.destination as? TimelineEditorVC {
                editorVC.eventInfoArray = events
                editorVC.timelineTitle = timeline
                editorVC.isNewTimeline = false
            }
        } else if segue.identifier == "initializeEventDetailed" {
            if let eventVC = segue.destination as? EventDetailedVC {
                eventDetailedVC = eventVC
            }
        }
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
}

protocol TimelineDataDelegate {
    func updateTitle(newTitle: Timeline);
}
