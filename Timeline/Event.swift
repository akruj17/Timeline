//
//  Event.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 7/14/17.
//  Copyright © 2017 Edumacation!. All rights reserved.
//

import Foundation
import RealmSwift

class Event: Object, TimeObject{
    @objc dynamic var overview = ""
    @objc dynamic var detailed = ""
    let startYear = RealmOptional<Int>()
    let endYear = RealmOptional<Int>()
    @objc dynamic var isTimePeriod = false
    @objc dynamic var timeline: Timeline!
    @objc dynamic var id = ""
    
    func isEmpty() -> Bool {
        if isTimePeriod {
            return (startYear.value == nil) && (endYear.value == nil) && overview.isEmpty && detailed.isEmpty
        }
        return (startYear.value == nil) && overview.isEmpty && detailed.isEmpty
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    var year: Int {
        get {
            return startYear.value!
        }
    }
    
    var event: Event {
        get {
            return self
        } set {}
    }
}

class Timeline: Object {
    @objc dynamic var name = ""
    @objc dynamic var createdAt = Date()
    @objc dynamic var id = ""
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

class Period: TimeObject {
    var isBeginning: Bool!
    var myEvent: Event!
    
    init(event: Event, beginning: Bool) {
        self.myEvent = event
        self.isBeginning = beginning
    }
    
    var year: Int {
        get {
            return isBeginning ? myEvent.startYear.value! : myEvent.endYear.value!
        }
    }
    
    var event: Event {
        get {
            return myEvent
        } set {
            self.myEvent = newValue
        }
    }
}

protocol TimeObject {
    var event: Event {get set}
    var year: Int {get}
}
