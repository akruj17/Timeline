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

class TimelineVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, BackgroundModifierDelegate, ImageLayoutDelegate, EventLayoutDelegate, EditorDataSaveDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var navBar: customNavBar!
    @IBOutlet weak var backgroundModifierContainer: UIView!
    @IBOutlet weak var eventDetailedView: EventDetailedView!
    @IBOutlet weak var loadingScreen: LoadingScreen!
    
    // DEALING WITH THE DATA
    var timeline: Timeline!
    var events: [Event]! // solely the events used for loading table view and indexing
    var eventsLayout: [TimeObject]! // some events may be duplicated here for laying out periods
    var realmOperator: RealmOperator!
    var backgroundModifierVC: BackgroundModifierVC!
    var imageStatusesArray: [imageStatusTuple]!
    var colorCache = [UIColor]()
    var isInitialized = false
    var imgDirectory: NSString!
    var layout: TimelineLayout!
    var pListPath: NSString!
    var imageInfo: NSMutableDictionary!
    weak var titleDelegate: CollectionReloadDelegate!
    var doneEditing: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //assign delegates
        collectionView.dataSource = self
        collectionView.delegate = self
        if let layout = collectionView?.collectionViewLayout as? TimelineLayout {
            self.layout = layout
            self.layout.delegate = self
            self.layout.eventDelegate = self
        }
        eventDetailedView.delegate = self
        assert(titleDelegate != nil)
        loadingScreen.isHidden = false
        let dispatch_group = DispatchGroup()
        // should only be in landscape
        if UIDevice.current.orientation != .landscapeLeft && UIDevice.current.orientation != .landscapeRight {
            AppUtility.lockOrientation(.landscape, andRotateTo: .landscapeRight)
        }
        // these variables should be populated during segue
        assert(events != nil)
        assert(timeline != nil)
        realmOperator = RealmOperator(_timeline: timeline)
        // make two worker threads that will layout the events and images. SYNCHRONIZATION IS FUN!!!
        //EVENTS
        eventsLayout = [TimeObject]()
        dispatch_group.enter()
        DispatchQueue.main.async {
            self.events.sort(by: {$0.startYear.value! < $1.startYear.value!})
            // sort the events for layout
            for event in self.events {
                if (event.isTimePeriod) {
                    self.eventsLayout.append(Period(event: event, beginning: true))
                    self.eventsLayout.append(Period(event: event, beginning: false))
                } else {
                    self.eventsLayout.append(event)
                }
            }
            self.eventsLayout.sort(by: {$0.year < $1.year})
            // periods and events should now be sorted
            dispatch_group.leave()
        }
        DispatchQueue.global(qos: .background).async {
            let completionHandler = { (year: String, overview: String, view: UIView) -> Void in
                self.view.endEditing(true)
                if year.isEmpty || overview.isEmpty {
                    let incompleteAlert = UIAlertController(title: "Incomplete", message: nil, preferredStyle: .alert)
                    incompleteAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    incompleteAlert.title = "The event must have a year and overview."
                    self.present(incompleteAlert, animated: true, completion: nil)
                } else {
                    self.collectionView.performBatchUpdates({
                        self.collectionView.reloadSections([1])
                    }, completion: { (b) in
                        view.isHidden = true
                    })
                }
            }
            self.eventDetailedView.completion = completionHandler
            
        }
        //IMAGES
        //AFTER BOTH ASYNC FINISH
        dispatch_group.notify(queue: DispatchQueue.main, work: DispatchWorkItem {
            self.collectionView.reloadData()
            self.loadingScreen.isHidden = true
        })
        //if a directory for the images has not yet been created, create it here. Otherwise, retrieve the images here
        let isNew = FileSystemOperator.createImageDirectory(name: timeline.name)
            
            // get the images
    }
      
