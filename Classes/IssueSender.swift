//
//  IssueSender.swift
//  SAIssueTracker
//
//  Created by Sandeep Aggarwal on 10/07/17.
//  Copyright © 2017 Sandeep Aggarwal. All rights reserved.
//

import Foundation

protocol IssueSender
{
    var consoleLogsFilePath: String? {get set}
    var exceptionLogsFilePath: String? {get set}
    var screenShotFilePath: String? { get set }
    
    func sendLogs(completion: @escaping( _ completion: Bool, _ error: Error?) -> Void)
}
