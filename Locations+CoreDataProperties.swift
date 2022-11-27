//
//  Locations+CoreDataProperties.swift
//  YagmurunDefteri
//
//  Created by Mustafa Batar on 19.12.2021.
//
//

import Foundation
import CoreData


extension Locations {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Locations> {
        return NSFetchRequest<Locations>(entityName: "Locations")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var name: String?
    @NSManaged public var note: String?
    @NSManaged public var moment: Moments?

}

extension Locations : Identifiable {

}
