//
//  ViewController.swift
//  SAIssueTracker
//
//  Created by Sandeep Aggarwal on 08/07/17.
//  Copyright © 2017 Sandeep Aggarwal. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad()
    {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        
      let tracker =  SAIssueTracker(issueSender: IssueMailer(senderEmail: "", senderPassword: "", toEmail: ""), consoleLogs: true, exceptionLogs: true)
        print("huhu 1");
        print("huhu 2");
        print("huhu 3");
        print("huhu 4");
        tracker.send()
        
//        var a = [""]
//        print(a[2])
        
//        var a: NSArray = [""]
//        print(a[2])
        
//        let number: Int? = nil
//        let val = number!
        
       // preconditionFailure()
        
       // [0][1]
        
      //  fatalError()
        
    }




}

