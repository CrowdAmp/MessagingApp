//
//  HomeMenuViewController.swift
//  ChatChat
//
//  Created by Ruben Mayer on 6/21/16.
//  Copyright © 2016 Razeware LLC. All rights reserved.
//

import UIKit

class HomeMenuViewController: UIViewController {

    @IBOutlet weak var messagesAmmountLabel: UILabel!
    @IBOutlet weak var followersAmmountLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBarHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        newMessagesLabel.clipsToBounds = true
        newMessagesLabel.layer.cornerRadius = 15
        
        replyToGroupedMessagesButton.clipsToBounds = true
        replyToGroupedMessagesButton.layer.cornerRadius = 8.0
        sendMessageToAllButton.clipsToBounds = true
        sendMessageToAllButton.layer.cornerRadius = 8.0
        viewAllMessagesButton.clipsToBounds = true
        viewAllMessagesButton.layer.cornerRadius = 8.0
        followersAmmountLabel.sizeToFit()
        messagesAmmountLabel.sizeToFit()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        let backItem = UIBarButtonItem()
        backItem.title = ""
        navigationItem.backBarButtonItem = backItem
        if segue.identifier == "viewAllMessagesSegue" {
            let messageTableVc = segue.destinationViewController as! MessageTableViewController
            messageTableVc.firebaseStoragePath = "IndividualMessageData"
            messageTableVc.vCTitle = "All Messages"
        
        } else if segue.identifier == "replyToGroupedMessagesSegue" {
            let messageTableVc = segue.destinationViewController as! MessageTableViewController
            messageTableVc.firebaseStoragePath = "GroupedMessageData"
            messageTableVc.vCTitle = "Grouped Messages"
        }

    }
    
    
    @IBOutlet weak var replyToGroupedMessagesButton: UIButton!

    @IBOutlet weak var sendMessageToAllButton: UIButton!
    
     @IBOutlet weak var viewAllMessagesButton: UIButton!
    
    @IBOutlet weak var newMessagesLabel: UILabel!
    override func shouldAutorotate() -> Bool {
        if (UIDevice.currentDevice().orientation == UIDeviceOrientation.Portrait ||
            UIDevice.currentDevice().orientation == UIDeviceOrientation.PortraitUpsideDown ||
            UIDevice.currentDevice().orientation == UIDeviceOrientation.Unknown) {
            return true
        }
        else {
            return false
        }
    }
    
     internal override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [UIInterfaceOrientationMask.Portrait ,UIInterfaceOrientationMask.PortraitUpsideDown]
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

extension UINavigationController {
    public override func shouldAutorotate() -> Bool {
        return visibleViewController!.shouldAutorotate()
    }
    
    public override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return (visibleViewController?.supportedInterfaceOrientations())!
    }
}
