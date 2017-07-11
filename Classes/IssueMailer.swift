//
//  IssueMailer.swift
//  SAIssueTracker
//
//  Created by Sandeep Aggarwal on 10/07/17.
//  Copyright © 2017 Sandeep Aggarwal. All rights reserved.
//

import Foundation


class IssueMailer
{
    var senderEmail: String
    var senderPassword: String
    var toEmail: String
    var subject: String?
    var relayHost: String?
    var consoleLogsFilePath: String?
    var exceptionLogsFilePath: String?
    
    init(senderEmail: String, senderPassword: String, toEmail: String)
    {
        self.senderEmail = senderEmail
        self.senderPassword = senderPassword
        self.toEmail = toEmail
    }
}

extension IssueMailer: IssueSender
{
    func sendLogs(completion: @escaping (Bool, Error?) -> Void)
    {
        guard (isValid(email: senderEmail) && isValid(email: toEmail)) else
        {
            return
        }
        
        guard (senderPassword.characters.count > 0) else
        {
            return
        }
        
        guard (consoleLogsFilePath != nil || exceptionLogsFilePath != nil) else
        {
            return
        }
        
        let smtpSession = MCOSMTPSession()
        smtpSession.hostname = self.relayHost ?? "smtp.gmail.com"
        smtpSession.username = self.senderEmail
        smtpSession.password = self.senderPassword
        smtpSession.port = 465
        smtpSession.authType = MCOAuthType.saslPlain
        smtpSession.connectionType = MCOConnectionType.TLS
        
        let builder = MCOMessageBuilder()
        builder.header.to = [MCOAddress(mailbox: self.toEmail)]
        builder.header.from = MCOAddress(mailbox: self.senderEmail)
        builder.header.subject = self.subject ?? "SA Issue Tracker"
        
        let attachment1 = MCOAttachment(contentsOfFile: consoleLogsFilePath)
        let attachment2 = MCOAttachment(contentsOfFile: exceptionLogsFilePath)
        
        if (attachment1?.data != nil)
        {
           builder.addAttachment(attachment1)
        }
        
        if (attachment2?.data != nil)
        {
           builder.addAttachment(attachment2)
        }
        
        let rfc822Data = builder.data()
        let sendOperation = smtpSession.sendOperation(with: rfc822Data!)
        sendOperation?.start
        { (error) -> Void in
            if (error != nil)
            {
                completion(false, error)
                NSLog("Error sending email: \(String(describing: error))")
            }
            else
            {
                completion(true, nil)
                NSLog("Successfully sent email!")
            }
        }
    }
}

extension IssueMailer
{
    func isValid(email: String?) -> Bool
    {
        guard (email?.characters.count)! > 0 else
        {
            return false
        }
        
        let emailRegEx = "(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"+"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"+"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"+"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"+"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"+"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"+"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])"
        
        let emailTest = NSPredicate(format:"SELF MATCHES[c] %@", emailRegEx)
        return emailTest.evaluate(with: email)
    }
}
