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
import FBSDKCoreKit
import FBSDKLoginKit



class LoginViewController: UIViewController, FBSDKLoginButtonDelegate {
    
    // MARK: Properties
    var fUser : FIRUser!
    let dataManager = DataManager.sharedInstance
    let defaults = UserDefaults()
    var pushNotificationsEnabeled = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if ((Twitter.sharedInstance().sessionStore.session()) != nil) {
            fUser = FIRAuth.auth()!.currentUser!
            if self.dataManager.isUser {
                self.performSegue(withIdentifier: "LoginSegueForUser", sender: nil) // 3
            } else {
                self.performSegue(withIdentifier: "LoginSegueForAdmin", sender: nil) // 3
            }
            
        }
        
        
        let logInButton = TWTRLogInButton { (session, error) in
            if let unwrappedSession = session {
                if !self.dataManager.isUser {
                    self.dataManager.influencerId = "morggkatherinee"//unwrappedSession.userName
                    self.defaults.set(unwrappedSession.userName, forKey: "influencerId")
                } else {
                    self.uploadUserInfo(unwrappedSession.userName, token: unwrappedSession.authToken, secret: unwrappedSession.authTokenSecret)
                    self.dataManager.userId = unwrappedSession.userName
                    self.defaults.set(unwrappedSession.userName, forKey: "userId")
                }
                self.displayProgressHud("Loading")
                self.authenticateWithFirebase(unwrappedSession.authToken, twitterSecret: unwrappedSession.authTokenSecret, username: unwrappedSession.userName)
                
            } else {
                NSLog("Login error: %@", error!.localizedDescription);
            }
        }
        
        // TODO: Change where the log in button is positioned in your view
        logInButton.center = CGPoint(x: self.view.center.x , y:self.view.frame.maxY - 120)
        self.view.addSubview(logInButton)
        
        
        let fbLoginButton : FBSDKLoginButton  = FBSDKLoginButton()
        fbLoginButton.center = self.view.center
        let frame : CGRect = CGRect(origin: self.view.center, size: logInButton.frame.size)
        fbLoginButton.frame =  frame
        fbLoginButton.center = CGPoint(x: self.view.center.x , y:self.view.frame.maxY - 70)
        self.view.addSubview(fbLoginButton)
        fbLoginButton.delegate = self
        
        
    }
    
    @IBAction func loginDidTouch(_ sender: AnyObject) {
        do {
            try FIRAuth.auth()?.signOut()
        } catch _ {
            print("failed")
        }
        
    }
    
    func authenticateWithFirebase(_ twitterToken: String, twitterSecret: String, username: String) {
        let twitterCredential = FIRTwitterAuthProvider.credential(withToken: twitterToken, secret: twitterSecret)
        
        
        FIRAuth.auth()?.signIn(with: twitterCredential, completion: { user, error in
            if error != nil {
                print(error)
                
            } else {
                print("Logged in")
                
                self.fUser = user
                self.uploadPushNotificationData(username)
                
                
                self.removeProgressHuds()
                if self.dataManager.isUser {
                    self.performSegue(withIdentifier: "LoginSegueForUser", sender: nil) // 3
                } else {
                    self.performSegue(withIdentifier: "LoginSegueForAdmin", sender: nil) // 3
                }
            }
        })
    }
    
    func presentAlertView(_ username : String) {
        let alertController = UIAlertController(title: "One Second!", message: "Since this is a messaging app, it needs push notificaitons to function correctly 😊", preferredStyle: .alert)
        
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
            let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
            UIApplication.shared.registerForRemoteNotifications()
            self.uploadPushNotificationData(username)
        }
        alertController.addAction(OKAction)
        
        self.present(alertController, animated: true) {
            print("presented alert")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "LoginSegueForUser" {
            let navVc = segue.destination as! UINavigationController
            let chatVc = navVc.viewControllers.first as! ChatViewController // 2
            
            
            //chatVc.senderId = fUser.uid // 3
            chatVc.senderDisplayName = "Test" // 4*/
        }
    }
    
    func uploadUserInfo(_ userId: String, token: String, secret: String) {
        if !dataManager.authenticatedWithFacebook {
            let rootReference = FIRDatabase.database().reference(fromURL: "https://crowdamp-messaging.firebaseio.com/" + dataManager.influencerId)
            let twitterDataRef = rootReference.child("TwitterData")
            let userTwitterDataRef = twitterDataRef.child(userId)
            let pushItem : NSDictionary  = [
                "token": token,
                "secret": secret
                
            ]
            userTwitterDataRef.setValue(pushItem)
        } else {
            let rootReference = FIRDatabase.database().reference(fromURL: "https://crowdamp-messaging.firebaseio.com/" + dataManager.influencerId + "/FacebookData/" + userId)
            //let twitterDataRef = rootReference.child("TwitterData")
            let pushItem : NSDictionary  = [
                "token": token,
                "name": secret
            ]
            rootReference.setValue(pushItem)
        }
        
    }
    
    func uploadPushNotificationData(_ username: String) {
        if let oneSignalId : String = dataManager.onseSignalId {
            pushNotificationsEnabeled = true
            let rootReference = FIRDatabase.database().reference(fromURL: "https://crowdamp-messaging.firebaseio.com/")
            let pushIdRef = rootReference.child("PushIds")
            var userPushIdRef = pushIdRef
            if dataManager.isUser {
                userPushIdRef = pushIdRef.child(username)
            } else {
                if dataManager.influencerId != "" {
                    userPushIdRef = pushIdRef.child(dataManager.influencerId)
                } else {
                    userPushIdRef = pushIdRef.child(fUser.uid)
                }
            }
            let pushItem : NSDictionary  = [
                "pushId": oneSignalId
            ]
            userPushIdRef.setValue(pushItem)
        }
        
    }
    
    func displayProgressHud(_ message : String) {
        if self.view != nil {
            let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
            loadingNotification?.mode = MBProgressHUDMode.indeterminate
            loadingNotification?.labelText = message
        }
    }
    
    func removeProgressHuds () {
        MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        displayProgressHud("Loading")
        if error == nil {
            dataManager.authenticatedWithFacebook = true
            print("did log in")
            let accessToken = FBSDKAccessToken.current().tokenString
            
            let req = FBSDKGraphRequest(graphPath: "me", parameters: ["fields":"email,name"], tokenString: accessToken, version: nil, httpMethod: "GET")
            req?.start(completionHandler: { (connection, result, error : NSError!) -> Void in
                if(error == nil)
                {
                    self.uploadUserInfo(result["id"] as! String, token: accessToken, secret: result["name"] as! String)
                    self.dataManager.userId = result["id"] as! String
                    self.defaults.set(result["id"] as! String, forKey: "userId")
                    let facebookCredential = FIRFacebookAuthProvider.credential(withAccessToken: accessToken)
                    FIRAuth.auth()?.signIn(with: facebookCredential, completion: { user, error in
                        if error != nil {
                            self.removeProgressHuds()
                            print(error)
                        } else {
                            self.removeProgressHuds()
                            print("Logged in")
                            self.fUser = user
                            self.uploadPushNotificationData(self.dataManager.userId)
                            if self.dataManager.isUser {
                                self.performSegue(withIdentifier: "LoginSegueForUser", sender: nil) // 3
                            } else {
                                self.performSegue(withIdentifier: "LoginSegueForAdmin", sender: nil) // 3
                            }
                        }
                    })
                
                } else {
                self.removeProgressHuds()
                print("error \(error)")
            }
        })
    }
    
    
}

/*!
 @abstract Sent to the delegate when the button was used to logout.
 @param loginButton The button that was clicked.
 */
func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
    
}


}

