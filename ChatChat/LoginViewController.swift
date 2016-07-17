/*
* Copyright (c) 2015 Razeware LLC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseAuth
import Fabric
import TwitterKit
import MBProgressHUD



class LoginViewController: UIViewController {
    
    // MARK: Properties
    var fUser : FIRUser!
    let dataManager = DataManager.sharedInstance
    let defaults = NSUserDefaults()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if ((Twitter.sharedInstance().sessionStore.session()) != nil) {
            fUser = FIRAuth.auth()!.currentUser!
            if self.dataManager.isUser {
                self.performSegueWithIdentifier("LoginSegueForUser", sender: nil) // 3
            } else {
                self.performSegueWithIdentifier("LoginSegueForAdmin", sender: nil) // 3
            }

        }
    

        let logInButton = TWTRLogInButton { (session, error) in
            if let unwrappedSession = session {
                self.dataManager.influencerId = "morggkatherinee"//unwrappedSession.userName
                self.defaults.setObject(unwrappedSession.userName, forKey: "influencerId")
                self.displayProgressHud("Loading")
                self.authenticateWithFirebase(unwrappedSession.authToken, twitterSecret: unwrappedSession.authTokenSecret)

                
                } else {
                NSLog("Login error: %@", error!.localizedDescription);
            }
        }
        
        // TODO: Change where the log in button is positioned in your view
        logInButton.center = CGPoint(x: self.view.center.x , y:self.view.frame.maxY - 100)
        self.view.addSubview(logInButton)

    
    }


  @IBAction func loginDidTouch(sender: AnyObject) {
    do {
        try FIRAuth.auth()?.signOut()
    } catch _ {
        print("failed")
    }
    
  }
   
    func authenticateWithFirebase(twitterToken: String, twitterSecret: String) {
        let twitterCredential = FIRTwitterAuthProvider.credentialWithToken(twitterToken, secret: twitterSecret)
        
        
        FIRAuth.auth()?.signInWithCredential(twitterCredential, completion: { user, error in
            if error != nil {
                print(error)
                
            } else {
                print("Logged in")
                
                self.fUser = user
                self.uploadPushNotificationData()

                
                self.removeProgressHuds()
                if self.dataManager.isUser {
                    self.performSegueWithIdentifier("LoginSegueForUser", sender: nil) // 3
                } else {
                    self.performSegueWithIdentifier("LoginSegueForAdmin", sender: nil) // 3
                }
            }
        })
    }
    
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        if segue.identifier == "LoginSegueForUser" {
            let navVc = segue.destinationViewController as! UINavigationController
            let chatVc = navVc.viewControllers.first as! ChatViewController // 2
            
           
            //chatVc.senderId = fUser.uid // 3
            //chatVc.senderDisplayName = "Test" // 4*/
        }
    }
    func uploadPushNotificationData() {
        if let oneSignalId : String = dataManager.onseSignalId {
            let rootReference = FIRDatabase.database().referenceFromURL("https://crowdamp-messaging.firebaseio.com/")
            let pushIdRef = rootReference.child("PushIds")
            var userPushIdRef = pushIdRef
            if dataManager.influencerId != "" {
                userPushIdRef = pushIdRef.child(dataManager.influencerId)
            } else {
                userPushIdRef = pushIdRef.child(fUser.uid)
            }
            let pushItem : NSDictionary  = [
                "pushId": oneSignalId
            ]
            userPushIdRef.setValue(pushItem)
        }
        
    }

    func displayProgressHud(message : String) {
        if self.view != nil {
            let loadingNotification = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
            loadingNotification.mode = MBProgressHUDMode.Indeterminate
            loadingNotification.labelText = message
        }
    }
    
    func removeProgressHuds () {
        if self.view.window != nil {
            MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
        }
        
    }

}

