//
//  Event.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 7/14/17.
//  Copyright © 2017 Edumacation!. All rights reserved.
//

import Foundation
import RealmSwift

class Event: Object, NSCopying, TimeObject{
    @objc dynamic var overview = ""
    @objc dynamic var detailed = ""
    let startYear = RealmOptional<Int>()
    let endYear = RealmOptional<Int>()
    @objc dynamic var isTimePeriod = false
    @objc dynamic var timeline: Timeline!
    @objc dynamic var id = ""
    @objc dynamic var editsRequired: [String: Bool] = ["startYear": false, "endYear": false, "overview": false]
    
    func isEmpty() -> Bool {
        if isTimePeriod {
            return (startYear.value == nil) && (endYear.value == nil) && overview.isEmpty && detailed.isEmpty
        }
        return (startYear.value == nil) && overview.isEmpty && detailed.isEmpty
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["editsRequired"]
    }

    func copy(with zone: NSZone? = nil) -> Any {
        let copy = Event()
        copy.overview = self.overview
        copy.detailed = self.detailed
        copy.startYear.value = self.startYear.value
        copy.endYear.value = self.endYear.value
        copy.isTimePeriod = self.isTimePeriod
        copy.timeline = self.timeline.copy() as! Timeline
        copy.id = self.id
        
        return copy
    }
    
    var year: Int {
        get {
            return startYear.value!
        }
    }
    
    var event: Event {
        get {
            return self
        } set {
        }
    }
}

class Timeline: Object, NSCopying {
    @objc dynamic var name = ""
    @objc dynamic var createdAt = Date()
    @objc dynamic var id = ""
    @objc dynamic var editsRequired = false
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["editsRequired"]
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = Timeline()
        copy.name = self.name
        copy.createdAt = self.createdAt
        copy.id = self.id

        return copy
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
    var year: Int {get}
    var event: Event {get set}
}
