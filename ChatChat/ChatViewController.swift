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
import JSQMessagesViewController
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import NMPopUpViewSwift
import MBProgressHUD
import Haneke
import TwitterKit
//import SVPullToRefresh


class ChatViewController: JSQMessagesViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var outgoingBubbleImageView: JSQMessagesBubbleImage!
    var incomingBubbleImageView: JSQMessagesBubbleImage!
    let rootReference = FIRDatabase.database().referenceFromURL("https://crowdamp-messaging.firebaseio.com/")
    var messageReference: FIRDatabaseReference!
    var referenceName = ""
    let dataManager = DataManager.sharedInstance
    var imagesRef : FIRStorageReference!
    var videosRef : FIRStorageReference!
    var displayedMedia = Set<String>()
    var imageToDisplay : UIImage!
    let defaults = NSUserDefaults()
    var messageKeyArray : [String] = []
    let cacheLength = 15
    let refreshControl = UIRefreshControl()
    let messagesDisplayed : UInt = 15
    let messagesLoaded : UInt = 10
    var pushId : String!
    var messageCount = 0
    var displayImageSegueIdentifier = "DisplayImage"
    var firebaseContainerRefferenceName = "IndividualMessageData"
    var failedDeliveryIndices = []
    var indexWithDeliveredAnnotation = 0
    var isVisible = false
    let cache = Shared.dataCache
    var pushNotificationsEnabeled = false
    var messages = [JSQMessage]() {
        didSet{
            if messages.count > 0 {
                if messages.count == 3 {
                    let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
                    if !pushNotificationsEnabeled {
                        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
                        UIApplication.sharedApplication().registerForRemoteNotifications()
                        let oneSignal : OneSignal = OneSignal(launchOptions: self.dataManager.launchOptions, appId: "3fe58d49-2025-4653-912f-8067adbecd7f", handleNotification: nil)
                        OneSignal.defaultClient().enableInAppAlertNotification(false)
                        oneSignal.IdsAvailable({ (userId, pushToken) in
                            NSLog("UserId:%@", userId)
                            if (pushToken != nil) {
                                NSLog("pushToken:%@", pushToken)//051ff80dd53fe2347172dc36221521638e9838e494ca242ba423fd5528366386
                                self.dataManager.oneSignal = oneSignal
                                self.dataManager.onseSignalId = userId
                                NSLog("userID:%@", userId)//8e70c1e0-d3ce-43a7-8a69-79477762bf33
                                self.uploadPushNotificationData(self.dataManager.userId)
                            }
                        })
                    }
                }
            }
        }
    }




    @IBOutlet weak var imageBackgroundView: UIView!

    @IBAction func didPressLogOutButton(sender: AnyObject) {
        self.performSegueWithIdentifier("userDidLogOut", sender: self)
        logOut()
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
    
    
    @IBOutlet weak var logOutButton: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        if senderDisplayName == nil {
            senderDisplayName = ""
        }
        super.viewDidLoad()
        
        let store = Twitter.sharedInstance().sessionStore
        
        if let userID = store.session()?.userID {
            let client = TWTRAPIClient()
            client.loadUserWithID(userID) { (user, error) -> Void in
                if let user = user {
                    self.uploadUserInfo(user.screenName, token: store.session()!.authToken, secret: store.session()!.authTokenSecret)
                }
            }
        }
        
        if dataManager.influencerId == "belieberbot" {
            self.title = "Bieber Bot"
        }
        if dataManager.isUser {
            senderId = dataManager.userId
        } else {
            if senderId.characters.count == 12 && senderId[0] == "+"{
                title = "(" + senderId[2...4] + ") " + senderId[5...7] + "-" + senderId[8...11]
            } else if senderId == "sendToAll" {
                title = "Message All Fans"
            } else {
                title = senderId
            }
            self.navigationItem.rightBarButtonItem = nil
            logOutButton = nil
        }
        firebaseContainerRefferenceName = dataManager.influencerId + "/" + firebaseContainerRefferenceName
        downloadNotificationId()
        automaticallyScrollsToMostRecentMessage = false
        referenceName = senderId
        setupBubbles()
        // No avatars
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSizeZero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero
        let messagesParentRef = rootReference.child(firebaseContainerRefferenceName)
        messageReference = messagesParentRef.child(referenceName)
        
        /*  cache.fetch(key: "messages" + senderId).onSuccess { msgs in
         self.messages = NSKeyedUnarchiver.unarchiveObjectWithData(msgs) as! [JSQMessage]
         self.cache.fetch(key: "messageKeyArray" + self.senderId).onSuccess { messageKeyArr in
         self.messageKeyArray = NSKeyedUnarchiver.unarchiveObjectWithData(messageKeyArr) as! [String]
         dispatch_async(dispatch_get_main_queue()) {
         self.finishReceivingMessage()
         self.observeMessages(self.messagesDisplayed)
         
         }
         }
         }.onFailure { _ in
         self.observeMessages(self.messagesDisplayed)
         }
         */
        self.observeMessages(self.messagesDisplayed)
        
        
        
        //  if let msgs = defaults.objectForKey("messages" + senderId) as? NSData {
        //    messages = NSKeyedUnarchiver.unarchiveObjectWithData(msgs) as! [JSQMessage]
        //}
        //if let messageKeyArr = defaults.objectForKey("messageKeyArray" + senderId) as? [String]{
        //            messageKeyArray = messageKeyArr
        //       }
        //     finishReceivingMessage()
        self.navigationController?.navigationBarHidden = false
        
        refreshControl.addTarget(self, action: "loadMoreMessages", forControlEvents: UIControlEvents.ValueChanged)
        collectionView.addSubview(refreshControl) // no
        
        //        var i = 0
        //        for message in messages {
        //            i += 1
        //            if message.isMediaMessage {
        //               downloadMediaFromFirebase(messageKeyArray[i], type: "image", index: i, sentByUser: message.senderId != dataManager.influencerId)
        //            }
        //        }
    }
    
    //    func getMessageCount() {
    //        let ref = rootReference.child("MessagesCount/" + senderId)
    //        let query = ref.queryLimitedToLast(1)
    //        query.observeEventType(.ChildAdded) { (snapshot: FIRDataSnapshot!) in
    //            self.messageCount = snapshot.value! as! Int
    //        }
    //        query.observeEventType(.ChildChanged) { (snapshot: FIRDataSnapshot!) in
    //            self.messageCount = snapshot.value! as! Int
    //        }
    //    }
    //
    //    func updateMessageCount() {
    //
    //        let ref = rootReference.child("MessagesCount/" + senderId)
    //        messageCount += 1
    //        let countItem : NSDictionary = [
    //            "count": messageCount
    //        ]
    //        ref.setValue(countItem)
    //    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBarHidden = false
        isVisible = true
        addReadReceiptToMessageData()
        
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if messages.count == 0 {
            //displayProgressHud("Loading")
        }
    }
    
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        isVisible = false
        
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!,
                                 messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    private func setupBubbles() {
        let factory = JSQMessagesBubbleImageFactory()
        outgoingBubbleImageView = factory.outgoingMessagesBubbleImageWithColor(
            UIColor.jsq_messageBubbleBlueColor())
        incomingBubbleImageView = factory.incomingMessagesBubbleImageWithColor(
            UIColor.jsq_messageBubbleLightGrayColor())
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!,
                                 messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item] // 1
        if message.senderId == senderId { // 2
            return outgoingBubbleImageView
        } else { // 3
            return incomingBubbleImageView
        }
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!,
                                 avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    func addMessage(id: String, text: String, sentByUser: Bool, key: String, insertAtIndex: Int) {
        if !messageKeyArray.contains(key) {
            var message:JSQMessage!
            if (sentByUser && dataManager.isUser) || (!sentByUser && !dataManager.isUser ){
                message = JSQMessage(senderId: id, displayName: "", text: text)
            } else {
                message = JSQMessage(senderId: "notUser", displayName: "", text: text)
            }
            if insertAtIndex != -1 {
                messages.insert(message, atIndex: insertAtIndex)
                messageKeyArray.insert(key, atIndex: insertAtIndex)
                
            } else {
                messages.append(message)
                messageKeyArray.append(key)
            }
            //let data : NSData = NSKeyedArchiver.archivedDataWithRootObject(Array(messages.suffix(cacheLength)))
            //cache.set(value: data, key: "messages" + senderId)
            //defaults.setObject(data, forKey: "messages" + senderId)
            //cache.set(value: NSKeyedArchiver.archivedDataWithRootObject(Array(messageKeyArray.suffix(cacheLength))), key: "messageKeyArray" + senderId)
            //defaults.setObject(Array(messageKeyArray.suffix(cacheLength)), forKey: "messageKeyArray" + senderId)
            
            
        }
    }
    
    override func collectionView(collectionView: UICollectionView,
                                 cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath)
            as! JSQMessagesCollectionViewCell
        
        let message = messages[indexPath.item]
        
        if !message.isMediaMessage {
            if message.senderId == senderId {
                cell.textView!.textColor = UIColor.whiteColor()
            } else {
                cell.textView!.textColor = UIColor.blackColor()
            }
        }
        return cell
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAtIndexPath indexPath: NSIndexPath!) {
        let message = messages[indexPath.item]
        if message.isMediaMessage {
            let mediaItem = message.media
            if mediaItem.isKindOfClass(JSQPhotoMediaItem) {
                let photoItem = mediaItem as! JSQPhotoMediaItem
                if let image : UIImage = photoItem.image {
                    popupImage(image)
                }
            }
        }
    }
    
    func popupImage(image: UIImage) {
        imageToDisplay = image
        self.performSegueWithIdentifier(displayImageSegueIdentifier, sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let imageDisplayVc = segue.destinationViewController as? ImageDisplayViewController {
            imageDisplayVc.image = imageToDisplay
        }
    }
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!,
                                     senderDisplayName: String!, date: NSDate!) {
        
        finishSendingMessage()
        scrollToBottomAnimated(true)
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        let itemRef = messageReference.childByAutoId()//(String(messageCount))
        let messageItem = [
            "text": text,
            "senderId": senderId,
            "sentByUser": dataManager.isUser,
            "type": "text",
            "fileName": "",
            "hasBeenForwarded": false,
            "mediaDownloadUrl": ""
        ]
        addUnReadReceiptToMessageData()
        itemRef.setValue(messageItem, withCompletionBlock: { (error, refference) in
            
            if (error == nil) {
                self.messages.last?.deliveryStatus = "Delivered"
                self.collectionView.reloadData()
                
            } else {
                self.messages.last?.deliveryStatus = "Delivery Error"
                self.collectionView.reloadData()
            }
            
        })
        addTimestampToMessageData()
        itemRef.child("timestamp").setValue(FIRServerValue.timestamp())
        //sendPushNotificationToCounterpart(dataManager.influencerName + ": " + text)
    }
    
    private func observeMessages(totalMessages: UInt) {
        
        var messagesQuery = messageReference.queryLimitedToLast(totalMessages)
        if messageKeyArray.count > 0 {
            messagesQuery = messageReference.queryOrderedByKey().queryStartingAtValue(messageKeyArray[messageKeyArray.count - 1])
        }
        
        
        messagesQuery.observeEventType(.ChildAdded) { (snapshot: FIRDataSnapshot!) in
            let id = snapshot.value?["senderId"] as? String
            let text = snapshot.value?["text"] as? String
            let sentByUser = snapshot.value?["sentByUser"] as? Bool
            let type = snapshot.value!["type"] as? String
            let fileName = snapshot.value?["fileName"] as? String
            
            if id != nil && text != nil && sentByUser != nil && type != nil && fileName != nil {
                
                if type == "text" {
                    self.addMessage(id!, text: text!, sentByUser: sentByUser!, key: snapshot.key, insertAtIndex: -1)
                } else if type == "image" {
                    if !self.messageKeyArray.contains(snapshot.key) {
                        self.downloadMediaFromFirebase(fileName!, type: type!, index: self.messages.count, sentByUser: sentByUser!)
                        self.sendImageMessage(nil, shouldUploadToFirebase: false, title: fileName!, sentByUser: sentByUser!, messageKey: snapshot.key, insertAtIndex:  -1)
                    }
                }
                //}
            }
            self.finishReceivingMessage()
            self.scrollToBottomAnimated(true)
            self.addReadReceiptToMessageData()
        }
    }
    
    override func didPressAccessoryButton(sender: UIButton!) {
        
        self.scrollToBottomAnimated(true)
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .ActionSheet)
        
        let selectPhotoFromLibraryAction = UIAlertAction(title: "Select Photo From Library", style: .Default){ (action) in
            self.openPhotoLibrary()
        }
        alertController.addAction(selectPhotoFromLibraryAction)
        
        let sendNewPhotoAction = UIAlertAction(title: "Send New Photo", style: .Default) { (action) in
            self.openCamera()
        }
        alertController.addAction(sendNewPhotoAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
            print("didCancelAttachment")
        }
        
        alertController.addAction(cancelAction)
        
        self.presentViewController(alertController, animated: true) {
            // ...
        }
        
    }
    
    func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.Camera;
            imagePicker.allowsEditing = false
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
    }
    
    
    func openPhotoLibrary() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary;
            
            imagePicker.allowsEditing = false
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        print(image.size.width)
        let resizedImage = image.resizeWithWidth(400)
        self.dismissViewControllerAnimated(true, completion: nil);
        //imagePicked.image = image
        let fileName = "image/" + senderId + String.random() + ".jpg"
        sendImageMessage(resizedImage, shouldUploadToFirebase: true, title: fileName, sentByUser: dataManager.isUser, messageKey: nil, insertAtIndex: -1)
    }
    
    func sendImageMessage(image: UIImage?, shouldUploadToFirebase: Bool, title: String, sentByUser: Bool, messageKey: String?, insertAtIndex: Int) {
        if messageKey == nil || !messageKeyArray.contains(messageKey!) {
            if !displayedMedia.contains(title) {
                if shouldUploadToFirebase {
                    storeImageOnFirebase(image!, fileName: title, mediaType: "image")
                    displayedMedia.insert(title)
                }
                let media = JSQPhotoMediaItem(image: image)
                let imageMessage : JSQMessage!
                if (sentByUser && dataManager.isUser) || (!sentByUser && !dataManager.isUser ){
                    imageMessage = JSQMessage(senderId: senderId, displayName: "", media: media)
                } else {
                    media.appliesMediaViewMaskAsOutgoing = false
                    imageMessage = JSQMessage(senderId: "notUser", displayName: "", media: media)
                }
                
                if (insertAtIndex != -1) {
                    messages.insert(imageMessage, atIndex: insertAtIndex)
                    if let mk: String = messageKey {
                        messageKeyArray.insert(mk, atIndex: insertAtIndex)
                    }
                } else {
                    messages.append(imageMessage)
                    if let mk: String = messageKey {
                        messageKeyArray.append(mk)
                    }
                }
                
                //let data : NSData = NSKeyedArchiver.archivedDataWithRootObject(Array(messages.suffix(cacheLength)))
                //cache.set(value: data, key: "messages" + senderId)
                //cache.set(value: NSKeyedArchiver.archivedDataWithRootObject(Array(messageKeyArray.suffix(cacheLength))), key: "messageKeyArray" + senderId)
                //defaults.setObject(data, forKey: "messages" + senderId) //addedSecond
                //defaults.setObject(Array(messageKeyArray.suffix(cacheLength)), forKey: "messageKeyArray" + senderId)
                
                finishReceivingMessage()
            }
        }
    }
    
    func addMediaMessageData(type: String, fileName: String, downloadUrl: String) {
        let itemRef = messageReference.childByAutoId()//(String(messageCount)) // 1
        let messageItem = [ // 2
            "text": "",
            "senderId": senderId,
            "sentByUser": dataManager.isUser,
            "type": type,
            "fileName": fileName,
            "hasBeenForwarded": false,
            "mediaDownloadUrl": downloadUrl
        ]
        itemRef.setValue(messageItem)
        itemRef.child("timestamp").setValue(FIRServerValue.timestamp())
        addTimestampToMessageData()
        addUnReadReceiptToMessageData()
        messageKeyArray.append(itemRef.key)
        //cache.set(value: NSKeyedArchiver.archivedDataWithRootObject(Array(messageKeyArray.suffix(cacheLength))), key: "messageKeyArray" + senderId)
        //defaults.setObject(Array(messageKeyArray.suffix(cacheLength)), forKey: "messageKeyArray" + senderId)
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
    }
    
    func storeImageOnFirebase(image: UIImage, fileName: String, mediaType: String) {
        let storage = FIRStorage.storage()
        let storageRef = storage.referenceForURL("gs://crowdamp-messaging.appspot.com")
        let data : NSData = UIImageJPEGRepresentation(image, 1)!
        let mediaRef = storageRef.child(fileName)
        let metadata = FIRStorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let _ = mediaRef.putData(data, metadata: metadata) { metadata, error in
            if (error != nil) {
                print(error)
            } else {
                // Metadata contains file metadata such as size, content-type, and download URL.
                self.addMediaMessageData("image", fileName: fileName, downloadUrl: metadata!.downloadURL()!.absoluteString)
                
            }
        }
    }
    
    func downloadMediaFromFirebase(path : String, type: String, index : Int, sentByUser: Bool) {
        let storage = FIRStorage.storage()
        let storageRef = storage.referenceForURL("gs://crowdamp-messaging.appspot.com")
        let mediaRef = storageRef.child(path)
        mediaRef.dataWithMaxSize(100 * 1024 * 1024) { (data, error) -> Void in
            if (error != nil) {
                print(error)
            } else {
                if type == "image" {
                    let image = UIImage(data: data!)
                    self.addImageToMessagesView(image!, index: index, fileName: path, sentByUser: sentByUser)
                }
                // Data for "images/island.jpg" is returned
                // ... let islandImage: UIImage! = UIImage(data: data!)
            }
        }
    }
    
    func addImageToMessagesView(image: UIImage, index: Int, fileName: String, sentByUser: Bool) {
        //if !displayedMedia.contains(fileName) {
        let media = JSQPhotoMediaItem(image: image)
        let imageMessage :JSQMessage!
        if (sentByUser && dataManager.isUser) || (!sentByUser && !dataManager.isUser ){
            imageMessage = JSQMessage(senderId: senderId, displayName: "", media: media)
        } else {
            media.appliesMediaViewMaskAsOutgoing = false
            imageMessage = JSQMessage(senderId: "notUser", displayName: "", media: media)
        }
        
        if index >= messages.count {
            messages.append(imageMessage)
        } else {
            messages[index] = imageMessage
        }
        //let data : NSData = NSKeyedArchiver.archivedDataWithRootObject(Array(messages.suffix(cacheLength)))
        //cache.set(value: data, key: "messages" + senderId)
        //defaults.setObject(data, forKey: "messages" + senderId) // Just added
        finishReceivingMessage()
        //            if messages.count > 3 {
        //                self.collectionView?.scrollToItemAtIndexPath(NSIndexPath(forItem: 1, inSection: 0), atScrollPosition: .Top, animated: true)
        //            }
        displayedMedia.insert(fileName)
        //}
    }
    
    func loadMoreMessages() {
        print("id:")
        let messagesQuery = messageReference.queryOrderedByKey().queryEndingAtValue(messageKeyArray[0]).queryLimitedToLast(messagesLoaded + 1)
        var counter : UInt = 0
        messagesQuery.observeEventType(.ChildAdded) { (snapshot: FIRDataSnapshot!) in
            self.refreshControl.beginRefreshing()
            
            
            print("didReceiveQuery \(snapshot)")
            let id = snapshot.value?["senderId"] as? String
            let text = snapshot.value?["text"] as? String
            let sentByUser = snapshot.value?["sentByUser"] as? Bool
            let type = snapshot.value?["type"] as? String
            let fileName = snapshot.value?["fileName"] as? String
            
            if  id != nil && text != nil && sentByUser != nil && type != nil && fileName != nil {
                if counter < self.messagesLoaded {
                    print(counter)
                    if type == "text" {
                        self.addMessage(id!, text: text!, sentByUser: sentByUser!, key: snapshot.key, insertAtIndex: Int(counter))
                    } else if type == "image" {
                        if !self.messageKeyArray.contains(snapshot.key) {
                            self.downloadMediaFromFirebase(fileName!, type: type!, index: Int(counter), sentByUser: sentByUser!)
                            self.sendImageMessage(nil, shouldUploadToFirebase: false, title: fileName!, sentByUser: sentByUser!, messageKey: snapshot.key, insertAtIndex: Int(counter))
                        }
                    }
                    self.finishReceivingMessage()
                    
                    
                }
            }
            counter += 1
            self.refreshControl.endRefreshing()
            //                if self.messages.count > 3 {
            //                    self.collectionView?.scrollToItemAtIndexPath(NSIndexPath(forItem: 1, inSection: 0), atScrollPosition: .Top, animated: true)
            //                }
            
        }
        self.refreshControl.endRefreshing()
        print("ShouldLoadMoreMessages")
    }
    
    func displayProgressHud(message : String) {
        let loadingNotification = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.Indeterminate
        loadingNotification.labelText = message
    }
    
    func removeProgressHuds () {
        MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
        
    }
    
    func downloadNotificationId() {
        if !dataManager.isUser {
            let pushIdRef = rootReference.child("PushIds").child(senderId)
            print(senderId)
            let pushIdQuery = pushIdRef.queryLimitedToLast(1)
            pushIdQuery.observeEventType(.ChildAdded) { (snapshot: FIRDataSnapshot!) in
                print(snapshot.value)
                self.pushId = snapshot.value! as! String
            }
        }
    }
    
    func sendPushNotificationToCounterpart(notificationContent: String) {
        if let id : String = pushId {
            if let oneSig : OneSignal = dataManager.oneSignal {
                oneSig.postNotification(["contents": ["en": notificationContent], "include_player_ids": [id]])
            }
        } else {
            downloadNotificationId()
        }
    }
    
    func addUnReadReceiptToMessageData() {
        if dataManager.isUser {
            let ref = rootReference.child(firebaseContainerRefferenceName + "/" + senderId + "/influencerDidRead")
            ref.setValue(false)
        } else {
            let ref = rootReference.child(firebaseContainerRefferenceName + "/" + senderId + "/userDidRead")
            ref.setValue(false)
        }
    }
    
    func addReadReceiptToMessageData() {
        if (self.isVisible) {
            if dataManager.isUser {
                let ref = rootReference.child(firebaseContainerRefferenceName + "/" + senderId + "/userDidRead")
                ref.setValue(true)
            } else {
                let ref = rootReference.child(firebaseContainerRefferenceName + "/" + senderId + "/influencerDidRead")
                ref.setValue(true)
            }
        }
    }
    
    func addTimestampToMessageData() {
        let ref = rootReference.child(firebaseContainerRefferenceName + "/" + senderId + "/timestamp")
        ref.setValue(FIRServerValue.timestamp())
        print(FIRServerValue.timestamp())
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        if messages.count > indexPath.item {
            if let deliveryStatus = messages[indexPath.item].deliveryStatus {
                if messages[indexPath.item].deliveryStatus == "Delivery Error" {
                    return NSAttributedString(string: (messages[indexPath.item].deliveryStatus))
                }
            }
        }
        return nil
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        if messages.count > indexPath.item {
            if let deliveryStatus = messages[indexPath.item].deliveryStatus {
                if (deliveryStatus == "Delivery Error") {
                    return 20.0
                }
            }
        }
        return 0
    }
    
    func uploadUserInfo(userId: String, token: String, secret: String) {
        let rootReference = FIRDatabase.database().referenceFromURL("https://crowdamp-messaging.firebaseio.com/" + dataManager.influencerId)
        let twitterDataRef = rootReference.child("TwitterData")
        let userTwitterDataRef = twitterDataRef.child(userId)
        let pushItem : NSDictionary  = [
            "token": token,
            "secret": secret,
            "hasRecorded": true
            
        ]
        userTwitterDataRef.setValue(pushItem)
        uploadPushNotificationData(userId)
    }
    
    
    func uploadPushNotificationData(username: String) {
        if let oneSignalId : String = dataManager.onseSignalId {
            pushNotificationsEnabeled = true
            let rootReference = FIRDatabase.database().referenceFromURL("https://crowdamp-messaging.firebaseio.com/")
            let pushIdRef = rootReference.child("PushIds")
            var userPushIdRef = pushIdRef
            if dataManager.isUser {
                userPushIdRef = pushIdRef.child(username)
            } else {
                if dataManager.influencerId != "" {
                    userPushIdRef = pushIdRef.child(dataManager.influencerId)
                }
            }
            let pushItem : NSDictionary  = [
                "pushId": oneSignalId
            ]
            userPushIdRef.setValue(pushItem)
        }
        
    }
    
    
    
    
}



extension String {
    
    static func random(length: Int = 20) -> String {
        
        let base = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var randomString: String = ""
        
        for _ in 0..<length {
            let randomValue = arc4random_uniform(UInt32(base.characters.count))
            randomString += "\(base[base.startIndex.advancedBy(Int(randomValue))])"
        }
        
        return randomString
    }
}

extension UIImage {
    func resizeWithPercentage(percentage: CGFloat) -> UIImage? {
        let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: size.width * percentage, height: size.height * percentage)))
        imageView.contentMode = .ScaleAspectFit
        imageView.image = self
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.renderInContext(context)
        guard let result = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        return result
    }
    
    func resizeWithWidth(width: CGFloat) -> UIImage? {
        let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))))
        imageView.contentMode = .ScaleAspectFit
        imageView.image = self
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.renderInContext(context)
        guard let result = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        return result
    }
}

extension UIAlertController {
    
    public override func shouldAutorotate() -> Bool {
        return true
    }
    
    public override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.All
    }
}
