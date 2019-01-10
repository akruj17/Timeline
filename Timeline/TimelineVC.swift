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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //assign delegates
        collectionView.dataSource = self
        collectionView.delegate = self
        if let layout = collectionView?.collectionViewLayout as? TimelineLayout {
            self.layout = layout
            self.layout.delegate = self
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
                    self.collectionView.performBatchUpdates({
                        self.collectionView.reloadSections([PERIOD_STICK_SECTION, EVENT_SECTION])
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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
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
                fileSystemOperator.retrieveImage(named: fileSystemOperator.imageInfoArray[indexPath.item].name, width: ORIGINAL_WIDTH) { (image) in
                    cell.imgView.image = image
                }
                cell.layer.zPosition = 50
                return cell
            }
        } else if indexPath.section == EVENT_SECTION {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "eventCell", for: indexPath) as? TimelineEventBoxCell {
                let isTopRow = indexPath.item % 2 == 0
                // firstYear will store whether the event is the first of its year, nil otherwise
                let firstYear = (indexPath.item == 0 || (eventsLayout[indexPath.item].year > eventsLayout[indexPath.item - 1].year)) ? eventsLayout[indexPath.item].year : nil
                let color = (indexPath.item < colorCache.count) ? colorCache[indexPath.item] : UIColor.gray
                cell.configure(isTopRow: isTopRow, overview: eventsLayout[indexPath.item].event.overview, color: color, year: firstYear)
                cell.layer.zPosition = 100
                return cell
            }
        } else if indexPath.section == PERIOD_STICK_SECTION {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "periodCell", for: indexPath) as? PeriodStickCell {
                let isTopRow = indexPath.item % 2 != 0
                let color = (indexPath.item < colorCache.count) ? colorCache[indexPath.item] : UIColor.gray
                if let period = eventsLayout[indexPath.item] as? Period {
                    cell.configure(isTopRow: isTopRow, color: color, isBeginning: period.isBeginning)
                    cell.isHidden = false
                } else {
                    cell.isHidden = true
                }
                return cell
            }
        }
        return UICollectionViewCell()
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

}
