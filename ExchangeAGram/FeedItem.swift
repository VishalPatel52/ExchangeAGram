//
//  FeedItem.swift
//  ExchangeAGram
//
//  Created by Vishal Patel on 29/10/14.
//  Copyright (c) 2014 Vishal Patel. All rights reserved.
//

import Foundation
import CoreData

@objc (FeedItem)
class FeedItem: NSManagedObject {

    @NSManaged var caption: String
    @NSManaged var image: NSData

}
