//
//  constants.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 7/31/17.
//  Copyright © 2017 Edumacation!. All rights reserved.
//

import UIKit

let TIMELINE_IMAGE_DIRECTORY = "TimelineImages"
let FIRST_IMAGES_DIRECTORY = "FirstImages"
let IMAGE_INFO_PLIST = "imageInfo.plist"
let IMAGE_COUNTER = "imageCounter"
let IMAGE_ORDERING_ARRAY = "imageOrderingArray"

let TITLE_TIMELINE_PADDING = 120

let PERIOD_CELL_BORDER: CGFloat = 10

let editorViewRed = UIColor(red: 236/255, green: 105/255, blue: 83/255, alpha: 1)

enum UpdateAction {
    case insert
    case delete
    case moveToFront
    case moveToEnd
}

typealias imageStatusTuple = (filePath: String?, data: Data, selectedStat: Bool, largeSize: CGSize)
