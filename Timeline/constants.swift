//
//  constants.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 7/31/17.
//  Copyright © 2017 Edumacation!. All rights reserved.
//

import Foundation

let TIMELINE_IMAGE_DIRECTORY = "TimelineImages"
let IMAGE_INFO_PLIST = "imageInfo.plist"
let IMAGE_COUNTER = "imageCounter"
let IMAGE_ORDERING_ARRAY = "imageOrderingArray"

let TITLE_TIMELINE_PADDING = 120



enum UpdateAction {
    case insert
    case delete
    case moveToFront
    case moveToEnd
}