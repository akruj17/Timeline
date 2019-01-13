//
//  TimelineVC.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 7/10/17.
//  Copyright © 2017 Edumacation!. All rights reserved.
//

import UIKit
import RealmSwift

class TimelineVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, BackgroundModifierDelegate,  TimelineCollectionDelegate, EditorDataSaveDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var navBar: customNavBar!
    @IBOutlet weak var backgroundModifierContainer: UIView!
    @IBOutlet weak var eventDetailedView: EventDetailedView!
    @IBOutlet weak var loadingScreen: LoadingScreen!
    
    // DEALING WITH THE DATA
    var timeline: Timeline!
    var events: Results<Event>! // solely the events used for loading table view and indexing
    var eventsLayout: [TimeObject]! // some events may be duplicated here for laying out periods
    var realmOperator: RealmOperator!
    var fileSystemOperator: FileSystemOperator!
    var backgroundModifierVC: BackgroundModifierVC!
    var colorCache = [UIColor]()
    var needsLayout = false
    var layout: TimelineLayout!
    weak var titleDelegate: CollectionReloadDelegate!
    var doneEditing: Bool = false
    var activeTextView: UIView? = nil //any because it could be a text field or text view
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // should only be in landscape
        if UIApplication.shared.statusBarOrientation != .landscapeLeft && UIApplication.shared.statusBarOrientation != .landscapeRight {
            AppUtility.lockOrientation(.landscape, andRotateTo: .landscapeLeft)
            UIViewController.attemptRotationToDeviceOrientation()
        }
        //assign delegates
        collectionView.dataSource = self
        collectionView.delegate = self
        if let layout = collectionView?.collectionViewLayout as? TimelineLayout {
            self.layout = layout
            self.layout.delegate = self
            self.layout.sizeClass = self.view.traitCollection.verticalSizeClass
        }
        eventDetailedView.delegate = self
        assert(titleDelegate != nil)
        loadingScreen.isHidden = false
        let dispatch_group = DispatchGroup()
//        AppUtility.lockOrientation(.portrait, andRotateTo: .portrait)
        // these variables should be populated during segue
        assert(timeline != nil)
        realmOperator = RealmOperator(_timeline: timeline)
        //setup background modifier properties that it was unable to at instantiation
        fileSystemOperator = FileSystemOperator(timelineName: timeline.name)
        fileSystemOperator.backgroundCollectionHeight = backgroundModifierVC.editorHeight
        fileSystemOperator.timelineCollectionHeight = collectionView.frame.height
        backgroundModifierVC.fileSystemOperator = fileSystemOperator
        backgroundModifierVC.timelineHeight = collectionView.frame.height
        backgroundModifierVC.selectedImages = [Bool](repeating: false, count: fileSystemOperator.imageInfoArray.count)
        // make two worker threads that will layout the events and images. SYNCHRONIZATION IS FUN!!!
        //EVENTS
        eventsLayout = [TimeObject]()
        dispatch_group.enter()
        DispatchQueue.main.async {
            RealmOperator.retrieveEvents(timeline: self.timeline, sorted: true) { (events) in
                self.events = events
                self.setUpEventLayout()
                dispatch_group.leave()
            }
        }
        //IMAGES
        dispatch_group.enter()
        DispatchQueue.main.async {
            self.updateColorCache()
            dispatch_group.leave()
        }
        let completionHandler = { (year: String, overview: String, view: UIView) -> Void in
                self.doneEditing = true
                self.view.endEditing(true)
                self.doneEditing = false
                if year.isEmpty || overview.isEmpty {
                    let incompleteAlert = UIAlertController(title: "Incomplete", message: nil, preferredStyle: .alert)
                    incompleteAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    incompleteAlert.title = "The event must have a year and overview."
                    self.present(incompleteAlert, animated: true, completion: nil)
                } else {
                    self.eventsLayout.sort(by: {$0.year < $1.year})
                    self.collectionView.reloadSections([PERIOD_STICK_SECTION, EVENT_SECTION])
                    self.collectionView.performBatchUpdates({
                    }, completion: { (b) in
                        view.isHidden = true
                    })
                }
            }
            eventDetailedView.completion = completionHandler
        
        //AFTER BOTH ASYNC FINISH
        dispatch_group.notify(queue: DispatchQueue.main, work: DispatchWorkItem {
            self.collectionView.reloadData()
            self.loadingScreen.isHidden = true
        })
        //add support for pushing view up when keyboard appears
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        // should only be in landscape
        if UIApplication.shared.statusBarOrientation != .landscapeLeft && UIApplication.shared.statusBarOrientation != .landscapeRight {
            AppUtility.lockOrientation(.landscape, andRotateTo: .landscapeLeft)
            UIViewController.attemptRotationToDeviceOrientation()
        }
        if needsLayout {
            setUpEventLayout()
            collectionView.reloadData()
        }
        navBar.topItem?.title = timeline.name.uppercased()
    }
    
    func setUpEventLayout() {
        eventsLayout = [TimeObject]()
        for event in self.events {
            if (event.isTimePeriod) {
                self.eventsLayout.append(Period(event: event, beginning: true))
                self.eventsLayout.append(Period(event: event, beginning: false))
            } else {
                self.eventsLayout.append(event)
            }
        }
        // sort the events for layout
        eventsLayout.sort(by: {$0.year < $1.year})
    }
    
