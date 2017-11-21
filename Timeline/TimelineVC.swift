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

class TimelineVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, BackgroundModifierDelegate, ImageLayoutDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var backgroundModifierContainer: UIView!
    @IBOutlet weak var eventDetailedContainer: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var timeline: Timeline!
    var events: [Event]!
    var eventDetailedVC: EventDetailedVC!
    var imagePaths = [String]()
    var colorCache = [UIColor]()
    var isInitialized = false
    var imgDirectory: NSString!
    var layout: TimelineLayout!
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        collectionView.delegate = self
        collectionView.dataSource = self
        
        if let layout = collectionView?.collectionViewLayout as? TimelineLayout {
            self.layout = layout
            self.layout.delegate = self
        }
        navBar.titleTextAttributes = [ NSAttributedStringKey.font: UIFont(name: "AvenirNext-Regular", size: 30)!, NSAttributedStringKey.foregroundColor: UIColor.darkGray]
        
        backgroundModifierContainer.layer.borderColor = UIColor.lightGray.cgColor
        backgroundModifierContainer.layer.borderWidth = 2
        backgroundModifierContainer.layer.cornerRadius = 4
        
        //store a reference to the image directory
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        imgDirectory = documents.appendingPathComponent("\(TIMELINE_IMAGE_DIRECTORY)/\(timeline.name)") as NSString
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
    
/////IB ACTION METHODS
    
    @IBAction func backBtnPressed(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
//        performSegue(withIdentifier: "timelineToTitleScrn", sender: self)
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
            return imagePaths.count
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
                let path = imgDirectory.appendingPathComponent("\(imagePaths[indexPath.item])")
                cell.imgView.image = resizeImage(image: UIImage(contentsOfFile: path)!)
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
    
    func resizeImage(image: UIImage) -> UIImage {
        let size = image.size
        let scale = collectionView.frame.height / size.height
        UIGraphicsBeginImageContext(CGSize(width: size.width * scale, height: size.height * scale))
        image.draw(in: CGRect(x: 0, y: 0, width: size.width * scale, height: size.height * scale))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    
//////BACKGROUND MODIFIER DELEGATE METHODS
    
    func timelineName() -> String {
        return timeline.name
    }
    
    func updateImageCache(imagePaths: [String]) {
        self.imagePaths = imagePaths
        
        if layout != nil {
            let invalidationContext = TimelineInvalidationContext()
            invalidationContext.invalidateImages = true
            layout.invalidateLayout(with: invalidationContext)
            collectionView.reloadData()
            updateColorCache()
        }
        
    }
    
    func removeContainerView() {
        self.view.subviews[2].removeFromSuperview()
        backgroundModifierContainer.isHidden = true
    }
    
/////IMAGE LAYOUT DELEGATE METHODS
    
    func getSizeAtIndexPath(indexPath: IndexPath) -> CGSize {
        let searchPath = imgDirectory.appendingPathComponent(imagePaths[indexPath.item])
        let tempImg = UIImage(contentsOfFile: searchPath)
        return tempImg!.size
    }
    
/////HELPER METHODS
    
    func updateColorCache() {
        colorCache.removeAll()
        let eventLength = collectionView.frame.height * 0.9
        
        for path in imagePaths {
            let image = resizeImage(image: UIImage(contentsOfFile: imgDirectory.appendingPathComponent(path))!)
            let imageLength: CGFloat = image.size.width * 0.75
            
            var colorSwatch = UIColor.blue
            Palette.generateWith(configuration: PaletteConfiguration(image: image), queue: DispatchQueue.global(qos: .background)) {
                colorSwatch = $0.vibrantColor(defaultColor: UIColor.darkGray)
                var currentPosition: CGFloat = 0
                while currentPosition < imageLength {
                    self.colorCache.append(colorSwatch)
                    currentPosition += eventLength
                }
            }
        }
    }
//
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "initializeBackgroundModifier" {
            if let backgroundModifierVC = segue.destination as? BackgroundModifierVC {
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
