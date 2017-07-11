//
//  IssueSender.swift
//  SAIssueTracker
//
//  Created by Sandeep Aggarwal on 10/07/17.
//  Copyright © 2017 Sandeep Aggarwal. All rights reserved.
//

import Foundation

@objc protocol IssueSender
{
    var consoleLogsFilePath: String? {get set}
    var exceptionLogsFilePath: String? {get set}
    
   @objc optional func sendLogs()
}
