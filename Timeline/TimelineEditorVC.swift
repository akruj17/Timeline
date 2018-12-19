//
//  TimelineEditorController.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 7/2/17.
//  Copyright © 2017 Edumacation!. All rights reserved.
//

import UIKit
import RealmSwift

class TimelineEditorVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    @IBOutlet weak var blurView: UIVisualEffectView!

    var eventInfoArray: [Event]!
    var deletedEvents = [Event]()
    var timelineTitle = Timeline()
    var titleNeedsEditing = false
    var isNewTimeline = false
    var backgroundThread = DispatchQueue(label: "realmThread", qos: .background)
    var trashcanIcon: UIImage!
    weak var titleDelegate: TitleScreenLayoutDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        AppUtility.lockOrientation(.all)

        tableView.dataSource = self
        tableView.delegate = self
        //If the timeline is being created for the first time, fields should appear empty. Otherwise, fields should be filled with prior data from database.
        if isNewTimeline {
            eventInfoArray = [Event]()
            initializeNumRows(rows: 5)
        }
        //set up for loading animation
        blurView.layer.borderColor = UIColor.lightGray.cgColor
        blurView.layer.cornerRadius = 16
        blurView.layer.borderWidth = 1
        indicatorView.backgroundColor = UIColor.clear
        //set up the trashcan icon in case the user chooses to delete an event
        trashcanIcon = createIcons(image: UIImage(named: "trashcan")!)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        blurView.isHidden = true
        indicatorView.stopAnimating();
        tableView.reloadData()
    }
    
    
/////IB ACTION METHODS
    
    //dismiss the view controller without saving any changes made
    @IBAction func cancelPressed(_ sender: Any) {
        let warningAlert = UIAlertController(title: "Are you sure?", message: "Any edits will not be saved", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        let positiveAction = UIAlertAction(title: "Discard", style: .destructive) { [unowned self] action in
            if self.isNewTimeline {
                self.navigationController?.popToRootViewController(animated: false)
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        }
        warningAlert.addAction(cancelAction)
        warningAlert.addAction(positiveAction)
        present(warningAlert, animated: true, completion: nil)
    }
    
    
    //Add a new event form to the table when the addEvent button is pressed
    @IBAction func addEventPressed(_ sender: Any) {
        initializeNumRows(rows: 1)
    }
    
    
    //Perform validation and saving operations when the done button is pressed
    @IBAction func donePressed(_ sender: Any) {
        self.view.endEditing(true)
        blurView.isHidden = false
        indicatorView.startAnimating()
        //only "attempted events" will be saved
        DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
            let eventInfoArray = self.eventInfoArray.filter({
                !($0.isEmpty())
            })
            //make sure "attempted events" and the timeline title are properly completed
            let needsEdit = self.performEventValidation(eventArray: eventInfoArray)
            //if fields were left empty or the number of complete events is less than 3, set an incomplete alert
            //check if the timeline name is valid
            var nameIsValid: Bool
            if self.isNewTimeline {
                nameIsValid = RealmOperator.timelineTitleIsNew(title: self.timelineTitle.name)
            } else {
                nameIsValid = RealmOperator.timelineTitleIsNew(timeline: self.timelineTitle)
            }
            if needsEdit || eventInfoArray.count < 3 || !nameIsValid {
                let incompleteAlert = UIAlertController(title: "Incomplete", message: nil, preferredStyle: .alert)
                incompleteAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                if needsEdit {
                    incompleteAlert.title = "Fields that still need to be completed are highlighted in red."
                }
                else if eventInfoArray.count < 3 {
                    incompleteAlert.title = "Your timeline must have at least three completed events."
                    self.initializeNumRows(rows: 3 - eventInfoArray.count)
                } else {  // the title is not valid
                    incompleteAlert.title = "A timeline with this title already exists."
                }
                //present the alert on the main thread
                DispatchQueue.main.async(execute: { [unowned self] in
                    self.blurView.isHidden = true
                    self.indicatorView.stopAnimating()
                    self.present(incompleteAlert, animated: true, completion: self.tableView.reloadData)
                })
            } else {
                //At this point, the timeline is valid and will be saved in the Realm. Deleted
                //events will be removed.
                RealmOperator.saveToDatabase(events: eventInfoArray, timeline: self.timelineTitle)
                DispatchQueue.main.async(execute: { [unowned self] in
                    if self.isNewTimeline {
                        //Create directory for time line's images
                        FileSystemOperator.createImageDirectory(name: self.timelineTitle.name)
                        self.titleDelegate.updateNumTitles(numTitles: 1)
                        self.performSegue(withIdentifier: "editorToTimeline", sender: eventInfoArray)
                    } else {
                        RealmOperator.deleteFromDatabase(events: self.deletedEvents)
                        self.navigationController?.popViewController(animated: true)
                    }
                })
            }
        }
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
        if indexPath.section == 0 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "titleFormCell", for: indexPath) as? TimelineTitleEditorCell {
                cell.configure(timeline: timelineTitle)
                return cell
            }
        }
        else {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "eventFormCell", for: indexPath) as? EventEditorCell {
                cell.configure(index: indexPath.row + 1, eventInfo: eventInfoArray[indexPath.row])
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

    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteButton = UITableViewRowAction(style: .normal, title: "                      ") { [unowned self] action, index in
            self.deletedEvents.append(self.eventInfoArray.remove(at: indexPath.item))
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.reloadData()
            tableView.reloadRows(at: tableView.indexPathsForVisibleRows!, with: UITableViewRowAnimation.automatic)
        }
        deleteButton.backgroundColor = UIColor(patternImage: trashcanIcon)
        return [deleteButton]
    }
    

    
