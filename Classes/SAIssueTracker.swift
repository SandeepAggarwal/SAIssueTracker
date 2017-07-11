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
    var issueSender: IssueSender { get set }
    var optedForConsoleLogs : Bool { get }
    var optedForExceptionLogs : Bool { get }
    var consoleLogsFilePath: String? { get set }
    var exceptionLogsFilePath: String? { get set }
    
    func send()
}

// MARK: SAIssueTracker

class SAIssueTracker : IssueTracker
{
    var consoleLogsFilePath: String?
    var exceptionLogsFilePath: String?

    var issueSender: IssueSender

    private var consoleLogs: Bool
    private var exceptionLogs: Bool
    
    fileprivate var _consoleLogFilePointer: UnsafeMutablePointer<FILE>?
    fileprivate var _exceptionsLogFilePointer: UnsafeMutablePointer<FILE>?
    
    public init(issueSender: IssueSender, consoleLogs: Bool , exceptionLogs: Bool)
    {
        self.issueSender = issueSender
        self.consoleLogs = consoleLogs
        self.exceptionLogs = exceptionLogs
        
        if amIAttachedToDebugger()
        {
            //so as to continue to log on developer's Xcode console
           return
        }
        
        if optedForConsoleLogs
        {
            consoleLogsFilePath = saveConsoleLogsInFile()
            self.issueSender.consoleLogsFilePath = consoleLogsFilePath
        }
        if optedForExceptionLogs
        {
            exceptionLogsFilePath = saveExceptionLogsInFile()
            self.issueSender.exceptionLogsFilePath = exceptionLogsFilePath
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
    
    func send()
    {
        self.issueSender.sendLogs!()
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
    
    func saveConsoleLogsInFile() -> String
    {
        let pathForLog = documentDirectoryPathAppending(path: SAIssueTracker.consoleLogFileName)
        _consoleLogFilePointer = freopen(pathForLog.cString(using: String.Encoding.ascii)!, "w", stdout)
        setvbuf(_consoleLogFilePointer, nil, _IONBF, 0)
        return pathForLog
    }
    
    func saveExceptionLogsInFile() -> String
    {
        let pathForLog = documentDirectoryPathAppending(path: SAIssueTracker.exceptionsLogFileName)
        _exceptionsLogFilePointer = freopen(pathForLog.cString(using: String.Encoding.ascii)!, "w", stderr)
         setvbuf(_exceptionsLogFilePointer, nil, _IONBF, 0)
        return pathForLog
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