//        imageStatusesArray = [imageStatusTuple]()
//        if let layout = collectionView?.collectionViewLayout as? TimelineLayout {
//            self.layout = layout
//            self.layout.delegate = self
//            self.layout.eventDelegate = self
//        }
//        collectionView.delegate = self
//        collectionView.dataSource = self
//
//        if let layout = collectionView?.collectionViewLayout as? TimelineLayout {
//            self.layout = layout
//            self.layout.delegate = self
//        }
//        //set the title to store the title of the timeline
//        navBar.titleTextAttributes = [ NSAttributedString.Key.font: UIFont(name: "AvenirNext-Regular", size: 30)!, NSAttributedString.Key.foregroundColor: UIColor.darkGray]
//
//        //create references for the filesystem and current timeline directory
//        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
//        imgDirectory = documents.appendingPathComponent("\(TIMELINE_IMAGE_DIRECTORY)/\(timeline.name)") as NSString
//
//        //retrieve imageInfo plist from directory
//        pListPath = imgDirectory.appendingPathComponent("\(IMAGE_INFO_PLIST)") as NSString
//        imageInfo = NSMutableDictionary(contentsOfFile: pListPath as String)
//
//        //set up properties of the container views
//        backgroundModifierContainer.layer.borderColor = UIColor.lightGray.cgColor
//        backgroundModifierContainer.layer.borderWidth = 2
//        backgroundModifierContainer.layer.cornerRadius = 4
//        eventDetailedContainer.layer.borderColor = UIColor.lightGray.cgColor
//        eventDetailedContainer.layer.borderWidth = 3
//        eventDetailedContainer.layer.cornerRadius = 5

//        print("\(imgDirectory)")

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        navBar.topItem?.title = timeline.name.uppercased()
        //if the user entered the timeline for the first time, the else statement runs. If they entered from a VC being
        //dismissed, the if portion runs.
//        if isInitialized {
//            events.sort(by: {$0.startYear.value! < $1.startYear.value!})
//            if eventsForLayout.count < collectionView.numberOfItems(inSection: 1)
//            {
//                let invalidationContext = TimelineInvalidationContext()
//                invalidationContext.numberOfEventsToDrop = collectionView.numberOfItems(inSection: 1) - events.count
//                invalidationContext.invalidateEvents = true
//                layout.invalidateLayout(with: invalidationContext)
//            }
//            collectionView.reloadData()
//            collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
//        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
//        if !isInitialized {
//            DispatchQueue.global(qos: .background).sync {
//                if events.isEmpty {
//                    let tuple = RealmOperator.retrieveEventsFromDatabase(timeline: timeline.name)
//                    events = tuple.0
//                    // retrieve all image paths for the specific timeline from the filesystem
//                    for imagePath in (imageInfo?.value(forKey: IMAGE_ORDERING_ARRAY) as! [String]) {
//                        autoreleasepool {
//                            let img = UIImage(contentsOfFile: imgDirectory.appendingPathComponent("\(imagePath)"))
//                            let imgData = img!.jpegData(compressionQuality: 0.3)!
//                            imageStatusesArray.append((imagePath, imgData, false, img!.size))
//                        }
//                    }
//                    updateColorCache()
//                }

//                DispatchQueue.main.async {
//                    self.collectionView.reloadData()
//                    self.collectionView.reloadItems(at: self.collectionView.indexPathsForVisibleItems)
//                }
//
//                //this initializes the background in the background modifier
//                backgroundModifierVC.imageStatusesArray = self.imageStatusesArray
//            }
//
//            let when = DispatchTime.now() + 0.1 // change 2 to desired number of seconds
//            DispatchQueue.main.asyncAfter(deadline: when) { [unowned self] in
//
//                self.activityIndicator.stopAnimating()
//                self.loadingBlurContainer.isHidden = true
//            }
//            isInitialized = true
//        }
    }
    
