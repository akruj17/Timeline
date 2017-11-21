//
//  CacheArray.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 11/20/17.
//  Copyright © 2017 Edumacation!. All rights reserved.
//

import Foundation

class CacheArray<T> {
    var cacheArray = [T]()
    var beginningCounter: Int
    
    init(beginningCounter: Int) {
        self.beginningCounter = beginningCounter
    }
}