//////HELPER METHODS
    
    //Adds a certain number of empty event forms to the table
    func initializeNumRows(rows: Int) {
        var indexPaths = [IndexPath]()
        for _ in 0 ..< rows {
            let event = Event()
            eventInfoArray.append(event)
            indexPaths.append(IndexPath(row: eventInfoArray.count - 1, section: 1))
        }
        tableView.insertRows(at: indexPaths, with: .bottom)
    }
    
    
    //creates the trashcan of fixed size
    func createIcons(image: UIImage) -> UIImage {
        let width: CGFloat = 80
        let height: CGFloat = 300
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0.0)
        let origin = CGPoint(x: (width - image.size.width) / 2.0, y: (height - image.size.height) / 2.0)
        image.draw(at: origin)
       
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    
    //verify timeline event fields are properly completed
    func performEventValidation(eventArray: [Event]) -> Bool {
        var requiresEdits = false
        if eventArray.count > 0 {
            for event in eventArray {
                if event.startYear.value == nil {
                    event.editsRequired.updateValue(true, forKey: "startYear")
                    requiresEdits = true
                }
                if event.isTimePeriod {
                    if event.endYear.value == nil {
                        event.editsRequired.updateValue(true, forKey: "endYear")
                        requiresEdits = true
                    } else if event.endYear.value! < event.startYear.value! {
                        event.editsRequired.updateValue(true, forKey: "endYear")
                        event.editsRequired.updateValue(true, forKey: "startYear")
                        requiresEdits = true
                    }
                }
                if event.overview.isEmpty {
                    event.editsRequired.updateValue(true, forKey: "overview")
                    requiresEdits = true
                }
            }
        }
        if self.timelineTitle.name.replacingOccurrences(of: " ", with: "") == "" {
            self.timelineTitle.editsRequired = true
            requiresEdits = true
        }
        return requiresEdits
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editorToTimeline" {
            if let timelineVC = segue.destination as? TimelineVC {
                timelineVC.timeline = timelineTitle
                let events = sender as! [Event]
                // sort the events because this is the VERY FIRST TIME the timeline will be opened
                timelineVC.events = events
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Don't forget to reset when view is being removed
        AppUtility.lockOrientation(.landscape)
    }
    
}
