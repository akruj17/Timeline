//
//  Event.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 7/14/17.
//  Copyright © 2017 Edumacation!. All rights reserved.
//

import Foundation
import RealmSwift

class Event: Object, NSCopying{
    @objc dynamic var overview = ""
    @objc dynamic var detailed = ""
    let year = RealmOptional<Int>()
    @objc dynamic var isBCE = false
    @objc dynamic var timeline: Timeline!
    @objc dynamic var id = ""
    @objc dynamic var editsRequired: [String: Bool] = ["year": false, "overview": false]
    
    func isEmpty() -> Bool {
        return (year.value == nil) && overview.isEmpty && detailed.isEmpty
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
        copy.year.value = self.year.value
        copy.isBCE = self.isBCE
        copy.timeline = self.timeline.copy() as! Timeline
        copy.id = self.id
        
        return copy
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
