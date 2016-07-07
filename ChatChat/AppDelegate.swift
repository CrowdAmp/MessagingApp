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
import FirebaseMessaging
import Fabric
import TwitterKit
import Crashlytics


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let dm = DataManager.sharedInstance
    let defaults = NSUserDefaults()


  override init() {
     //Firebase.defaultConfig().persistenceEnabled = true
  }

  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
   
    
    Fabric.with([Twitter.self, Crashlytics.self])
    FIRApp.configure()
    FIRMessaging.messaging().connectWithCompletion { (error) in
        if (error != nil) {
            print("Unable to connect with FCM. \(error)")
        } else {
            print("Connected to FCM.")
        }
    }
    let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
    UIApplication.sharedApplication().registerUserNotificationSettings(settings)
    UIApplication.sharedApplication().registerForRemoteNotifications()
    
    let oneSignal : OneSignal = OneSignal(launchOptions: launchOptions, appId: "3fe58d49-2025-4653-912f-8067adbecd7f", handleNotification: nil)
    
    OneSignal.defaultClient().enableInAppAlertNotification(true)
    
    oneSignal.IdsAvailable({ (userId, pushToken) in
        NSLog("UserId:%@", userId)
        if (pushToken != nil) {
            NSLog("pushToken:%@", pushToken)//051ff80dd53fe2347172dc36221521638e9838e494ca242ba423fd5528366386
            self.dm.oneSignal = oneSignal
            self.dm.onseSignalId = userId
            NSLog("userID:%@", userId)//8e70c1e0-d3ce-43a7-8a69-79477762bf33
        }
    })
    
    //set initial VC if logged in 
    
    self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
    let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
    if ((Twitter.sharedInstance().sessionStore.session()?.userID) != nil && defaults.objectForKey("influencerId") != nil) {
        if dm.isUser {
            let initialVC: UINavigationController = mainStoryboard.instantiateViewControllerWithIdentifier("initialVCForUser") as! UINavigationController
            self.window?.rootViewController = initialVC

        } else {
            dm.influencerId = defaults.objectForKey("influencerId") as! String
            let initialVC: UINavigationController = mainStoryboard.instantiateViewControllerWithIdentifier("initialVCForInfluencer") as! UINavigationController
            self.window?.rootViewController = initialVC
        }
    } else {
        let initialVC: LoginViewController = mainStoryboard.instantiateViewControllerWithIdentifier("initialVCForNewUser") as! LoginViewController
        self.window?.rootViewController = initialVC

    }

    return true

    
    }

    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        print("didRegister")
    }
    
    
    func application(application: UIApplication,  notificationSettings: UIUserNotificationSettings) {
        print("Hooray! I'm registered!")
        FIRMessaging.messaging().subscribeToTopic("/topics/test")
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        func applicationDidEnterBackground(application: UIApplication) {
            FIRMessaging.messaging().disconnect()
            print("Disconnected from FCM.")
        }
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject],
                     fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // Print message ID.
        print("didReceive notification)")
       // print("Message ID: \(userInfo["gcm.message_id"]!)")
        
        // Print full message.
        print("%@", userInfo)
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

