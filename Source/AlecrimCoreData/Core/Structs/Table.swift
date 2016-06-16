//
//  Table.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-06-25.
//  Copyright (c) 2014, 2015 Alecrim. All rights reserved.
//

import Foundation
import CoreData

// MARK: -

private var cachedEntityDescriptions = [String : NSEntityDescription]()

private func cachedEntityDescription(for dataContext: NSManagedObjectContext, managedObjectType: NSManagedObject.Type) -> NSEntityDescription {
    let dataContextClassName = String(dataContext.dynamicType)
    let managedObjectClassName = String(managedObjectType)
    let cacheKey = "\(dataContextClassName)|\(managedObjectClassName)"
    
    let entityDescription: NSEntityDescription
    
    if let cachedEntityDescription = cachedEntityDescriptions[cacheKey] {
        entityDescription = cachedEntityDescription
    }
    else {
        let persistentStoreCoordinator = dataContext.persistentStoreCoordinator!
        let managedObjectModel = persistentStoreCoordinator.managedObjectModel
        
        entityDescription = managedObjectModel.entities.filter({ $0.managedObjectClassName.components(separatedBy: ".").last! == managedObjectClassName }).first!
        cachedEntityDescriptions[cacheKey] = entityDescription
    }
    
    return entityDescription
}

// MARK: -


public struct Table<T: NSManagedObject>: TableProtocol {
    
    public typealias Element = T
    
    public let dataContext: NSManagedObjectContext
    public let entityDescription: NSEntityDescription
    
    public var offset: Int = 0
    public var limit: Int = 0
    public var batchSize: Int = DataContextOptions.defaultBatchSize
    
    public var predicate: Predicate? = nil
    public var sortDescriptors: [SortDescriptor]? = nil
    
    public init(dataContext: NSManagedObjectContext) {
        self.dataContext = dataContext
        self.entityDescription = cachedEntityDescription(for: dataContext, managedObjectType: T.self)
    }
    
}
