//
//  MessageAllViewController.swift
//  ChatChat
//
//  Created by Ruben Mayer on 6/21/16.
//  Copyright © 2016 Razeware LLC. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import Firebase
import FirebaseDatabase

class MessageAllViewController: ChatViewController {

    
    override func viewDidLoad() {
        senderId = "sendToAll"
        firebaseContainerRefferenceName = "MessageAllData"
        displayImageSegueIdentifier = "displayImageFromMessageAll"
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
 

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
