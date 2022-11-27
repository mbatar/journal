//
//  Moments+CoreDataProperties.swift
//  YagmurunDefteri
//
//  Created by Mustafa Batar on 19.12.2021.
//
//

import Foundation
import CoreData


extension Moments {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Moments> {
        return NSFetchRequest<Moments>(entityName: "Moments")
    }

    @NSManaged public var date: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var note: String?
    @NSManaged public var images: NSSet?
    @NSManaged public var locations: NSSet?

}

// MARK: Generated accessors for images
extension Moments {

    @objc(addImagesObject:)
    @NSManaged public func addToImages(_ value: Images)

    @objc(removeImagesObject:)
    @NSManaged public func removeFromImages(_ value: Images)

    @objc(addImages:)
    @NSManaged public func addToImages(_ values: NSSet)

    @objc(removeImages:)
    @NSManaged public func removeFromImages(_ values: NSSet)

}

// MARK: Generated accessors for locations
extension Moments {

    @objc(addLocationsObject:)
    @NSManaged public func addToLocations(_ value: Locations)

    @objc(removeLocationsObject:)
    @NSManaged public func removeFromLocations(_ value: Locations)

    @objc(addLocations:)
    @NSManaged public func addToLocations(_ values: NSSet)

    @objc(removeLocations:)
    @NSManaged public func removeFromLocations(_ values: NSSet)

}

extension Moments : Identifiable {

}
