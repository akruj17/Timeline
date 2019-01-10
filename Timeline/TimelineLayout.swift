//
//  TimelineLayout.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 7/10/17.
//  Copyright © 2017 Edumacation!. All rights reserved.
//

import UIKit

class TimelineLayout: UICollectionViewLayout {

    var eventContentWidth: CGFloat = 0
    var imageContentWidth: CGFloat = 0
    var contentHeight: CGFloat {
        return collectionView!.frame.height
    }

    var imageCache = [UICollectionViewLayoutAttributes]()
    var eventCache = [UICollectionViewLayoutAttributes]()
    var periodStickCache = [UICollectionViewLayoutAttributes]()
    weak var delegate: TimelineCollectionDelegate!
    
    override func prepare() {
        //Setup for images
        if imageCache.count != collectionView!.numberOfItems(inSection: IMAGE_SECTION) {
            imageContentWidth = (imageCache.count > 0) ? imageCache.last!.frame.maxX : 0
            for item in imageCache.count ..< collectionView!.numberOfItems(inSection: IMAGE_SECTION) {
                let width = delegate.getWidthAtIndexPath(index: item)
                let attributes = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: item, section: IMAGE_SECTION))
                attributes.frame = CGRect(x: imageContentWidth, y: 0, width: width, height: contentHeight)
                imageContentWidth += (width * 0.75)
                imageCache.append(attributes)
            }
            imageContentWidth += (imageCache.count > 0) ? (0.25 * imageCache.last!.frame.width) : 0
        }
        //Setup for events. eventXposCache and eventHeightCache should ALWAYS have same number of items
        if eventCache.count != collectionView!.numberOfItems(inSection: EVENT_SECTION) {
            //This is actually the event cell width plus end padding
            let eventCellWidth = contentHeight * 0.8
            let eventCellHeight = contentHeight * 0.3
            let periodTopRowYOffset = 0.1 * contentHeight
            
            var xOffset: [CGFloat] = [TIMELINE_OFFSET, TIMELINE_OFFSET + (eventCellWidth / 2)]
            //for events, and periods on the top row
            let yOffset = [(contentHeight / 2) - (TIMELINE_LINE_HEIGHT / 2) - eventCellHeight, (contentHeight / 2) + (TIMELINE_LINE_HEIGHT / 2)]
            var row = 0
            
            if eventCache.isEmpty {
                //starting from scratch. Layout is being initialized
                eventContentWidth = 0
            } else {
                let numToRemove = eventCache.count - collectionView!.numberOfItems(inSection: EVENT_SECTION)
                eventCache.removeLast((numToRemove > 0) ? numToRemove : 0)
                periodStickCache.removeLast((numToRemove > 0) ? numToRemove : 0)
                //end point for last cell
                eventContentWidth = (eventCache.last == nil) ? TIMELINE_OFFSET : eventCache.last!.frame.minX + eventCellWidth
                //end point for second to last cell, and where the first new cell will placed
                let startPoint = (eventCache.count <= 1) ? xOffset[eventCache.count] : eventCache[eventCache.count - 2].frame.minX + eventCellWidth
                if eventCache.count % 2 == 0 {
                    //the next cell put down will be on the top row
                    xOffset = [startPoint, eventContentWidth]
                } else {
                    xOffset = [eventContentWidth, startPoint]
                    row = 1
                }
            }
            
            let numEvents = collectionView!.numberOfItems(inSection: EVENT_SECTION)
            //add cells for the new events
            for item in eventCache.count ..< numEvents {
                //add attributes for the event
                let eventAttributes = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: item, section: EVENT_SECTION))
                eventAttributes.frame = CGRect(x: xOffset[row], y: yOffset[row % 2], width: 0.7 * eventCellWidth, height: eventCellHeight)
                eventCache.append(eventAttributes)
                //add attributes for the period stick
                let stickAttributes = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: item, section: PERIOD_STICK_SECTION))
                stickAttributes.frame = CGRect(x: xOffset[row], y: row % 2 == 1 ? periodTopRowYOffset : yOffset[1], width: 0.7 * eventCellWidth, height: 0.4 * contentHeight)
                periodStickCache.append(stickAttributes)
                xOffset[row] += eventCellWidth
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
        //check each cache individually, but generalize the checking
        let attributeCaches = [eventCache, periodStickCache, imageCache]
        for cache in attributeCaches {
            var foundEnd = false
            for attributes in cache {
                if attributes.frame.intersects(rect) {
                    layoutAttributes.append(attributes)
                    foundEnd = true
                } else if foundEnd {
                    break
                }
            }
        }
        return layoutAttributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if indexPath.section == IMAGE_SECTION {
            return imageCache[indexPath.item]
        } else if indexPath.section == PERIOD_STICK_SECTION {
            return periodStickCache[indexPath.item]
        } else {
            return eventCache[indexPath.item]
        }
    }
    
    func invalidateImageLayout(startingAt index: Int) {
        imageCache.removeLast(imageCache.count - index)
    }
}