/////IB ACTION METHODS
    
    @IBAction func backBtnPressed(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
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
            RealmOperator.deleteTimeline(title: self.timeline)
            self.titleDelegate.updateCollection(completion: { unused in
                self.navigationController?.popToRootViewController(animated: true)
            })
        }))
        incompleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        incompleteAlert.title = "Are you sure you want to delete this timeline? This action cannot be undone later."
        self.present(incompleteAlert, animated: true, completion: nil)
    }
    
    
/////COLLECTIONVIEW METHODS
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == IMAGE_SECTION {
            return fileSystemOperator.imageInfoArray.count
        }
        else if section == EVENT_SECTION || section == PERIOD_STICK_SECTION {
            return eventsLayout.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == IMAGE_SECTION {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as? TimelineImageCell {
                fileSystemOperator.imageInfoArray[indexPath.item].cell = cell
                fileSystemOperator.retrieveImage(index: indexPath.item, widthType: .ORIGINAL)
                cell.layer.zPosition = 50
                return cell
            }
        } else {
            //either event or period stick
            let isTopRow = indexPath.item % 2 == 0 || self.view.traitCollection.verticalSizeClass == .compact
            let color = (indexPath.item < colorCache.count) ? colorCache[indexPath.item] : UIColor.gray
            var eventType = EventType.REGULAR
            if let period = eventsLayout[indexPath.item] as? Period {
                eventType = period.isBeginning ? .BEGIN : .END
            }
            if indexPath.section == EVENT_SECTION {
                 if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "eventCell", for: indexPath) as? TimelineEventBoxCell {
                    // firstYear will store whether the event is the first of its year, nil otherwise
                    let firstYear = (indexPath.item == 0 || (eventsLayout[indexPath.item].year > eventsLayout[indexPath.item - 1].year)) ? eventsLayout[indexPath.item].year : nil
                    cell.configure(isTopRow: isTopRow, overview: eventsLayout[indexPath.item].event.overview, color: color, year: firstYear, eventType: eventType)
                    cell.layer.zPosition = 100
                    return cell
                }
            } else if indexPath.section == PERIOD_STICK_SECTION {
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "periodCell", for: indexPath) as? PeriodStickCell {
                    if eventType != .REGULAR {
                        cell.configure(isTopRow: !isTopRow || self.view.traitCollection.verticalSizeClass == .compact, color: color, isBeginning: eventType == .BEGIN)
                        cell.isHidden = false
                    } else {
                        cell.isHidden = true
                    }
                    return cell
                }
            }
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.item < fileSystemOperator.imageInfoArray.count {
            fileSystemOperator.imageInfoArray[indexPath.item].cell = nil
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == EVENT_SECTION {
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
                let color = (indexPath.item < colorCache.count) ? colorCache[indexPath.item] : UIColor.darkGray
                eventDetailedView.configure(index: indexPath.item, timeObject: eventsLayout[indexPath.item], color: color, first: eventsLayout.first!.year, last: eventsLayout.last!.year, second: second, secondLast: secondLast)
                eventDetailedView.isHidden = false
            }
        }
    }
    
    
//////BACKGROUND MODIFIER DELEGATE METHODS

    func backgroundModifierDonePressed(updateAt updateIndex: Int) {
        self.layout.invalidateImageLayout(startingAt: updateIndex)
        updateColorCache()
        collectionView.reloadData()
        collectionView.performBatchUpdates(nil) { _ in
            self.backgroundModifierContainer.isHidden = true
        }
    }
    

/////LAYOUT DELEGATE METHODS

    func getWidthAtIndexPath(index: Int) -> CGFloat {
        return fileSystemOperator.imageInfoArray[index].width
    }

/////HELPER METHODS
    
    func updateColorCache() {
        colorCache.removeAll()
        let eventLength = collectionView.frame.height * 0.8
        for image in fileSystemOperator.imageInfoArray {
            let imageLength = image.width
            let imageColor = image.color
            var currPos: CGFloat = 0
            while currPos < imageLength {
                colorCache.append(imageColor)
                currPos += eventLength
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
            needsLayout = true    //we want to do some setting up when navigating back
            if let editorVC = segue.destination as? TimelineEditorVC {
                editorVC.eventInfoArray = Array(events)
                editorVC.timelineTitle = timeline
                editorVC.mode = MODIFY
                editorVC.realmOperator = realmOperator
            }
        }
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
    
    func setActiveTextField(textField: UIView) {
        activeTextView = textField
    }
    
//HANDLING KEYBOARD
@objc func keyboardWillShow(notification: NSNotification) {
    if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
        if let textField = activeTextView {
            let pos = textField.convert(textField.frame.origin, to: view)
            if (pos.y + textField.frame.height) >= (self.view.frame.height - keyboardSize.height) {
                //then shift the VC up
                if self.view.frame.origin.y == 0 {
                    self.view.frame.origin.y -= (keyboardSize.height / 3.0)
                }
            }
        }
    }
}

@objc func keyboardWillHide(notification: NSNotification) {
    if self.view.frame.origin.y != 0 {
        self.view.frame.origin.y = 0
    }
}

}
