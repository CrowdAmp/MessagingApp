//
//  ImageDisplayViewController.swift
//  ChatChat
//
//  Created by Ruben Mayer on 6/15/16.
//  Copyright © 2016 Razeware LLC. All rights reserved.
//

import UIKit

class ImageDisplayViewController: UIViewController {

    var image: UIImage!
    

 
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        imageView.image = image
        imageView.contentMode = .ScaleAspectFit
        imageView.addConstraint(NSLayoutConstraint(
            item: imageView,
            attribute: NSLayoutAttribute.Height,
            relatedBy: NSLayoutRelation.Equal,
            toItem: imageView,
            attribute: NSLayoutAttribute.Width,
            multiplier: image.size.height / image.size.width,
            constant: 0))
        
 

    }


    override func viewDidLoad() {
        
        self.navigationController?.navigationBarHidden = true
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(ImageDisplayViewController.respondToSwipeGesture(_:)))
        swipeRight.direction = UISwipeGestureRecognizerDirection.Right
        self.view.addGestureRecognizer(swipeRight)
        
        super.viewDidLoad()


        // Do any additional setup after loading the view.
    }
    
    func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            
            
            switch swipeGesture.direction {
            case UISwipeGestureRecognizerDirection.Right:
                print("didSwipeRight")
                self.navigationController?.popViewControllerAnimated(true)
            default:
                break
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBOutlet weak var imageView: UIImageView!
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
