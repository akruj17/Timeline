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
    var delegate: TitleCollectionDelegate!
    
    override func prepare() {
        //this method should only execute if the layout has not been setup, OR if a title cell was added or removed
        if cache.count != collectionView!.numberOfItems(inSection: 0) {
            //The height of each row, which accounts for the central line which is 5 pixels tall
            let rowHeight = (contentHeight / CGFloat(2)) - (TITLE_LINE_HEIGHT / 2)
            let titleCellHeight = 0.85 * rowHeight //height of each cell with a timeline title
            //TITLE CELL WIDTH = BOX WIDTH + PADDING
            let titleCellWidth = titleCellHeight
            let titleBoxWidth = 0.7 * titleCellWidth
            
            let yOffset: [CGFloat] = [rowHeight - titleCellHeight, rowHeight + (TITLE_LINE_HEIGHT / 2)]
            var xOffset: [CGFloat] = [0, (titleCellWidth / 2)]
            var row = 0
            
            if cache.isEmpty {
                //starting from scratch. Layout is being initialized
                contentWidth = 0
            } else {
                //The length of the cache must be at least one because of the "new timeline" cell
                assert(cache.count >= 1)
                //remove the "new timeline" cell first, we will append it later, and we may need to delete events instead of insert
                let numToRemove = cache.count - collectionView!.numberOfItems(inSection: 0)
                cache.removeLast((numToRemove > 0) ? (numToRemove + 1) : 1)
                //end point for last cell
                contentWidth = (cache.last == nil) ? 0 : cache.last!.frame.minX + titleCellWidth
                //end point for second to last cell, and where the first new cell will placed
                let startPoint = (cache.count <= 1) ? xOffset[cache.count] : cache[cache.count - 2].frame.minX + titleCellWidth
                if cache.count % 2 == 0 {
                    //the next cell put down will be on the top row
                    xOffset = [startPoint, contentWidth]
                } else {
                    xOffset = [contentWidth, startPoint]
                    row = 1
                }
            }
            
            let numTitles = collectionView!.numberOfItems(inSection: 0) - 1
            //add cells for the regular titles
            for item in cache.count ..< numTitles {
                let indexPath = IndexPath(item: item, section: 0)
                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.frame = CGRect(x: xOffset[row], y: yOffset[row], width: titleBoxWidth, height: titleCellHeight)
                xOffset[row] += titleCellWidth
                cache.append(attributes)   // make this second to last element
                row = (row + 1) > 1 ? 0: 1
            }
            //now add "new timeline" cell
            let new_timeline_cell = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: cache.count, section: 0))
            new_timeline_cell.frame = CGRect(x: xOffset[row], y: (cache.count % 2 == 0) ? 0 : yOffset[row], width: 0.7 * rowHeight, height: rowHeight)
            xOffset[row] += (0.7 * rowHeight)
            cache.append(new_timeline_cell)
            //update contentWidth
            contentWidth = max(xOffset[0], xOffset[1])
            delegate.updateCollectionWidth(newWidth: contentWidth)
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
        var found = false //allows breaking early since attributes are ordered
        for attributes in cache {
            if attributes.frame.intersects(rect) {
                if ((attributes.frame.origin.x + attributes.frame.size.width <= self.collectionViewContentSize.width) &&
                    (attributes.frame.origin.y + attributes.frame.size.height <= self.collectionViewContentSize.height)) {
                    layoutAttributes.append(attributes)
                    found = true
                }
            } else if found {
                break
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
