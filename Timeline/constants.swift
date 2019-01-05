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

let TITLE_TIMELINE_PADDING: CGFloat = 120

let PERIOD_CELL_BORDER: CGFloat = 8
let TEXT_FIELD_BORDER: CGFloat = 2
let TEXT_FIELD_RADIUS: CGFloat = 5
let TITLE_BORDER: CGFloat = 5
let EVENT_BORDER: CGFloat = 8

let START_YEAR_INDEX = 0
let END_YEAR_INDEX = 1
let OVERVIEW_INDEX = 2

let EVENT_DETAILED_PLACEHOLDER = "Add an event description..."

let GRAY_CONSTANT = 100

let TITLE_LINE_HEIGHT: CGFloat = 5.0
let TIMELINE_LINE_HEIGHT: CGFloat = 10.0

//Editor modes
let NEW = 0 //a new timeline is being created
let INVALID = 1 //the user must fix something because the state is invalid
let MODIFY = 2 //the user is modifying fields from the timeline screen

let editorViewRed = UIColor(red: 236/255, green: 105/255, blue: 83/255, alpha: 1)

enum UpdateAction {
    case INSERT
    case DELETE
    case MOVE_FRONT
    case MOVE_END
}

enum EventInfo {
    case OVERVIEW
    case DETAILED
    case TIME_PERIOD
    case START_YEAR
    case END_YEAR
}

typealias imageStatusTuple = (filePath: String?, data: Data, selectedStat: Bool, largeSize: CGSize)
