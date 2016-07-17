//
//  DataManager.swift
//  ChatChat
//
//  Created by Ruben Mayer on 6/14/16.
//  Copyright © 2016 Razeware LLC. All rights reserved.
//

import Foundation

class DataManager {
    static let sharedInstance = DataManager()
    var isUser = false
    var oneSignal : OneSignal?
    var onseSignalId : String?
    var influencerName = "Alex Ramos"
    var influencerId = "" {
        didSet {
            if influencerId == "KyleExum" {
                influencerId = influencerId.lowercaseString
            }
        }
    }
    
}