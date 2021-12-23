//
//  Images+CoreDataProperties.swift
//  YagmurunDefteri
//
//  Created by Mustafa Batar on 19.12.2021.
//
//

import Foundation
import CoreData


extension Images {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Images> {
        return NSFetchRequest<Images>(entityName: "Images")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var image: Data?
    @NSManaged public var moment: Moments?

}

extension Images : Identifiable {

}
