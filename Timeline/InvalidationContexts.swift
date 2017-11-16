//
//  backgroundModifierInvalidationContext.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 8/19/17.
//  Copyright © 2017 Edumacation!. All rights reserved.
//

import UIKit

class BackgroundModifierInvalidationContext: UICollectionViewLayoutInvalidationContext {
    
    private var _invalidatedIndices = [IndexPath]()
    var updateType: UpdateAction!
    var insertionCount: Int!
    
    override func invalidateItems(at indexPaths: [IndexPath]) {
        invalidatedItemIndexPaths = indexPaths
    }
    
    override var invalidatedItemIndexPaths: [IndexPath]? {
        set {
            _invalidatedIndices = newValue as! [IndexPath]
        } get {
            return _invalidatedIndices
        }
    }
}

class TimelineInvalidationContext: UICollectionViewLayoutInvalidationContext {
    
    var invalidateEvents = false
    var invalidateImages = false
    var numberOfEventsToDrop = 0
    
}
