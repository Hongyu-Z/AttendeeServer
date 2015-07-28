//
//  AttendeeManager.swift
//  SwiftAttendeeCollector
//
//  Created by Zhu, Hongyu on 7/27/15.
//  Copyright (c) 2015 Zhu, Hongyu. All rights reserved.
//

import Foundation

class AttendeeManager : NSObject {
    var attendeeArray:Array<Attendee>!;
    
    override init () {
        super.init()
        self.attendeeArray = []
    }
    
    func addAttendee(newAttendee attendee:Attendee){
        self.attendeeArray.append(attendee)
    }

    func attendeeAtIndex(#index:Int) -> Attendee{
        return self.attendeeArray[index]
    }
    
    func clear(){
        self.attendeeArray.removeAll(keepCapacity: false)
    }
    
    func count() -> Int{
        return self.attendeeArray.count
    }

}