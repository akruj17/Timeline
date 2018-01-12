//
//  TimelineLayout.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 7/10/17.
//  Copyright © 2017 Edumacation!. All rights reserved.
//

import UIKit

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
            let eventHeight = contentHeight * 0.30
            
            //This is actually the event cell width plus end padding
            eventCellWidth = eventHeight * 3
            
            var yOffset: [CGFloat] = [((contentHeight / 2) - 5) - eventHeight, (contentHeight / 2) + 5]
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
                
                frame = CGRect(x: xOffset[row], y: yOffset[row], width: (0.7 * eventCellWidth), height: eventHeight)
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

}
