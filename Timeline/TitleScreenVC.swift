//
//  ViewController.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 6/15/17.
//  Copyright © 2017 Edumacation!. All rights reserved.
//

import UIKit
import RealmSwift

class TitleScreenVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var containerLeadingMargin: NSLayoutConstraint!
    @IBOutlet weak var containerTrailingMargin: NSLayoutConstraint!
    
    @IBOutlet weak var collectionLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionTrailingConstraint: NSLayoutConstraint!
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        print("touched\(touch.location(in: self.view))")
    }
    
    @IBAction func btnPress(_ sender: Any) {
        let t = Timeline()
        t.name = "BLUFFERs"
        t.id = NSUUID().uuidString
        let realm = try! Realm()
        try! realm.write {
            realm.add(t)
        }
        print("HI")
        print("\(timelineNames!.count)")
        
    }
    
    
    
    weak var layout: TitleScrnLayout!
    var collectionViewLoadedDetector = 0
    var timelineNames: Results<Timeline>?
    var indicator = UIActivityIndicatorView()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        collectionView.dataSource = self
        collectionView.delegate = self
        if let layout = collectionView?.collectionViewLayout as? TitleScrnLayout {
            self.layout = layout
        }
        
        //Obtain all timeline names from the database, and sort them chronologically
        let realm = try! Realm()
        timelineNames = realm.objects(Timeline.self).sorted(byKeyPath: "createdAt", ascending: true)
    }
    
    override func viewDidLayoutSubviews() {
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
    
    override func viewWillAppear(_ animated: Bool) {
        indicator.stopAnimating()
        if (timelineNames!.count + 1) > collectionView.numberOfItems(inSection: 0)
        {
            let currentItemLength = collectionView.numberOfItems(inSection: 0)
            let invalidationContext = UICollectionViewLayoutInvalidationContext()
            invalidationContext.invalidateItems(at: [IndexPath(item: currentItemLength - 1, section: 0)])
            layout.invalidateLayout(with: invalidationContext)
            
            collectionView.reloadData()
            collectionView.scrollToItem(at: IndexPath(item: (timelineNames?.count)!, section: 0), at: .right, animated: false)
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
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "titleCell", for: indexPath) as? TimelineEventBoxCell {
            let isTopRow = indexPath.item % 2 == 0 ? true: false
            
            //Configure collectionview cells to appear as timeline objects. Last index has a special configuration to say "New Timeline"
            if indexPath.item < timelineNames!.count {
                cell.configure(isTopRow: isTopRow, title: timelineNames![indexPath.item].name, color: UIColor.darkGray)
            } else {
                cell.configure(isTopRow: isTopRow, title: "New Timeline", color: UIColor.darkGray)
            }
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
            //Present loading activity indicator while timeline loads
//            if let cell = collectionView.cellForItem(at: indexPath) as? TimelineEventBoxCell {
//                let eventBox = cell.timelineBox.eventBox
//                indicator.activityIndicatorViewStyle = .whiteLarge
//                indicator.color = UIColor.red
//                indicator.frame.size = CGSize(width: eventBox.frame.width, height: eventBox.frame.height)
//                indicator.frame.origin = CGPoint(x: 0, y: 0)
//                indicator.backgroundColor = UIColor.white
//                cell.timelineBox.eventBox.addSubview(indicator)
//                self.indicator.startAnimating()
                performSegue(withIdentifier: "titleScrnToTimeline", sender: indexPath.item)
//            }
            

        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "titleScrnToEditor" {
            if let editorVC = segue.destination as? TimelineEditorVC {
                editorVC.isNewTimeline = true
            }
        } else if segue.identifier == "titleScrnToTimeline" {
            if let timelineVC = segue.destination as? TimelineVC {
                let timelineName = timelineNames![sender as! Int]
                timelineVC.timeline = timelineName.copy() as! Timeline
//                let tuple = RealmOperator.retrieveEventsFromDatabase(timeline: timelineName.name)
//                timelineVC.events = tuple.0
//                timelineVC.timeline = tuple.1
            }
        }
    }
    
}

