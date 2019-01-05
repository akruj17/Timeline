//
//  TimelineEditorController.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 7/2/17.
//  Copyright © 2017 Edumacation!. All rights reserved.
//

import UIKit
import RealmSwift

class TimelineEditorVC: UIViewController, UITableViewDataSource, UITableViewDelegate, EditorDataSaveDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var loadingScreen: LoadingScreen!
    @IBOutlet weak var navItems: UINavigationItem!
    
    // ALL THE DATA
    var eventInfoArray: [Event]!
    var timelineTitle: Timeline!
    var realmOperator: RealmOperator!
    // TRACKING INVALID INPUT
    var editsTracker = [[Bool]]()
    var titleInvalid = false
    // OTHER STATE
    var doneEditing = false
    var requiresEdits = false
    var mode = NEW
    weak var titleDelegate: CollectionReloadDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        AppUtility.lockOrientation(.all)
        tableView.dataSource = self
        tableView.delegate = self
        //If the timeline is being created for the first time, fields should appear empty. Otherwise, fields should be filled with prior data from database.
        if mode == NEW {
            timelineTitle = Timeline()
            
            eventInfoArray = [Event]()
            initializeNumRows(rows: 5)
        } else if mode == INVALID {
            // eventInfoArray and timelineTitle should already be instantiated
            if eventInfoArray.count == 0 {
                initializeNumRows(rows: 5)
            }
            presentIncompleteMessage(requiresEdits: requiresEdits)
        } else {
            //only present cancel option for new timelines that have not been validated
            navItems.leftBarButtonItem = nil
        }

        realmOperator = RealmOperator(_timeline: timelineTitle)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    
    
/////IB ACTION METHODS
    
    //Add a new event form to the table when the addEvent button is pressed
    @IBAction func addEventPressed(_ sender: Any) {
        initializeNumRows(rows: 1)
    }
    
    
    //Perform validation and saving operations when the done button is pressed
    @IBAction func donePressed(_ sender: Any) {
        doneEditing = true  //set so that final write occurs synchronously
        self.view.endEditing(true)
        doneEditing = false
        let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        doneButton.customView = activityIndicator
        activityIndicator.startAnimating()
        //delete the empty events first. This must be done on the main thread becasue of thread safety and the
        //delete method already creates its own background thread. At the same time, filter the array
        DispatchQueue.main.async {
            self.editsTracker = [[Bool]] () //reset the editsTracker
            //perform validation, the method will modify the eventInfoArray, editsTracker, and timelineInvalid variables
            let valid = DataValidator.performValidation(events: &self.eventInfoArray, editsTracker: &self.editsTracker, title: self.timelineTitle)
            self.titleInvalid = valid.titleEmpty || valid.titleTaken
            self.doneButton.customView = nil
            if valid.requiresEdits || valid.titleTaken {
                self.presentIncompleteMessage(requiresEdits: valid.requiresEdits)
            } else {
                //TIMELINE IS VALID
                self.loadingScreen.isHidden = false
                self.titleDelegate.updateCollection(updateType: .INSERT, completion: nil)
                self.performSegue(withIdentifier: "editorToTimeline", sender: nil)
            }
        }
    }
    
    func presentIncompleteMessage(requiresEdits: Bool) {
        var message = ""
        // the timeline must have at least one complete event
        if self.eventInfoArray.count < 1 {
            message = "Your timeline must have at least one completed event."
            if self.eventInfoArray.count == 0 {
                self.initializeNumRows(rows: 1)
            }
        } else if requiresEdits {
            // the timeline has incomplete fields
            message = "Fields that still need to be completed are highlighted in red"
        } else {
            // the title is already taken
            message = "A timeline with this title already exists"
        }
        // now create an incomplete alert
        let incompleteAlert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        incompleteAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(incompleteAlert, animated: true, completion: self.tableView.reloadData)
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        let incompleteAlert = UIAlertController(title: "Warning", message: nil, preferredStyle: .alert)
        incompleteAlert.addAction(UIAlertAction(title: "OK", style: .destructive, handler: {[unowned self] action in
            //the user has confirmed they would like to delete the timeline
            self.realmOperator.deleteTimeline()
            self.navigationController?.popToRootViewController(animated: true)
        }))
        incompleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        incompleteAlert.title = "Are you sure you want to delete this timeline? This action cannot be undone later."
        self.present(incompleteAlert, animated: true, completion: nil)
    }
    
    
    
