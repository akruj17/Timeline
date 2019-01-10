//
//  RealmOperator.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 9/27/17.
//  Copyright © 2017 Edumacation!. All rights reserved.
//

import Foundation
import RealmSwift
import Realm

class RealmOperator {
    
    var timeline: Timeline
    
    init(_timeline: Timeline) {
        timeline = _timeline
        //if this timeline is new, save it to the database
        if timeline.id == "" {
            timeline.id = NSUUID().uuidString
            timeline.name = _timeline.name
            let realm = try! Realm()
            try! realm.write {
                realm.add(timeline)
                print("Created title")
            }
        }
    }
    
    func persistTitle(title: String, sync: Bool) {
        let timelineRef = ThreadSafeReference(to: timeline)
        // I use a block to avoid redundancy and having to create a separate function
        let block: () -> Void = {
            autoreleasepool {
                let realm = try! Realm()
                guard let _timeline = realm.resolve(timelineRef) else {
                    return // something got messed up...idk
                }
                try! realm.write {
                    _timeline.name = title
                    print ("Saved title!")
                }
            }
        }
        if sync {
            DispatchQueue.global(qos: .background).sync(execute: block)
        } else {
            DispatchQueue.global(qos: .background).async(execute: block)
        }
    }
    
    func persistEventField(event: Event, field: Any?, type: EventInfo, sync: Bool) {
        //check if the event is new, if so, cannot create reference yet
        if event.id == "" {
            event.id = NSUUID().uuidString
            event.timeline = timeline
            updateEventField(event: event, field: field, type: type)
            let realm = try! Realm()
            try! realm.write {
                realm.add(event)
            }
        } else {
            let eventRef = ThreadSafeReference(to: event)
            // I use a block to avoid redundancy and having to create a separate function
            let block: () -> Void = {
                autoreleasepool {
                    let realm = try! Realm()
                    guard let _event = realm.resolve(eventRef) else {
                        return // something got messed up...idk
                    }
                    try! realm.write {
                        self.updateEventField(event: _event, field: field, type: type)
                    }
                }
            }
            if sync {
                DispatchQueue.global(qos: .background).sync(execute: block)
            } else {
                DispatchQueue.global(qos: .background).async(execute: block)
            }
        }
    }
    
    private func updateEventField(event: Event, field: Any?, type: EventInfo) {
        switch type {
        case .OVERVIEW:
            let text = field as! String
            event.overview = (text.replacingOccurrences(of: " ", with: "") == "") ? "" : text
        case .DETAILED:
            let text = field as! String
            event.detailed = (text.replacingOccurrences(of: " ", with: "") == "") ? "" : text
        case .TIME_PERIOD:
            event.isTimePeriod = field as! Bool
        case .START_YEAR:
            event.startYear.value = field as! Int?
        case .END_YEAR:
            event.endYear.value = field as! Int?
        case .DEFAULT:
            break
        }
    }

    static func retrieveEvents(timeline: Timeline, sorted: Bool, completion: @escaping (inout Results<Event>) -> Void) {
        let timelineRef = ThreadSafeReference(to: timeline)
        DispatchQueue.global(qos: .background).async {
            let realm = try! Realm()
            guard let _timeline = realm.resolve(timelineRef) else {
                return //something got messed up...idk
            }
            var events = realm.objects(Event.self).filter("timeline = %@", _timeline)
            if sorted {
                events = events.sorted(byKeyPath: "startYear", ascending: true)
            }
            let eventRefs = ThreadSafeReference(to: events)
            DispatchQueue.main.async {
                let _realm = try! Realm()
                guard var resolvedEvents = _realm.resolve(eventRefs) else {
                    return // something got messed up...idk
                }
                completion(&resolvedEvents)
            }
        }
    }

    
    static func deleteEvent(event: Event) {
        //if the id has not been assigned, this event was never put in the database
        if event.id != "" {
            let eventRef = ThreadSafeReference(to: event)
            DispatchQueue.global(qos: .background).async {
                autoreleasepool {
                    let realm = try! Realm()
                    guard let _event = realm.resolve(eventRef) else {
                        return // something got messed up...idk
                    }
                    try! realm.write {
                        realm.delete(_event)
                        print ("Deleted event!")
                    }
                }
            }
        }
    }
    
    //THE REALM OPERATOR OBJECT SHOULD NOT BE USED AFTER CALLING THIS METHOD
    static func deleteTimeline(title: Timeline) {
        let realm = try! Realm()
        let events = realm.objects(Event.self).filter("timeline = %@", title)
        let eventsRef = ThreadSafeReference(to: events)
        //delete events on background thread
        DispatchQueue.global(qos: .background).async {
            autoreleasepool {
                let _realm = try! Realm()
                guard let _events = _realm.resolve(eventsRef) else {
                    return // something got messed up...idk
                }
                for event in _events {
                    try! _realm.write {
                        _realm.delete(event)
                    }
                }
            }
        }
        //delete the timeline on the main thread, so the Results variable immediately updates
        try! realm.write {
            realm.delete(title)
        }
    }
    
    static func titleAlreadyExists(title: String) -> Bool {
        var alreadyExists = false
        DispatchQueue.global(qos: .background).sync {
            autoreleasepool {
                let realm = try! Realm()
                let results = realm.objects(Timeline.self).filter("name = %@", title)
                // this title will already exist once for the current timeline
                alreadyExists = results.count > 1
            }
        }
        return alreadyExists
    }
}
