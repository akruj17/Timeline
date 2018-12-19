//
//  TimelineLayout.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 7/10/17.
//  Copyright © 2017 Edumacation!. All rights reserved.
//

import UIKit

var collectionHeight: CGFloat!
class TimelineLayout: UICollectionViewLayout {

    var eventCellWidth: CGFloat!
    var eventContentWidth: CGFloat = 0
    var imageContentWidth: CGFloat = 0
    var contentHeight: CGFloat {
        return collectionView!.frame.height
    }
    
    var eventCache = [UICollectionViewLayoutAttributes]()
    var imageCache = [UICollectionViewLayoutAttributes]()
    
    var delegate: ImageLayoutDelegate!
    var eventDelegate: EventLayoutDelegate!
    
    override func prepare() {
        //Setup for images
        if imageCache.count != collectionView!.numberOfItems(inSection: 0) {
            imageContentWidth = 0
            var width: CGFloat = 0
            for item in imageCache.count ..< collectionView!.numberOfItems(inSection: 0) {
                let indexPath = IndexPath(item: item, section: 0)
                var frame = CGRect()
                
                width = resizeImage(originalSize: delegate.getSizeAtIndexPath(indexPath: indexPath))
                frame = CGRect(x: imageContentWidth, y: 0, width: width, height: contentHeight)
                imageContentWidth += (width * 0.75)
                
                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.frame = frame
                imageCache.append(attributes)
            }
            imageContentWidth += (0.25 * width)
        }
        //Setup for events
        if eventCache.count != collectionView!.numberOfItems(inSection: 1) {
            collectionHeight = contentHeight
            //This is actually the event cell width plus end padding
            eventCellWidth = contentHeight * 0.8
            
            var xOffset: [CGFloat] = [20, 20 + (eventCellWidth / 2)]
            var row = 0
            
            if !eventCache.isEmpty {
                let startPoint = eventCache.last!.frame.minX + (eventCellWidth / 2)
                if eventCache.count % 2 == 0 {
                    xOffset = [startPoint, eventContentWidth]
                } else {
                    xOffset = [eventContentWidth , startPoint]
                    row = 1
                }
            }
            
            for item in eventCache.count ..< collectionView!.numberOfItems(inSection: 1) {
                let indexPath = IndexPath(item: item, section: 1)

                var frame = CGRect()
                var cellHeight: CGFloat = contentHeight * 0.3 // default for events
                var yPos: CGFloat = (row % 2 == 0) ? ((contentHeight / 2) - 5) - cellHeight : (contentHeight / 2) + 5
                if eventDelegate.isTimeObjectPeriod(index: item) {
                    cellHeight = 0.85 * contentHeight
                    if row == 0 {
                        yPos = contentHeight * 0.1
                    } else {
                        yPos = contentHeight * 0.05
                    }
                }
                frame = CGRect(x: xOffset[row], y: yPos, width: (0.7 * eventCellWidth), height: cellHeight)
                xOffset[row] = xOffset[row] + eventCellWidth
                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.frame = frame
                eventCache.append(attributes)
                
                row = (row + 1) > 1 ? 0: 1
            }
            eventContentWidth = max(xOffset[0], xOffset[1])
        }
    }
    
    override var collectionViewContentSize: CGSize {
        return CGSize(width: max(eventContentWidth, imageContentWidth), height: contentHeight)
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var layoutAttributes = [UICollectionViewLayoutAttributes]()
        if eventCache.isEmpty || imageCache.isEmpty {
            self.prepare()
        }
        
        for attributes in eventCache {
            if attributes.frame.intersects(rect) {
                layoutAttributes.append(attributes)
            }
        }
        for attributes in imageCache {
            if attributes.frame.intersects(rect) {
                layoutAttributes.append(attributes)
            }
        }
        
        return layoutAttributes
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return eventCache[indexPath.row]
    }
    
    
    override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        if let cont = context as? TimelineInvalidationContext {
            if cont.invalidateEvents {
                eventCache.removeLast(cont.numberOfEventsToDrop)
                if let lastFrame = eventCache.last {
                    eventContentWidth = lastFrame.frame.maxX + (0.3 * eventCellWidth)
                } else {
                    eventContentWidth = 0
                }
            }
            if cont.invalidateImages {
                imageCache.removeAll()
            }
            
        }
    }
    
    private func resizeImage(originalSize: CGSize) -> CGFloat {
        let scale = contentHeight / originalSize.height
        return scale * originalSize.width
    }
    
    private func generateEventHeight(index: Int) -> CGFloat {
        let minEventHeight = contentHeight * 0.30
        let maxEventHeight = contentHeight * 0.45
        if eventDelegate.isEventAtIndexFirstOfYear(index: index) { 
            return 0.35 * contentHeight
        } else if index >= 0 && index < 4 {
            return CGFloat(arc4random_uniform(UInt32(maxEventHeight - minEventHeight)) + UInt32(minEventHeight))
        } else {
            let prevHeight = eventCache[index - 2].frame.height
            let prevPrevHeight = eventCache[index - 4].frame.height
            if prevHeight < prevPrevHeight {  // this cell should have a greater height to keep the pattern
                return CGFloat(arc4random_uniform(UInt32(maxEventHeight - prevHeight)) + UInt32(prevHeight))
            } else { // this cell should have a lower height to keep the pattern
                return CGFloat(arc4random_uniform(UInt32(prevHeight - minEventHeight)) + UInt32(minEventHeight))
            }
        }
        
    }

}

protocol EventLayoutDelegate: class {
    func isEventAtIndexFirstOfYear(index: Int) -> Bool
    func isTimeObjectPeriod(index: Int) -> Bool
}
