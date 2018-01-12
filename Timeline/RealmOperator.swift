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
                } catch let error as NSError {
                    fatalError()
                }
                print("\(Realm.Configuration.defaultConfiguration.fileURL)")
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
                } catch let error as NSError {
                    fatalError()
                }
        }
    }
    
    //retrieve a list of timeline objects
    static func retrieveTimelinesFromDatabase() -> Results<Timeline> {
        var timelineNames: Results<Timeline>!
        do {
            let realm = try Realm()
            timelineNames = realm.objects(Timeline.self).sorted(byKeyPath: "createdAt", ascending: true)
        }
        catch let error as NSError {
            print("\(error)")
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
            print("\(events.count)")
            for event in events {
                clone.append(event.copy() as! Event)
            }
            predicate = NSPredicate(format: "name = %@", timeline)
            chosen = (realm.objects(Timeline.self).filter(predicate)[0]).copy() as! Timeline
        }
        catch let error as NSError {
            print("\(error)")
        }
        return (clone, chosen)
    }
    
    static func timelineTitleIsNew(title: String) -> Bool {
        do {
            let realm = try Realm(configuration: Realm.Configuration.defaultConfiguration)
            var predicate = NSPredicate(format: "name = %@", title)
            let title = Array(realm.objects(Timeline.self).filter(predicate))
            return title.count == 0
        } catch let error as NSError {
            print("\(error)")
        }
        return false
    }
    
    static func timelineTitleIsNew(timeline: Timeline) -> Bool {
        do {
            let realm = try Realm(configuration: Realm.Configuration.defaultConfiguration)
            var predicate = NSPredicate(format: "name = %@", timeline.name)
            let title = Array(realm.objects(Timeline.self).filter(predicate))
            if title.count == 0 {
                return true;
            } else {   // the user may not have modified the title
                return title[0].id == timeline.id
            }
        } catch let error as NSError {
            print("\(error)")
        }
        return false
    }
}

