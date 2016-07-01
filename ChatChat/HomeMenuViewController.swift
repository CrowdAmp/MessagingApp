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
    @IBOutlet weak var welcomeLabel: UILabel!
    var dataManager = DataManager.sharedInstance
    
    override func viewDidLoad() {
        if dataManager.influencerId.characters.count > 12 {
            welcomeLabel.text = "Welcome"
        } else {
            welcomeLabel.text = "Welcome, " + dataManager.influencerId
        }
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBarHidden = true
        
        var url = NSURL(string: "https://peaceful-mountain-72739.herokuapp.com/getTotalMessages/" + dataManager.influencerId)
        let getTotalMessages = NSURLSession.sharedSession().dataTaskWithURL(url!) {(data, response, error) in
            if data != nil {
                let totalMessages : String? = String(data: data!, encoding: NSUTF8StringEncoding)
                if totalMessages != nil && Int(totalMessages!) != nil {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.messagesAmmountLabel.text = totalMessages
                    }
                    print("totalMessages: \(totalMessages)")
                }
                    
            }
        }
        getTotalMessages.resume()
        
        url = NSURL(string: "https://peaceful-mountain-72739.herokuapp.com/getTotalFans/" + dataManager.influencerId)
        let getTotalFans = NSURLSession.sharedSession().dataTaskWithURL(url!) {(data, response, error) in
            if data != nil {
                let totalFans : String? = String(data: data!, encoding: NSUTF8StringEncoding)
                if totalFans != nil && Int(totalFans!) != nil {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.followersAmmountLabel.text = totalFans
                    }
                    print("totalFans: \(totalFans)")
                }
            }
        }
        getTotalFans.resume()
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
