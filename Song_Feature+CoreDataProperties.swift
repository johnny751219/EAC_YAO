//
//  Song_Feature+CoreDataProperties.swift
//  
//
//  Created by Johnny_Yao on 2017/5/13.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Song_Feature {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Song_Feature> {
        return NSFetchRequest<Song_Feature>(entityName: "Song_Feature");
    }
    @NSManaged public var song_id: Int16
    @NSManaged public var song_answer: Int16
    @NSManaged public var pos_amount: Int16
    @NSManaged public var neg_amount: Int16
    @NSManaged public var pos_score: Float
    @NSManaged public var neg_score: Float
    @NSManaged public var pos_avg_amount: Float
    @NSManaged public var neg_avg_amount: Float
    @NSManaged public var pos_avg_score: Float
    @NSManaged public var neg_avg_score: Float
    

}
