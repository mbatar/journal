//
//  DrawCoordinates+CoreDataProperties.swift
//  YagmurunDefteri
//
//  Created by Mustafa Batar on 19.12.2021.
//
//

import Foundation
import CoreData


extension DrawCoordinates {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DrawCoordinates> {
        return NSFetchRequest<DrawCoordinates>(entityName: "DrawCoordinates")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var date: Date?
    @NSManaged public var draw: Draws?

}

extension DrawCoordinates : Identifiable {

}