///////////////TABLEVIEW METHODS
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return eventInfoArray.count
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 { //title row
            if let cell = tableView.dequeueReusableCell(withIdentifier: "titleFormCell", for: indexPath) as? TimelineTitleEditorCell {
                cell.configure(timeline: timelineTitle, invalid: titleInvalid)
                cell.delegate = self
                return cell
            }
        }
        else {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "eventFormCell", for: indexPath) as? EventEditorCell {
                cell.configure(index: indexPath.row + 1, event: eventInfoArray[indexPath.row], invalid: editsTracker[indexPath.row])
                cell.delegate = self
                return cell
            }
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 100
        }
        return 300
    }

    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let incompleteAlert = UIAlertController(title: "Warning", message: nil, preferredStyle: .alert)
            incompleteAlert.addAction(UIAlertAction(title: "OK", style: .destructive, handler: {[unowned self] action in
                //the user has confirmed they would like to delete the event
                RealmOperator.deleteEvent(event: self.eventInfoArray.remove(at: indexPath.item))
                self.editsTracker.remove(at: indexPath.item)
                UIView.animate(withDuration: 0.5, animations: {
                    tableView.deleteRows(at: [indexPath], with: .fade)
                }) { (success) in
                    tableView.reloadData()
                }
            }))
            incompleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            incompleteAlert.title = "Are you sure you want to delete this event? This action cannot be undone later."
            self.present(incompleteAlert, animated: true, completion: nil)
        }
    }

//////EDITOR DATA SAVE METHODS
    func saveTitle(title: String) {
        realmOperator.persistTitle(title: title, sync: doneEditing)
        // mark the title as invalid if it is
        titleInvalid = title.replacingOccurrences(of: " ", with: "") == ""
    }
    
    func saveYear(year: Int?, index: Int) {
        let event = eventInfoArray[index]
        realmOperator.persistEventField(event: event, field: year, type: EventInfo.START_YEAR, sync: doneEditing)
        editsTracker[index][START_YEAR_INDEX] = (year == nil)
    }
    
    func saveOverview(overview: String, index: Int) {
        let event = eventInfoArray[index]
        realmOperator.persistEventField(event: event, field: overview, type: EventInfo.OVERVIEW, sync: doneEditing)
        editsTracker[index][OVERVIEW_INDEX] = overview.replacingOccurrences(of: " ", with: "") == ""
    }
    
    func saveDetailed(detailed: String, index: Int) {
        let event = eventInfoArray[index]
        realmOperator.persistEventField(event: event, field: detailed, type: EventInfo.DETAILED, sync: doneEditing)
    }
    
    func saveTimePeriod(isTimePeriod: Bool, index: Int) {
        let event = eventInfoArray[index]
        realmOperator.persistEventField(event: event, field: isTimePeriod, type: EventInfo.TIME_PERIOD, sync: doneEditing)
        // if no longer a time period, turn off edits for end year
        if !isTimePeriod {
            editsTracker[index][END_YEAR_INDEX] = false
        }
    }
    
    func saveEndYear(year: Int?, index: Int) {
        let event = eventInfoArray[index]
        realmOperator.persistEventField(event: event, field: year, type: EventInfo.END_YEAR, sync: doneEditing)
        editsTracker[index][END_YEAR_INDEX] = (year == nil)
    }
    
    
//////HELPER METHODS
    
    //Adds a certain number of empty event forms to the table
    func initializeNumRows(rows: Int) {
        var indexPaths = [IndexPath]()
        for _ in 0 ..< rows {
            let event = Event()
            eventInfoArray.append(event)
            indexPaths.append(IndexPath(row: eventInfoArray.count - 1, section: 1))
            editsTracker.append([false, false, false])
        }
        tableView.reloadData()
    }
    
    
    //verify timeline event fields are properly completed
    private func performValidation(events: [Event]) -> Bool {
        var requiresEdits = false
        //reset all edits
        self.editsTracker = [[Bool]]()
        if events.count > 0 {
            for i in 0 ..< events.count {
                self.editsTracker.append([false, false, false])
                let event = events[i]
                //make sure start year is correctly filled out
                if event.startYear.value == nil {
                    self.editsTracker[i][START_YEAR_INDEX] = true
                    requiresEdits = true
                }
                //make sure end year is correctly filled, if appropriate. Its year must be < than startYear
                if event.isTimePeriod {
                    if event.endYear.value == nil || (event.endYear.value! < event.startYear.value!) {
                        self.editsTracker[i][END_YEAR_INDEX] = true
                        requiresEdits = true
                    }
                }
                if event.overview.isEmpty {
                    self.editsTracker[i][OVERVIEW_INDEX] = true
                    requiresEdits = true
                }
            }
        }
        if self.timelineTitle.name.replacingOccurrences(of: " ", with: "") == "" {
            self.titleInvalid = true
            requiresEdits = true
        }
        return requiresEdits
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editorToTimeline" {
            if let timelineVC = segue.destination as? TimelineVC {
                timelineVC.timeline = timelineTitle
                timelineVC.events = eventInfoArray
                timelineVC.titleDelegate = self.titleDelegate
            }
        }
    }
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if viewController is TimelineVC {
            loadingScreen.isHidden = true
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Don't forget to reset when view is being removed
        AppUtility.lockOrientation(.landscape)
    }
}
