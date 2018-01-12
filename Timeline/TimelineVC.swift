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

class TimelineVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, BackgroundModifierDelegate, ImageLayoutDelegate, EventDetailedDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var navBar: customNavBar!
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
    weak var titleDelegate: TitleScreenLayoutDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if UIDevice.current.orientation != .landscapeLeft && UIDevice.current.orientation != .landscapeRight {
            AppUtility.lockOrientation(.landscape, andRotateTo: .landscapeRight)
        }
        activityIndicator.startAnimating()
        //initialize variables
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
        
        //set up properties of the container views
        backgroundModifierContainer.layer.borderColor = UIColor.lightGray.cgColor
        backgroundModifierContainer.layer.borderWidth = 2
        backgroundModifierContainer.layer.cornerRadius = 4
        eventDetailedContainer.layer.borderColor = UIColor.lightGray.cgColor
        eventDetailedContainer.layer.borderWidth = 3
        eventDetailedContainer.layer.cornerRadius = 5
        
        //initialize this global variable. This will be used in background processes
        collectionHeight = collectionView.frame.height
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        navBar.topItem?.title = timeline.name.uppercased()
        //if the user entered the timeline for the first time, the else statement runs. If they entered from a VC being
        //dismissed, the if portion runs.
        if isInitialized {
            events.sort(by: {$0.year.value! < $1.year.value!})
            if events.count < collectionView.numberOfItems(inSection: 1)
            {
                let invalidationContext = TimelineInvalidationContext()
                invalidationContext.numberOfEventsToDrop = collectionView.numberOfItems(inSection: 1) - events.count
                invalidationContext.invalidateEvents = true
                layout.invalidateLayout(with: invalidationContext)
            }
            collectionView.reloadData()
            collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
        } 
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if !isInitialized {
            DispatchQueue.global(qos: .background).sync {
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
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                    self.collectionView.reloadItems(at: self.collectionView.indexPathsForVisibleItems)
                }
                
                //this initializes the background in the background modifier
                backgroundModifierVC.imageStatusesArray = self.imageStatusesArray
            }
            
            let when = DispatchTime.now() + 0.5 // change 2 to desired number of seconds
            DispatchQueue.main.asyncAfter(deadline: when) { [unowned self] in

                self.activityIndicator.stopAnimating()
                self.loadingBlurContainer.isHidden = true
            }
            isInitialized = true
        }
    }
    
/////IB ACTION METHODS
    
    @IBAction func backBtnPressed(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBOutlet weak var saveBtn: UIBarButtonItem!
    @IBAction func savePressed(_ sender: Any) {
        //set up the loading animation
        let indicator = UIActivityIndicatorView()
        indicator.activityIndicatorViewStyle = .whiteLarge
        indicator.color = UIColor.blue
        indicator.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        let loadingItem = UIBarButtonItem(customView: indicator)
        let customNavItem = UINavigationItem(title: "Saving...")
        customNavItem.setHidesBackButton(true, animated: false)
        customNavItem.rightBarButtonItem = loadingItem
        self.navBar.pushItem(customNavItem, animated: false)
        indicator.startAnimating()
        self.navBar.setNeedsLayout()
        self.navBar.setNeedsDisplay()
        // now save images and events on a background thread
        let currentCounter = imageInfo.value(forKey: IMAGE_COUNTER) as! Int
        FileSystemOperator.updateImagesInFileSystem(imageStatusData: imageStatusesArray, imagePathsToDelete: backgroundModifierVC.deletedPaths, imageDirectory: imgDirectory, startCounter: currentCounter, imageInfo:
            imageInfo, pListPath: pListPath, timelineTitle: timeline.name)
        // after saving is complete, change the navbar again... but wait a while to create a semblance :)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) { [unowned self] in
            indicator.stopAnimating()
            self.navBar.popItem(animated: false)
            self.navBar.setNeedsLayout()
            self.navBar.setNeedsDisplay()
            self.saveBtn.isEnabled = true
        }
        
    }
    
    
    @IBAction func modifyBackgroundPressed(_ sender: Any) {
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.view.frame
        self.view.insertSubview(blurEffectView, at: 2)
        backgroundModifierContainer.backgroundColor = UIColor.clear
        backgroundModifierVC.collectionView.reloadData()
        backgroundModifierContainer.isHidden = false
    }
    
    @IBAction func trashTimelinePressed(_ sender: Any) {
        let incompleteAlert = UIAlertController(title: "Warning", message: nil, preferredStyle: .alert)
        incompleteAlert.addAction(UIAlertAction(title: "OK", style: .destructive, handler: {[unowned self] action in
            DispatchQueue.global(qos: .background).sync {
                RealmOperator.deleteFromDatabase(events: self.events, timeline: self.timeline)
                DispatchQueue.main.async {
                    self.activityIndicator.startAnimating()
                }
            }
                self.titleDelegate?.updateNumTitles(numTitles: -1)
                self.navigationController?.popToRootViewController(animated: true)
        }))
        incompleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        incompleteAlert.title = "Are you sure you want to delete this timeline? This action cannot be undone later."
        self.present(incompleteAlert, animated: true, completion: nil)
    }
    
    
