//
//  timelineLayout.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 6/27/17.
//  Copyright © 2017 Edumacation!. All rights reserved.
//

import UIKit

class TitleScrnLayout: UICollectionViewLayout {

    //the height of the collection view
    var contentHeight: CGFloat {
        return collectionView!.frame.height
    }
    //the total width of the title cells, up until the final edge of the "New Timeline" cell
    var contentWidth: CGFloat = 0
    var cache = [UICollectionViewLayoutAttributes]()
    
    
    override func prepare() {
        //this method should only execute if the layout has not been setup, OR if a title cell was added or removed
        if cache.count != collectionView?.numberOfItems(inSection: 0) {
            //The height of each row, which accounts for the central line which is 5 pixels tall
            let rowHeight = (contentHeight / CGFloat(2)) - 2.5
            let titleCellHeight = 0.85 * rowHeight //height of each cell with a timeline title
            
            let titleCellWidth = titleCellHeight
            let titleBoxWidth = 0.7 * titleCellWidth
            let padding = 0.3 * titleCellWidth
            
            let yOffset: [CGFloat] = [rowHeight - titleCellHeight, rowHeight + 2.5]
            var xOffset: [CGFloat] = [0, (titleBoxWidth / 2) + (padding / 2)]
            var row = 0
            
            if cache.isEmpty {
                contentWidth = 0
            } else {  //The "new timeline" cell has already been invalidated
                contentWidth = cache.last!.frame.minX + titleCellWidth //end point for last cell
                //end point for second to last cell, and where the first new cell will placed
                var startPoint: CGFloat = (cache.count == 1) ? xOffset[1] : cache[cache.count - 2].frame.minX + titleCellWidth
                if cache.count % 2 == 0 {
                    //the next cell put down will be on the top row
                    xOffset = [startPoint, contentWidth]
                } else {
                    xOffset = [contentWidth, startPoint]
                    row = 1
                }
            }
            
            let numberOfItems = collectionView!.numberOfItems(inSection: 0)
            for item in cache.count ..< numberOfItems {
                let indexPath = IndexPath(item: item, section: 0)
                var frame = CGRect()
                if item == (numberOfItems - 1) {
                    if item % 2 == 0 {
                        frame = CGRect(x: xOffset[row], y: 0, width: (0.7 * rowHeight), height: rowHeight)
                    } else {
                        frame = CGRect(x: xOffset[row], y: yOffset[row], width: (0.7 * rowHeight), height: rowHeight)
                    }
                    xOffset[row] += (0.7 * rowHeight)
                } else {
                    frame = CGRect(x: xOffset[row], y: yOffset[row], width: titleBoxWidth, height: titleCellHeight)
                    xOffset[row] += titleCellWidth
                }
                
                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.frame = frame
                cache.append(attributes)
                
                row = (row + 1) > 1 ? 0: 1
            }
            
            contentWidth = max(xOffset[0], xOffset[1])
        }
    }
    
    override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var layoutAttributes = [UICollectionViewLayoutAttributes]()
        if cache.isEmpty {
            self.prepare()
        }
        for attributes in cache {
            if attributes.frame.intersects(rect) {
                if ((attributes.frame.origin.x + attributes.frame.size.width <= self.collectionViewContentSize.width) &&
                    (attributes.frame.origin.y + attributes.frame.size.height <= self.collectionViewContentSize.height)) {
                layoutAttributes.append(attributes)
                }
            }
        }

        return layoutAttributes
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache[indexPath.row]
    }
    
    override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        if let invalidatedPaths = context.invalidatedItemIndexPaths {
            cache.removeLast(invalidatedPaths.count)
        }
    }
    
}
