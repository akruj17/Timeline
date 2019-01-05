//
//  BackgroundModifierLayout.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 7/28/17.
//  Copyright © 2017 Edumacation!. All rights reserved.
//

import UIKit

@objc protocol ImageLayoutDelegate {
    func getSizeAtIndexPath(indexPath: IndexPath) -> CGSize
    @objc optional func setShouldRefresh()
}

class BackgroundModifierLayout: UICollectionViewLayout {

    var cache = [UICollectionViewLayoutAttributes]()
    var imageSizeCache = [CGFloat]()
    var contentHeight: CGFloat {
        return collectionView!.frame.height
    }

    
    var xOffset: CGFloat = 0
    var delegate: ImageLayoutDelegate!
    var layoutInitialized = false

    override func prepare() {
        if cache.count != collectionView!.numberOfItems(inSection: 0) {
            if cache.isEmpty {
                xOffset = 0
            } else {
                xOffset = cache.last!.frame.maxX
            }
            
            for item in cache.count ..< collectionView!.numberOfItems(inSection: 0) {
                let indexPath = IndexPath(item: item, section: 0)
                
                var frame = CGRect()
                let width: CGFloat
                if item < imageSizeCache.count {
                    width = imageSizeCache[item]
                } else {
                    width = resizeImage(originalSize: delegate.getSizeAtIndexPath(indexPath: indexPath))
                    imageSizeCache.append(width)
                }
                frame = CGRect(x: xOffset, y: 0, width: width, height: contentHeight)
                xOffset += width
                
                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.frame = frame
                cache.append(attributes)
            }
            
        }
        
        layoutInitialized = true
    }
    
    override var collectionViewContentSize: CGSize {
        return CGSize(width: xOffset, height: contentHeight)
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
    
    override func invalidationContext(forInteractivelyMovingItems targetIndexPaths: [IndexPath], withTargetPosition targetPosition: CGPoint, previousIndexPaths: [IndexPath], previousPosition: CGPoint) -> UICollectionViewLayoutInvalidationContext {
        
        let context = super.invalidationContext(forInteractivelyMovingItems: targetIndexPaths, withTargetPosition: targetPosition, previousIndexPaths: previousIndexPaths, previousPosition: previousPosition)
        
        if targetIndexPaths[0].item != previousIndexPaths[0].item {
            let currentAttr = layoutAttributesForItem(at: previousIndexPaths[0])!
            let destAttr = layoutAttributesForItem(at: targetIndexPaths[0])!
            let currentImageSize = layoutAttributesForItem(at: previousIndexPaths[0])!.size
            let destImageSize = layoutAttributesForItem(at: targetIndexPaths[0])!.size
            
            if targetIndexPaths[0].item > previousIndexPaths[0].item {
                destAttr.frame = CGRect(x: destAttr.frame.maxX - currentImageSize.width, y: 0, width: currentImageSize.width, height: contentHeight)
                currentAttr.frame = CGRect(x: currentAttr.frame.minX, y: 0, width: destImageSize.width, height: contentHeight)
            }
            else {
                destAttr.frame = CGRect(x: destAttr.frame.minX, y: 0, width: currentImageSize.width, height: contentHeight)
                currentAttr.frame = CGRect(x: destAttr.frame.maxX, y: 0, width: destImageSize.width, height: contentHeight)
            }
            
            let size = imageSizeCache.remove(at: previousIndexPaths[0].item)
            imageSizeCache.insert(size, at: targetIndexPaths[0].item)
            
            delegate.setShouldRefresh!()
            self.collectionView!.dataSource?.collectionView!(self.collectionView!, moveItemAt: previousIndexPaths[0], to: targetIndexPaths[0])
            
        }
        
        return context
    }
    
//    override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
//        if !updateItems.isEmpty {
//            if updateItems[0].updateAction == UICollectionUpdateAction.insert {
//                let startIndex = updateItems[0].indexPathAfterUpdate!.item
//                if cache.count != startIndex {
//                    cache.removeSubrange(startIndex...(cache.count - 1))
//                }
//                
//                for item in 0 ..< updateItems.count {
//                    let insertionIndex = startIndex + item
//                    let originalSize = delegate.getSizeAtIndexPath(indexPath: IndexPath(item: insertionIndex, section: 0))
//                    imageSizeCache.insert(resizeImage(originalSize: originalSize), at: insertionIndex)
//                }
//            } else if updateItems[0].updateAction == UICollectionUpdateAction.delete {
//                let startIndex = updateItems[0].indexPathBeforeUpdate!.item
//                cache.removeSubrange(startIndex...(cache.count - 1))
//                
//                for deletion in updateItems {
//                    imageSizeCache[deletion.indexPathBeforeUpdate!.item] = -1.0
//                }
//                
//                imageSizeCache = imageSizeCache.filter({
//                    !($0 == -1.0)}
//                )
//            }
//            needsPrepare = true
//            prepare()
//
//        }
//    }
    
    override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        if let cont = context as? BackgroundModifierInvalidationContext {
            switch cont.updateType! {
            case .INSERT:
                if let startIndex = cont.invalidatedItemIndexPaths?[0].item {
                    if cache.count != startIndex {
                        cache.removeSubrange(startIndex...(cache.count - 1))
                    }
                    
                    for item in 0 ..< cont.insertionCount {
                        let insertionIndex = startIndex + item
                        let originalSize = delegate.getSizeAtIndexPath(indexPath: IndexPath(item: insertionIndex, section: 0))
                        imageSizeCache.insert(resizeImage(originalSize: originalSize), at: insertionIndex)
                    }
                }
            case .DELETE:
                if let startIndex = cont.invalidatedItemIndexPaths?.sorted()[0].item {
                    cache.removeSubrange(startIndex...(cache.count - 1))
                }
                
                for indexPath in cont.invalidatedItemIndexPaths! {
                    imageSizeCache[indexPath.item] = -1.0
                }
                
                imageSizeCache = imageSizeCache.filter({
                    !($0 == -1.0)
                })
            case .MOVE_FRONT:
                cache.removeAll()
                
                var tempSizes = [CGFloat]()
                for indexPath in cont.invalidatedItemIndexPaths! {
                    tempSizes.append(imageSizeCache[indexPath.item])
                    imageSizeCache[indexPath.item] = -1.0
                }
                
                imageSizeCache = imageSizeCache.filter({
                    !($0 == -1.0)
                })
                
                imageSizeCache.insert(contentsOf: tempSizes, at: 0)
            case .MOVE_END:
                if let startIndex =  cont.invalidatedItemIndexPaths?.sorted()[0].item {
                    cache.removeSubrange(startIndex...(cache.count - 1))
                }
                
                var tempSizes = [CGFloat]()
                for indexPath in cont.invalidatedItemIndexPaths! {
                    tempSizes.append(imageSizeCache[indexPath.item])
                    imageSizeCache[indexPath.item] = -1.0
                }
                
                imageSizeCache = imageSizeCache.filter({
                    !($0 == -1.0)
                })
                
                imageSizeCache.append(contentsOf: tempSizes)

//            default:
//                super.invalidateLayout(with: cont)
            }
        }
    }
    
    private func resizeImage(originalSize: CGSize) -> CGFloat {
        let scale = contentHeight / originalSize.height
        return scale * originalSize.width
    }

}
