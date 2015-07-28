//
//  Attendee.swift
//  SwiftAttendeeCollector
//
//  Created by Zhu, Hongyu on 7/27/15.
//  Copyright (c) 2015 Zhu, Hongyu. All rights reserved.
//

import Foundation


class Attendee: NSObject {
    
    var firstName: String!
    var lastName:  String!
    var headLine: String!
//    var attendeeTypeID: String!
    var id: String!
    
    // initialize
    init(firstName first: String = "", lastName last: String, headLine head: String, attendeeID id: String = "") {
        super.init()
        self.headLine = head
        firstName = first
        lastName = last
//        attendeeTypeID = typeID
        self.id = id
    }
    
    // returns the attendee's information in JSON format
    func jsonFormat() -> String {
        
        var body = "{ "
        body += "\"FirstName\": \"" + firstName + "\", "
        body += "\"LastName\": \"" + lastName + "\", "
//        body += "\"AttendeeTypeID\": \"" + attendeeTypeID + "\" }"
        body += "}"
        return body
    }
}