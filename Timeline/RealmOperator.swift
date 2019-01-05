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
            event.timeline = timeline
            let realm = try! Realm()
            try! realm.write {
                realm.add(event)
                print("Created event overview")
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
                        print ("Saved event overview!")
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
        }
    }
    
    static func retrieveEvents(timeline: String, completion: @escaping (inout [Event], Timeline) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let realm = try! Realm()
            let events = Array(realm.objects(Event.self).filter("timeline.name = %@", timeline))
            var eventRefs = [ThreadSafeReference<Event>]()
            for event in events {
                eventRefs.append(ThreadSafeReference(to: event))
            }
            let timeline = realm.objects(Timeline.self).filter("name = %@", timeline)[0]
            let timelineRef = ThreadSafeReference(to: timeline)
            DispatchQueue.main.async {
                let _realm = try! Realm()
                var resolvedEvents = [Event]()
                for eventRef in eventRefs {
                    guard let _event = _realm.resolve(eventRef) else {
                        return // something got messed up...idk
                    }
                    resolvedEvents.append(_event)
                }
                guard let timelineResolved = _realm.resolve(timelineRef) else {
                    return // something got messed up...idk
                }
                completion(&resolvedEvents, timelineResolved)
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
    func deleteTimeline() {
        let realm = try! Realm()
        let events = realm.objects(Event.self).filter("timeline = %@", timeline)
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
            realm.delete(timeline)
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
    
//---------------------------------------------------------------------------------------------------------------------------
    
    //Save copies of the passed in events to the Realm database. Copies are made
    //and saved so that the originals can still be used and modified.
    static func saveToDatabase(events: [Event], timeline: Timeline) {
            autoreleasepool {
                do {
                    let realm = try Realm()
                    //only assign ids to new timelines
                    if timeline.id == "" {
                        timeline.id = NSUUID().uuidString
                    }
                    let timelineCopy = timeline.copy() as! Timeline
                    timelineCopy.createdAt = Date()
                    try realm.write {
                        realm.add(timelineCopy, update: true)
                    }
                    for event in events {
                        //only assign ids and timelines to brand new events. New events are only created
                        //when the timeline parameter is passed into this method, so it is guaranteed to != nil.
                        if event.id == "" {
                            event.id = NSUUID().uuidString
                        }
                        event.timeline = timelineCopy
                        let eventCopy = event.copy() as! Event
                        try realm.write {
                            realm.add(eventCopy, update: true)
                        }
                    }
                } catch _ as NSError {
                    fatalError()
                }
            }
    }
    
    static func saveToDatabase(event: Event) {
        do {
            let realm = try! Realm()
            let eventCopy = event.copy() as! Event
            let timelineCopy = eventCopy.timeline
            timelineCopy!.createdAt = Date()
            try realm.write {
                realm.add(eventCopy, update: true)
                realm.add(timelineCopy!, update: true)
            }
        }  catch _ as NSError {
            fatalError()
        }
    }
    
    //delete the events and/or timeline from the databsase.
    static func deleteFromDatabase(events: [Event], timeline: Timeline? = nil) {
            autoreleasepool {
                do {
                    let realm = try! Realm()
                    //only delete events that were saved at some point
                    for event in events {
                        if event.id != "" {
                            let temp = realm.object(ofType: Event.self, forPrimaryKey: event.id)
                            try realm.write {
                                realm.delete(temp!)
                            }
                        }
                    }
                    if let timelineTitle = timeline {
                        let temp = realm.object(ofType: Timeline.self, forPrimaryKey: timelineTitle.id)
                        try realm.write {
                            realm.delete(temp!)
                        }
                    }
                } catch _ as NSError {
                    fatalError()
                }
        }
    }
    
    static func deleteTimelineFromDatabase(timeline: Timeline) {
        do {
            let realm = try Realm()
            var predicate = NSPredicate(format: "timeline.name = %@", timeline.name)
            let events = Array(realm.objects(Event.self).filter(predicate))
            for event in events {
                try realm.write {
                    realm.delete(event)
                }
            }
            predicate = NSPredicate(format: "name = %@", timeline.name)
            let timeline = realm.objects(Timeline.self).filter(predicate)[0]
            try realm.write {
                realm.delete(timeline)
            }
        }
        catch _ as NSError {
            fatalError()
        }

    }
    
    //retrieve a list of timeline objects
    static func retrieveTimelinesFromDatabase() -> Results<Timeline> {
        var timelineNames: Results<Timeline>!
        do {
            let realm = try Realm()
            timelineNames = realm.objects(Timeline.self).sorted(byKeyPath: "createdAt", ascending: true)
        }
        catch _ as NSError {
            fatalError()
        }
        return timelineNames
    }
    
    //retrieve the events for a timeline from a database. Copies of the events are
    //returned which are thread safe
    static func retrieveEventsFromDatabase(timeline: String) -> ([Event], Timeline) {
        var clone = [Event]()
        var chosen = Timeline()
        do {
            let realm = try Realm(configuration: Realm.Configuration.defaultConfiguration)
            var predicate = NSPredicate(format: "timeline.name = %@", timeline)
            let events = Array(realm.objects(Event.self).filter(predicate))
            for event in events {
                clone.append(event.copy() as! Event)
            }
            predicate = NSPredicate(format: "name = %@", timeline)
            chosen = (realm.objects(Timeline.self).filter(predicate)[0]).copy() as! Timeline
        }
        catch _ as NSError {
            fatalError()
        }
        return (clone, chosen)
    }
    

    
    static func timelineTitleIsNew(timeline: Timeline) -> Bool {
        do {
            let realm = try Realm(configuration: Realm.Configuration.defaultConfiguration)
            let predicate = NSPredicate(format: "name = %@", timeline.name)
            let title = Array(realm.objects(Timeline.self).filter(predicate))
            if title.count == 0 {
                return true;
            } else {   // the user may not have modified the title
                return title[0].id == timeline.id
            }
        } catch _ as NSError {
            fatalError()
        }
        return false
    }
}

