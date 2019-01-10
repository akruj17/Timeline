//
//  ViewController.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 6/15/17.
//  Copyright © 2017 Edumacation!. All rights reserved.
//

import UIKit
import RealmSwift

class TitleScreenVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, CollectionReloadDelegate, TitleCollectionDelegate {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var containerLeadingMargin: NSLayoutConstraint!
    @IBOutlet weak var containerTrailingMargin: NSLayoutConstraint!
    
    @IBOutlet weak var collectionLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionTrailingConstraint: NSLayoutConstraint!
    
    weak var layout: TitleScrnLayout!
    var timelineNames: Results<Timeline>?
    var loadingIndex = -1
    var names = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "j", "K", "l", "m", "N", "O", "P", "q", "R", "s", "t"]

    struct TimelineArgs {
        var mode: Int
        var eventResults: Results<Event>?
        var eventArray: [Event]?
        var timeline: Timeline?
        var editsTracker: [[Bool]]?
        var titleInvalid: Bool?
        var requiresEdits: Bool?
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        self.navigationController?.delegate = self
        collectionView.dataSource = self
        collectionView.delegate = self
        if let layout = collectionView?.collectionViewLayout as? TitleScrnLayout {
            self.layout = layout
            self.layout.delegate = self
            self.layout.sizeClass = self.view.traitCollection.verticalSizeClass
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
            loadingIndex = -1
        }
    }

    
    func updateCollectionWidth(newWidth: CGFloat) {
        //set the timeline visual length dependent on the number of collectionview objects.
        if newWidth < (view.bounds.width - CGFloat(2 * TITLE_TIMELINE_PADDING)) {
            containerLeadingMargin.constant = ((view.bounds.width - newWidth) / 2) - view.layoutMargins.left
            containerTrailingMargin.constant = ((view.bounds.width - newWidth) / 2) - view.layoutMargins.right
            collectionView.isScrollEnabled = false
        } else {
            let padding = (self.view.traitCollection.verticalSizeClass == .regular) ? TITLE_TIMELINE_PADDING : TITLE_TIMELINE_PADDING_COMPACT
            containerLeadingMargin.constant = padding
            containerTrailingMargin.constant = padding
            collectionView.isScrollEnabled = true
            DispatchQueue.main.async {
                self.collectionView.scrollToItem(at: IndexPath(item: (self.timelineNames!.count), section: 0), at: .right, animated: false)

            }
        }
    }
    
    
    //////////////////COLLECTIONVIEW METHODS
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return names.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "titleCell", for: indexPath) as? TitleScreenCell {
            let isTopRow = (indexPath.item % 2 == 0) || (self.view.traitCollection.verticalSizeClass == .compact)
            //Configure collectionview cells to appear as timeline objects. Last index has a special configuration to say "New Timeline"
            let title = (indexPath.item < names.count) ? names[indexPath.item] : "New Timeline"
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
            let args = TimelineArgs(mode: NEW, eventResults: nil, eventArray: nil, timeline: nil, editsTracker: nil, titleInvalid: nil, requiresEdits: nil)
            self.performSegue(withIdentifier: "titleScrnToEditor", sender: args)
        } else if let cell = collectionView.cellForItem(at: indexPath) as? TitleScreenCell {
            self.loadingIndex = indexPath.item
            cell.setLoading(isLoading: true)
            RealmOperator.retrieveEvents(timeline: timelineNames![indexPath.item], sorted: false) { (events) in
                var editsTracker = [[Bool]]()
                var arrayForm = Array(events)
                let timeline = self.timelineNames![indexPath.item]
                let valid = DataValidator.performValidation(events: &arrayForm, editsTracker: &editsTracker, title: timeline)
                if valid.requiresEdits || valid.titleTaken {
                    //edits are required, switch to editor
                    let timelineInvalid = valid.titleEmpty || valid.titleTaken
                    let args = TimelineArgs(mode: INVALID, eventResults: nil, eventArray: arrayForm, timeline: timeline, editsTracker: editsTracker, titleInvalid: timelineInvalid, requiresEdits: valid.requiresEdits)
                    self.performSegue(withIdentifier: "titleScrnToEditor", sender: args)
                } else {
                    //TIMELINE IS VALID SWITCH TO TIMELINE VC
                    let args = TimelineArgs(mode: -1, eventResults: events, eventArray: nil, timeline: timeline, editsTracker: nil, titleInvalid: nil, requiresEdits: nil)
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
                    //the user has confirmed they want to delete the timeline
                    RealmOperator.deleteTimeline(title: self.timelineNames![index.item])
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
                    editorVC.eventInfoArray = Array(args.eventArray!)
                    editorVC.timelineTitle = args.timeline
                    editorVC.titleInvalid = args.titleInvalid!
                    editorVC.editsTracker = args.editsTracker!
                    editorVC.requiresEdits = args.requiresEdits!
                }
                editorVC.titleDelegate = self
                editorVC.titleScreen = self
            }
        } else if segue.identifier == "titleScrnToTimeline" {
            if let timelineVC = segue.destination as? TimelineVC {
                let args = sender as! TimelineArgs
                timelineVC.timeline = args.timeline
                timelineVC.events = args.eventResults
                timelineVC.titleDelegate = self
            }
        }
    }
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if viewController is TimelineEditorVC || viewController is TimelineVC {
            if let cell = collectionView.cellForItem(at: IndexPath(item: loadingIndex, section: 0)) as? TitleScreenCell {
                cell.setLoading(isLoading: false)
            }
            loadingIndex = -1
        }
    }
    
    func updateCollection(completion: ((Bool) -> ())?) {
        collectionView.reloadData()
        collectionView.performBatchUpdates(nil, completion: completion)
    }
}

