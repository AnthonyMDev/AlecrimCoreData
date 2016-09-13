//
//  NSManagedObjectExtensions.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-06-24.
//  Copyright (c) 2014, 2015 Alecrim. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObject {

    public func inContext(_ otherContext: NSManagedObjectContext) throws -> Self {
        if self.managedObjectContext === otherContext {
            return self
        }
        
        if self.objectID.isTemporaryID {
            try otherContext.obtainPermanentIDs(for: [self])
        }
        
        let otherManagedObject = try otherContext.existingObject(with: self.objectID)
        
        return unsafeBitCast(otherManagedObject, to: type(of: self))
    }
    
}

extension NSManagedObject {
    
    public func delete() {
        self.managedObjectContext!.delete(self)
    }
    
    public func refresh(mergingChanges mergeChanges: Bool = true) {
        self.managedObjectContext!.refresh(self, mergeChanges: mergeChanges)
    }

}

extension NSManagedObject {
    
    public class func isIn(_ values: Set<NSManagedObject>) -> NSComparisonPredicate {
        let rightExpressionConstantValues = values.map { NSExpression(forConstantValue: $0.objectID) }
        let rightExpression = NSExpression(forAggregate: rightExpressionConstantValues)
        let leftExpression = NSExpression(forKeyPath: "objectID")
        
        return NSComparisonPredicate(
            leftExpression: leftExpression,
            rightExpression: rightExpression,
            modifier: .direct,
            type: .in,
            options: NSComparisonPredicate.Options()
        )
    }
    
}
