//
//  SAIssueTracker.swift
//  SAIssueTracker
//
//  Created by Sandeep Aggarwal on 08/07/17.
//  Copyright © 2017 Sandeep Aggarwal. All rights reserved.
//

import Foundation
import UIKit


protocol IssueTracker
{
    var optedForConsoleLogs : Bool { get }
    var optedForExceptionLogs : Bool { get }
    
    func sendConsoleLogs()
    func sendUnCaughtExceptions()
}

// MARK: SAIssueTracker

class SAIssueTracker : IssueTracker
{
    private var email: String
    private var consoleLogs: Bool
    private var exceptionLogs: Bool
    
    fileprivate var _consoleLogFilePointer: UnsafeMutablePointer<FILE>?
    fileprivate var _exceptionsLogFilePointer: UnsafeMutablePointer<FILE>?
    
    public init(email: String, consoleLogs: Bool , exceptionLogs: Bool)
    {
        self.email = email
        self.consoleLogs = consoleLogs
        self.exceptionLogs = exceptionLogs
        
        if amIAttachedToDebugger()
        {
            //so as to continue to log on developer's Xcode console
           return
        }
        
        if optedForConsoleLogs
        {
            saveConsoleLogsInFile()
        }
        if optedForExceptionLogs
        {
            saveExceptionLogsInFile()
            configureUnCaughtExceptionLogs()
        }
        closeLogFilesOnAppTermination()
    }
    
    var optedForConsoleLogs: Bool
    {
        return consoleLogs
    }
    
    var optedForExceptionLogs: Bool
    {
        return exceptionLogs
    }
    
    func sendUnCaughtExceptions()
    {
        
    }

    func sendConsoleLogs()
    {
        
    }
}

// MARK: SAIssueTracker Methods

private extension SAIssueTracker
{
    enum SAIssueTracker
    {
        static let consoleLogFileName = "console.log"
        static let exceptionsLogFileName = "exceptions.log"
    }
    
    func saveConsoleLogsInFile()
    {
        let pathForLog = documentDirectoryPathAppending(path: SAIssueTracker.consoleLogFileName)
        _consoleLogFilePointer = freopen(pathForLog.cString(using: String.Encoding.ascii)!, "w", stdout)
        setvbuf(_consoleLogFilePointer, nil, _IONBF, 0)
    }
    
    func saveExceptionLogsInFile()
    {
        let pathForLog = documentDirectoryPathAppending(path: SAIssueTracker.exceptionsLogFileName)
        _exceptionsLogFilePointer = freopen(pathForLog.cString(using: String.Encoding.ascii)!, "w", stderr)
         setvbuf(_exceptionsLogFilePointer, nil, _IONBF, 0)
    }
    
    func configureUnCaughtExceptionLogs()
    {
        //for objc exceptions
        NSSetUncaughtExceptionHandler(exceptionHandler(exception:))
        
        //for Swift exceptions
        for sig in exceptionSignals()
        {
            signal(sig)
            { (sig) in
                fputs("Stack Trace:\n \(Thread.callStackSymbols.joined(separator: "\n"))", __stderrp)
                exit(sig)
            }
        }
    }
    
    func closeLogFilesOnAppTermination()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(closeStreams), name:NSNotification.Name.UIApplicationWillTerminate , object: UIApplication.shared)
    }
    
    @objc func closeStreams()
    {
        if (_consoleLogFilePointer != nil)
        {
            fclose(_consoleLogFilePointer)
        }
        
        if (_exceptionsLogFilePointer != nil)
        {
            fclose(_exceptionsLogFilePointer)
        }
    }
    
    func documentDirectoryPathAppending(path: String) -> String
    {
        let allPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = allPaths.first!
        let fullPath = documentsDirectory.appending("/\(path)")
        return fullPath;
    }
    
    func isValid(email: String?) -> Bool
    {
        let emailRegEx = "(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"+"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"+"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"+"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"+"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"+"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"+"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])"
        
        let emailTest = NSPredicate(format:"SELF MATCHES[c] %@", emailRegEx)
        return emailTest.evaluate(with: email)
    }
}

//MARK: Global functions

func exceptionHandler(exception : NSException)
{
    fputs("Stack Trace:\n \(exception.callStackSymbols.joined(separator: "\n"))", __stderrp)
    
    //reset so that duplicate Stack Trace from Signals doesn't get print up
    resetDefaultHandlingForUncaughtExceptions()
}

func resetDefaultHandlingForUncaughtExceptions()
{
    NSSetUncaughtExceptionHandler(nil)
    for sig in exceptionSignals()
    {
        signal(sig,SIG_DFL)
    }
}

func exceptionSignals() -> [Int32]
{
    return [SIGTRAP, SIGABRT, SIGILL, SIGSEGV, SIGFPE, SIGBUS, SIGPIPE]
}
