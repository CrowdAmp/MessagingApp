//
//  HomeMenuViewController.swift
//  ChatChat
//
//  Created by Ruben Mayer on 6/21/16.
//  Copyright © 2016 Razeware LLC. All rights reserved.
//

import UIKit
import TwitterKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseAuth

class HomeMenuViewController: UIViewController {

    @IBOutlet weak var messagesAmmountLabel: UILabel!
    @IBOutlet weak var followersAmmountLabel: UILabel!
    @IBOutlet weak var welcomeLabel: UILabel!
    var dataManager = DataManager.sharedInstance
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    override func viewDidLoad() {
        newMessagesLabel.isHidden = true
        if dataManager.influencerId.characters.count > 12 {
            welcomeLabel.text = "Welcome"
        } else {
            welcomeLabel.text = "Welcome, " + dataManager.influencerId
        }
        super.viewDidLoad()
        uploadPushNotificationData()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
        
        var url = URL(string: "https://peaceful-mountain-72739.herokuapp.com/getTotalMessages/" + dataManager.influencerId)
        let getTotalMessages = URLSession.shared.dataTask(with: url!, completionHandler: {(data, response, error) in
            if data != nil {
                let totalMessages : String? = String(data: data!, encoding: String.Encoding.utf8)
                if totalMessages != nil && Int(totalMessages!) != nil {
                    DispatchQueue.main.async {
                        self.messagesAmmountLabel.text = totalMessages
                    }
                    print("totalMessages: \(totalMessages)")
                }
                    
            }
        }) 
        getTotalMessages.resume()
        
        url = URL(string: "https://peaceful-mountain-72739.herokuapp.com/getTotalFans/" + dataManager.influencerId)
        let getTotalFans = URLSession.shared.dataTask(with: url!, completionHandler: {(data, response, error) in
            if data != nil {
                let totalFans : String? = String(data: data!, encoding: String.Encoding.utf8)
                if totalFans != nil && Int(totalFans!) != nil {
                    DispatchQueue.main.async {
                        self.followersAmmountLabel.text = totalFans
                    }
                    print("totalFans: \(totalFans)")
                }
            }
        }) 
        getTotalFans.resume()
        
        url = URL(string: "https://peaceful-mountain-72739.herokuapp.com/getNewMessages/" + dataManager.influencerId)
        let getNewMessages = URLSession.shared.dataTask(with: url!, completionHandler: {(data, response, error) in
            if data != nil {
                let newMessages : String? = String(data: data!, encoding: String.Encoding.utf8)
                if newMessages != nil && Int(newMessages!) != nil {
                    DispatchQueue.main.async {
                        if newMessages == "0" {
                            self.newMessagesLabel.isHidden = true
                        } else {
                            self.newMessagesLabel.isHidden = false
                            self.newMessagesLabel.text = newMessages
                        }
                    }
                    
                    print("newMessages: \(newMessages)")
                } else {
                    DispatchQueue.main.async {
                        self.newMessagesLabel.isHidden = true
                    }
                }
            }
        }) 
        getNewMessages.resume()
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        let backItem = UIBarButtonItem()
        backItem.title = ""
        navigationItem.backBarButtonItem = backItem
        if segue.identifier == "viewAllMessagesSegue" {
            let messageTableVc = segue.destination as! MessageTableViewController
            messageTableVc.firebaseStoragePath = "IndividualMessageData"
            messageTableVc.vCTitle = "All Messages"
        
        } else if segue.identifier == "replyToGroupedMessagesSegue" {
            let messageTableVc = segue.destination as! MessageTableViewController
            messageTableVc.firebaseStoragePath = "GroupedMessageData"
            messageTableVc.vCTitle = "Grouped Messages"
        } else if let chatVc = segue.destination as? MessageAllViewController {
            chatVc.senderDisplayName = "Test"
        }

    }
    
    
    @IBOutlet weak var replyToGroupedMessagesButton: UIButton!

    @IBOutlet weak var sendMessageToAllButton: UIButton!
    
     @IBOutlet weak var viewAllMessagesButton: UIButton!
    
    @IBOutlet weak var newMessagesLabel: UILabel!
    override var shouldAutorotate : Bool {
        if (UIDevice.current.orientation == UIDeviceOrientation.portrait ||
            UIDevice.current.orientation == UIDeviceOrientation.portraitUpsideDown ||
            UIDevice.current.orientation == UIDeviceOrientation.unknown) {
            return true
        }
        else {
            return false
        }
    }
    
     internal override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return [UIInterfaceOrientationMask.portrait ,UIInterfaceOrientationMask.portraitUpsideDown]
    }

    
    // MARK: - Navigation

    
    
    
    @IBAction func didPressLogOutButton(_ sender: AnyObject) {
        logOut()
        performSegue(withIdentifier: "influencerDidLogOut", sender: self)
        
    }
    func logOut() {
        let store = Twitter.sharedInstance().sessionStore
        
        if let userID = store.session()?.userID {
            store.logOutUserID(userID)
        }
        do {
            try FIRAuth.auth()?.signOut()
        } catch _ {
            print("failed")
        }
    }

    func uploadPushNotificationData() {
        if let oneSignalId : String = dataManager.onseSignalId {
            let rootReference = FIRDatabase.database().reference(fromURL: "https://crowdamp-messaging.firebaseio.com/")
            let pushIdRef = rootReference.child("PushIds")
            var userPushIdRef = pushIdRef
            if dataManager.influencerId != "" {
                userPushIdRef = pushIdRef.child(dataManager.influencerId)
            }
            let pushItem : NSDictionary  = [
                "pushId": oneSignalId
            ]
            userPushIdRef.setValue(pushItem)
        }
        
    }
}

extension UINavigationController {
    open override var shouldAutorotate : Bool {
        return visibleViewController!.shouldAutorotate
    }
    
    open override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return (visibleViewController?.supportedInterfaceOrientations)!
    }
}
