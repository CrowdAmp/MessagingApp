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
//import FirebaseMessaging
import Fabric
import TwitterKit
import Crashlytics
import FirebaseDatabase
import Appsee
import FBSDKCoreKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let dm = DataManager.sharedInstance
    let defaults = UserDefaults()
    
    
    override init() {
        //Firebase.defaultConfig().persistenceEnabled = true
    }
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        Appsee.start("129760c880774834b9cd9b769dc35f7c")
        Fabric.with([Twitter.self, Crashlytics.self])
        FIRApp.configure()
        FIRDatabase.database().persistenceEnabled = true
        FIRMessaging.messaging().connect { (error) in
            if (error != nil) {
                print("Unable to connect with FCM. \(error)")
            } else {
                print("Connected to FCM.")
            }
        }
        dm.launchOptions = launchOptions as [NSObject : AnyObject]?
        
        //set initial VC if logged in
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        if ((Twitter.sharedInstance().sessionStore.session()?.userID) != nil && (!dm.isUser && (defaults.object(forKey: "influencerId") != nil) || (dm.isUser && defaults.object(forKey: "userId") != nil))) {
            if dm.isUser {
                dm.userId = defaults.object(forKey: "userId") as! String
                let initialVC: UINavigationController = mainStoryboard.instantiateViewController(withIdentifier: "initialVCForUser") as! UINavigationController
                self.window?.rootViewController = initialVC
                
            } else {
                dm.influencerId = "morggkatherinee"//defaults.objectForKey("influencerId") as! String
                let initialVC: UINavigationController = mainStoryboard.instantiateViewController(withIdentifier: "initialVCForInfluencer") as! UINavigationController
                self.window?.rootViewController = initialVC
            }
        } else {
            let initialVC: LoginViewController = mainStoryboard.instantiateViewController(withIdentifier: "initialVCForNewUser") as! LoginViewController
            self.window?.rootViewController = initialVC
            
        }
        
        return true
        
        
    }
    
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("didRegister")
    }
    
    
    func application(_ application: UIApplication,  notificationSettings: UIUserNotificationSettings) {
        print("Hooray! I'm registered!")
        FIRMessaging.messaging().subscribe(toTopic: "/topics/test")
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        func applicationDidEnterBackground(_ application: UIApplication) {
            FIRMessaging.messaging().disconnect()
            print("Disconnected from FCM.")
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // Print message ID.
        print("didReceive notification)")
        // print("Message ID: \(userInfo["gcm.message_id"]!)")
        
        // Print full message.
        print("%@", userInfo)
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        FBSDKAppEvents.activateApp()
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
}