/////IB ACTION METHODS
    
    @IBAction func backBtnPressed(_ sender: Any) {
            self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBOutlet weak var saveBtn: UIBarButtonItem!
    @IBAction func savePressed(_ sender: Any) {
        //set up the loading animation
//        let indicator = UIActivityIndicatorView()
//        indicator.style = .whiteLarge
//        indicator.color = UIColor.blue
//        indicator.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
//        let loadingItem = UIBarButtonItem(customView: indicator)
//        let customNavItem = UINavigationItem(title: "Saving...")
//        customNavItem.setHidesBackButton(true, animated: false)
//        customNavItem.rightBarButtonItem = loadingItem
//        self.navBar.pushItem(customNavItem, animated: false)
//        indicator.startAnimating()
//        self.navBar.setNeedsLayout()
//        self.navBar.setNeedsDisplay()
//        // now save images and events on a background thread
//        let currentCounter = imageInfo.value(forKey: IMAGE_COUNTER) as! Int
//        FileSystemOperator.updateImagesInFileSystem(imageStatusData: imageStatusesArray, imagePathsToDelete: backgroundModifierVC.deletedPaths, imageDirectory: imgDirectory, startCounter: currentCounter, imageInfo:
//            imageInfo, pListPath: pListPath, timelineTitle: timeline.name)
//        // after saving is complete, change the navbar again... but wait a while to create a semblance :)
//        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) { [unowned self] in
//            indicator.stopAnimating()
//            self.navBar.popItem(animated: false)
//            self.navBar.setNeedsLayout()
//            self.navBar.setNeedsDisplay()
//            self.saveBtn.isEnabled = true
//        }
        
    }
    
    
    @IBAction func modifyBackgroundPressed(_ sender: Any) {
        backgroundModifierContainer.backgroundColor = UIColor.clear
        backgroundModifierVC.collectionView.reloadData()
        backgroundModifierContainer.isHidden = false
    }
    
    @IBAction func trashTimelinePressed(_ sender: Any) {
        let incompleteAlert = UIAlertController(title: "Warning", message: nil, preferredStyle: .alert)
        incompleteAlert.addAction(UIAlertAction(title: "OK", style: .destructive, handler: {[unowned self] action in
            //the user has confirmed they would like to delete this timeline
            self.realmOperator.deleteTimeline()
            self.titleDelegate.updateCollection(updateType: .DELETE, completion: { unused in
                self.navigationController?.popToRootViewController(animated: true)
            })
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
            return 0
        }
        else if section == 1 {
            return eventsLayout.count
        }
        else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as? TimelineImageCell {
                cell.imgView.image = FileSystemOperator.resizeImage(image: UIImage(data:
                    imageStatusesArray[indexPath.item].data)!, height: collectionHeight)
                cell.layer.zPosition = 50
                return cell
            }
        }
        else if indexPath.section == 1 {
            let isTopRow = indexPath.item % 2 == 0 ? true: false
            // firstYear will store whether the event is the first of its year, nil otherwise
            let firstYear = (indexPath.item == 0 || (eventsLayout[indexPath.item].year > eventsLayout[indexPath.item - 1].year)) ? eventsLayout[indexPath.item].year : nil
            var color: UIColor
            if indexPath.item < colorCache.count {
                color = colorCache[indexPath.item]
            } else {
                color = UIColor.gray
            }
            if eventsLayout[indexPath.item] is Period {
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "periodCell", for: indexPath) as? PeriodCell {
                    cell.configure(isTopRow: isTopRow, overview: eventsLayout[indexPath.item].event.overview, color: color, year: firstYear, isBeginning: (eventsLayout[indexPath.item] as! Period).isBeginning)
                    cell.layer.zPosition = 100
                    return cell
                }
            } else {
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "eventCell", for: indexPath) as? TimelineEventBoxCell {
                    cell.configure(isTopRow: isTopRow, overview: eventsLayout[indexPath.item].event.overview, color: color, year: firstYear)
                    cell.layer.zPosition = 100
                    return cell
                }
            }
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            if collectionView.cellForItem(at: indexPath) != nil {
                //populate the eventDetailedView
                var second: Int? = nil
                var secondLast: Int? = nil
                if indexPath.item == 0 && eventsLayout.count > 1 {
                    second = eventsLayout[1].year
                }
                if indexPath.item == (eventsLayout.count - 1) && eventsLayout.count > 1 {
                    secondLast = eventsLayout[eventsLayout.count - 2].year
                }
                eventDetailedView.configure(index: indexPath.item, timeObject: eventsLayout[indexPath.item], first: eventsLayout.first!.year, last: eventsLayout.last!.year, second: second, secondLast: secondLast)
                eventDetailedView.isHidden = false
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
            DispatchQueue.global(qos: .utility).async { [unowned self] in
                DispatchQueue.main.async { [unowned self] in
                    self.removeContainerView()
//                    self.activityIndicator.startAnimating()
//                    self.loadingBlurContainer.isHidden = false
                }
                let invalidationContext = TimelineInvalidationContext()
                invalidationContext.invalidateImages = true
                self.layout.invalidateLayout(with: invalidationContext)
                self.updateColorCache()
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) { [unowned self] in
                    self.collectionView.reloadData()
                    self.collectionView.reloadItems(at: self.collectionView.indexPathsForVisibleItems)
//                    self.activityIndicator.stopAnimating()
//                    self.loadingBlurContainer.isHidden = true
                }
            }

        }
    }
    
    func removeContainerView() {
        backgroundModifierContainer.isHidden = true
    }
    
    //
    
    func updateEvent(event: Event?, index: Int) {
        if let newEvent = event {
            events[index] = newEvent
        } else { // the event was deleted
            events.remove(at: index)
        }
        collectionView.reloadData()
    }
    
