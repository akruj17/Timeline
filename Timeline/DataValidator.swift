//
//  DataValidator.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 12/28/18.
//  Copyright © 2018 Edumacation!. All rights reserved.
//

import Foundation

class DataValidator {
    //verify timeline event fields are properly completed
    static func performValidation(events: inout [Event], editsTracker: inout [[Bool]], title: Timeline) -> (requiresEdits: Bool, titleEmpty: Bool, titleTaken: Bool) {
        //first filter out empty events
        for (i, event) in events.enumerated().reversed() {
            if event.isEmpty() {
                RealmOperator.deleteEvent(event: event)
                events.remove(at: i)
            }
        }
        var result = (requiresEdits: false, titleEmpty: false, titleTaken: false)
        //reset all edits
        if events.count > 0 {
            for i in 0 ..< events.count {
                editsTracker.append([false, false, false])
                let event = events[i]
                //make sure start year is correctly filled out
                if event.startYear.value == nil {
                    editsTracker[i][START_YEAR_INDEX] = true
                    result.requiresEdits = true
                }
                //make sure end year is correctly filled, if appropriate. Its year must be < than startYear
                if event.isTimePeriod {
                    if event.endYear.value == nil || (event.endYear.value! < event.startYear.value!) {
                        editsTracker[i][END_YEAR_INDEX] = true
                        result.requiresEdits = true
                    }
                }
                if event.overview.isEmpty {
                    editsTracker[i][OVERVIEW_INDEX] = true
                    result.requiresEdits = true
                }
            }
        } else {
            // must have at least one timeline event
            result.requiresEdits = true
        }
        if title.name.replacingOccurrences(of: " ", with: "") == "" {
            result.titleEmpty = true
            result.requiresEdits = true
        }
        if RealmOperator.titleAlreadyExists(title: title.name) {
            result.titleTaken = true
        }
        return result
    }
}
