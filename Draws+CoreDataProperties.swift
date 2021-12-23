//
//  Draws+CoreDataProperties.swift
//  YagmurunDefteri
//
//  Created by Mustafa Batar on 19.12.2021.
//
//

import Foundation
import CoreData


extension Draws {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Draws> {
        return NSFetchRequest<Draws>(entityName: "Draws")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var coordinates: NSSet?

}

// MARK: Generated accessors for coordinates
extension Draws {

    @objc(addCoordinatesObject:)
    @NSManaged public func addToCoordinates(_ value: DrawCoordinates)

    @objc(removeCoordinatesObject:)
    @NSManaged public func removeFromCoordinates(_ value: DrawCoordinates)

    @objc(addCoordinates:)
    @NSManaged public func addToCoordinates(_ values: NSSet)

    @objc(removeCoordinates:)
    @NSManaged public func removeFromCoordinates(_ values: NSSet)

}

extension Draws : Identifiable {

}