/////COLLECTIONVIEW METHODS
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return imageStatusesArray.count
        }
        else if section == 1 {
            return events.count
        }
        else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as? TimelineImageCell {
                cell.imgView.image = FileSystemOperator.resizeImage(image: UIImage(data: imageStatusesArray[indexPath.item].data)!, height: collectionHeight)
                cell.layer.zPosition = 50
                return cell
            }
        }
        else if indexPath.section == 1 {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "eventCell", for: indexPath) as? TimelineEventBoxCell {
                let isTopRow = indexPath.item % 2 == 0 ? true: false
                // firstYear will store whether the event is the first of its year, nil otherwise
                let firstYear = (indexPath.item == 0 || (events[indexPath.item].year.value! > events[indexPath.item - 1].year.value!)) ? events[indexPath.item].year.value! : nil
                print("\(indexPath.item)  \(firstYear)")
                
                var color: UIColor
                if indexPath.item < colorCache.count {
                    color = colorCache[indexPath.item]
                } else {
                    color = UIColor.gray
                }
                cell.configure(isTopRow: isTopRow, title: events[indexPath.item].overview, color: color, year: firstYear, isTitleScreenEventBox: false)
                cell.layer.zPosition = 100
                return cell
            }
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            if let cell = collectionView.cellForItem(at: indexPath) {
                let blurEffect = UIBlurEffect(style: .light)
                let blurEffectView = UIVisualEffectView(effect: blurEffect)
                blurEffectView.frame = self.view.frame
                self.view.insertSubview(blurEffectView, at: 2)
                eventDetailedVC.updateAppearance(event: events[indexPath.item], color: colorCache[indexPath.item])
                eventDetailedContainer.isHidden = false
            }
        }
    }
    
    
//////BACKGROUND MODIFIER DELEGATE METHODS
    
    func timelineName() -> String {
        return timeline.name
    }
    
    func updateBackgroundImages(imageStatuses: [imageStatusTuple]) {
        print("\(imageStatuses.count)")
        self.imageStatusesArray = imageStatuses
        // if the layout has already been created, it must be updated
        if layout != nil {
            DispatchQueue.global(qos: .utility).async { [unowned self] in
                DispatchQueue.main.async { [unowned self] in
                    self.removeContainerView()
                    self.activityIndicator.startAnimating()
                    self.loadingBlurContainer.isHidden = false
                }
                let invalidationContext = TimelineInvalidationContext()
                invalidationContext.invalidateImages = true
                self.layout.invalidateLayout(with: invalidationContext)
                self.updateColorCache()
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) { [unowned self] in
                    self.collectionView.reloadData()
                    self.collectionView.reloadItems(at: self.collectionView.indexPathsForVisibleItems)
                    self.activityIndicator.stopAnimating()
                    self.loadingBlurContainer.isHidden = true
                }
            }

        }
    }
    
    func removeContainerView() {
        self.view.subviews[2].removeFromSuperview()
        backgroundModifierContainer.isHidden = true
        eventDetailedContainer.isHidden = true
    }
    
/////IMAGE LAYOUT DELEGATE METHODS
    
    func getSizeAtIndexPath(indexPath: IndexPath) -> CGSize {
        return imageStatusesArray[indexPath.item].largeSize
    }
    
/////HELPER METHODS
    
    func updateColorCache() {
        colorCache.removeAll()
        let eventLength = collectionHeight * 0.9
        for image in imageStatusesArray {
            let imageLength: CGFloat = image.largeSize.width * 0.8
            var colorSwatch = UIColor.darkGray
            Palette.generateWith(configuration: PaletteConfiguration(image: UIImage(data: image.data)!), completion:{[unowned self] in
                colorSwatch = $0.vibrantColor(defaultColor: UIColor.darkGray)
                var currentPosition: CGFloat = 0
                while currentPosition < imageLength {
                    self.colorCache.append(colorSwatch)
                    currentPosition += eventLength
                }
            })
        }
        if colorCache.count < events.count {
            for i in colorCache.count ..< events.count {
                colorCache.append(UIColor.gray)
            }
        }
    }
    
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
                eventDetailedVC.delegate = self
            }
        }
    }
}

protocol TimelineDataDelegate {
    func updateTitle(newTitle: Timeline);
}