/////IMAGE LAYOUT DELEGATE METHODS
    
    func getSizeAtIndexPath(indexPath: IndexPath) -> CGSize {
        return imageStatusesArray[indexPath.item].largeSize
    }
    
/////EVENT LAYOUT DELEGATE METHODS

    func isEventAtIndexFirstOfYear(index: Int) -> Bool {
        return (index == 0 || (eventsLayout[index].year > eventsLayout[index - 1].year))
    }
    
    func isTimeObjectPeriod(index: Int) -> Bool {
        return eventsLayout[index] is Period
    }
    
/////HELPER METHODS
    
    func updateColorCache() {
        colorCache.removeAll()
        let eventLength = collectionView.frame.height * 0.9
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
        let currCount = colorCache.count
        for _ in currCount ... eventsLayout.count {
            colorCache.append(UIColor.gray)
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
            }
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
//EDITOR DATA SAVE METHODS
    func saveOverview(overview: String, index: Int) {
        realmOperator.persistEventField(event: eventsLayout[index].event, field: overview, type: EventInfo.OVERVIEW, sync: doneEditing)
    }
    
    func saveDetailed(detailed: String, index: Int) {
        realmOperator.persistEventField(event: eventsLayout[index].event, field: detailed, type: EventInfo.DETAILED, sync: doneEditing)
    }
    
    func saveYear(year: Int?, index: Int) {
        if let period = eventsLayout[index] as? Period {
            if !period.isBeginning {
                realmOperator.persistEventField(event: eventsLayout[index].event, field: year, type: EventInfo.END_YEAR, sync: doneEditing)
                return
            }
        }
        realmOperator.persistEventField(event: eventsLayout[index].event, field: year, type: EventInfo.START_YEAR, sync: doneEditing)
    }

    func saveTitle(title: String) {
        //method not implemented
    }
    
    func saveEndYear(year: Int?, index: Int) {
        //method not implemented
    }
    
    func saveTimePeriod(isTimePeriod: Bool, index: Int) {
        //method not implemented
    }

}

protocol TimelineDataDelegate {
    func updateTitle(newTitle: Timeline);
}



