//
//  SAIssueTracker.swift
//  SAIssueTracker
//
//  Created by Sandeep Aggarwal on 08/07/17.
//  Copyright © 2017 Sandeep Aggarwal. All rights reserved.
//

import Foundation
import UIKit


extension FileManager
{
    static func checkIfFileIsEmpty(path: String) -> Bool
    {
        let manager = FileManager.default
        guard manager.fileExists(atPath: path) else
        {
            return true //empty
        }
        
        do
        {
            let attributes = try manager.attributesOfItem(atPath: path)
            let size: UInt64 = attributes[FileAttributeKey.size] as! UInt64
            
            return (size == 0) //empty
        }
        catch
        {
            return true //empty
        }
    }
}

private extension UIWindow
{
    func capture() -> UIImage
    {
        UIGraphicsBeginImageContextWithOptions(self.frame.size, self.isOpaque, UIScreen.main.scale)
        self.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
}

protocol IssueTracker
{
    var issueSender: IssueSender { get set }
    var optedForConsoleLogs : Bool { get }
    var optedForExceptionLogs : Bool { get }
    var optedForScreenShot : Bool { get }
    
    func send(completion: (( _ completion: Bool, _ error: Error?) -> Void)? )
}

// MARK: SAIssueTracker

class SAIssueTracker : IssueTracker
{
    private var consoleLogsFilePath: String?
    private var exceptionLogsFilePath: String?

    var issueSender: IssueSender

    private var consoleLogs: Bool
    private var exceptionLogs: Bool
    private var needScreenShot: Bool
    
    fileprivate var _consoleLogFilePointer: UnsafeMutablePointer<FILE>?
    fileprivate var _exceptionsLogFilePointer: UnsafeMutablePointer<FILE>?
    
    public init(issueSender: IssueSender, consoleLogs: Bool , exceptionLogs: Bool, screenShot: Bool)
    {
        self.issueSender = issueSender
        self.consoleLogs = consoleLogs
        self.exceptionLogs = exceptionLogs
        self.needScreenShot = screenShot
        
        consoleLogsFilePath = customConsoleLogsFilePath()
        exceptionLogsFilePath = customExceptionLogsFilePath()
        
        self.issueSender.consoleLogsFilePath = consoleLogsFilePath
        self.issueSender.exceptionLogsFilePath = exceptionLogsFilePath
        self.issueSender.screenShotFilePath = customScreenShotFilePath()
        
        if amIAttachedToDebugger()
        {
            //so as to continue to log on developer's Xcode console
           return
        }
        
        weak var weakSelf = self
        if needToSendLogFiles()
        {
            let strongSelf = weakSelf
            send(completion:
            { (completed, error) in
                
                if (completed)
                {
                    /**
                     clear files so that same files don't get send again
                     **/
                    strongSelf?.clearFile(path: (strongSelf?.consoleLogsFilePath!)!)
                    strongSelf?.clearFile(path: (strongSelf?
                        .exceptionLogsFilePath!)!)
                }
            })
        }
        
        if optedForConsoleLogs
        {
            saveConsoleLogsInFile(path: consoleLogsFilePath!)
        }
        if optedForExceptionLogs
        {
            saveExceptionLogsInFile(path: exceptionLogsFilePath!)
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
    
    var optedForScreenShot: Bool
    {
        return needScreenShot
    }
    
    func sendLogsOnTakingScreenShot()
    {
        weak var weakSelf = self
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationUserDidTakeScreenshot, object: nil, queue: nil)
        { (notification) in
            
            let strongSelf = weakSelf
            strongSelf?.send(completion: nil)
        }
    }
    
    @objc func send(completion:  ((Bool, Error?) -> Void)?)
    {
        guard ( checkIfConsoleFileHasData() == true || checkIfExceptionFileHasData() == true ||
            (optedForScreenShot && checkIfScreenShotFileHasData()) == true ) else
        {
            return
        }
        
        if optedForScreenShot
        {
            captureScreenShot()
        }
        self.issueSender.sendLogs
        { (completed, error) in
            
            guard (completion != nil) else
            {
                return
            }
            completion!(completed,error)
        }
    }
    
    deinit
    {
        NotificationCenter.default.removeObserver(self,name: nil, object: nil)
    }
}

// MARK: SAIssueTracker Methods

private extension SAIssueTracker
{
    enum SAIssueTracker
    {
        static let consoleLogFileName = "console.log"
        static let exceptionsLogFileName = "exceptions.log"
        static let screenShotFileName = "screenShot.png"
    }
    
    func saveConsoleLogsInFile(path: String)
    {
        _consoleLogFilePointer = freopen(path.cString(using: String.Encoding.ascii)!, "w", stdout)
        setvbuf(_consoleLogFilePointer, nil, _IONBF, 0)
    }
    
    func saveExceptionLogsInFile(path: String)
    {
        _exceptionsLogFilePointer = freopen(path.cString(using: String.Encoding.ascii)!, "w", stderr)
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
    
    func needToSendLogFiles() -> Bool
    {
        return checkIfExceptionFileHasData()
    }
    
    func checkIfExceptionFileHasData() -> Bool
    {
        return !(FileManager.checkIfFileIsEmpty(path: customExceptionLogsFilePath()))
    }
    
    func checkIfConsoleFileHasData() -> Bool
    {
        return !(FileManager.checkIfFileIsEmpty(path: customConsoleLogsFilePath()))
    }
    
    func checkIfScreenShotFileHasData() -> Bool
    {
        return !(FileManager.checkIfFileIsEmpty(path: customScreenShotFilePath()))
    }
    
    func clearFile(path: String)
    {
        let text = ""
        do
        {
            try text.write(toFile: path, atomically: false, encoding: String.Encoding.utf8)
        }
        catch
        {
            //
        }
    }
    
    func captureScreenShot()
    {
        let window: UIWindow! = UIApplication.shared.keyWindow
        let windowImage = window.capture()
        
        do
        {
            try UIImagePNGRepresentation(windowImage)?.write(to: URL(fileURLWithPath: self.customScreenShotFilePath()))
        }
        catch
        {
            //
        }
    }
    
    func customConsoleLogsFilePath() -> String
    {
        return documentDirectoryPathAppending(path: SAIssueTracker.consoleLogFileName)
    }
    
    func customExceptionLogsFilePath() -> String
    {
        return documentDirectoryPathAppending(path: SAIssueTracker.exceptionsLogFileName)
    }
    
    func customScreenShotFilePath() -> String
    {
        return documentDirectoryPathAppending(path: SAIssueTracker.screenShotFileName)
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
    fputs("Exception:\n \(exception)", __stderrp)
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
