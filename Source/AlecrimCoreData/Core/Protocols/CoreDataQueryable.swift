//
//  CoreDataQueryable.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-08-08.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation
import CoreData

public protocol CoreDataQueryable: GenericQueryable {
    
    associatedtype Item: NSFetchRequestResult
    
    var batchSize: Int { get set }

    var dataContext: NSManagedObjectContext { get }
    var entityDescription: NSEntityDescription { get }

    func toFetchRequest<ResultType: NSFetchRequestResult>() -> NSFetchRequest<ResultType>
    
}

// MARK: - Enumerable

extension CoreDataQueryable {
    
    public func count() -> Int {
        do {
            let c = try self.dataContext.count(for: self.toFetchRequest())
            
            if c != NSNotFound {
                return c
            }
            else {
                return 0
            }
        }
        catch let error {
            AlecrimCoreDataError.handleError(error)
        }
    }
    
}


// MARK: - aggregate

extension CoreDataQueryable {
    
    public func sum<U>(_ closure: (Self.Item.Type) -> Attribute<U>) -> U {
        let attribute = closure(Self.Item.self)
        return self.aggregate(using: "sum", attribute: attribute)
    }
    
    public func min<U>(_ closure: (Self.Item.Type) -> Attribute<U>) -> U {
        let attribute = closure(Self.Item.self)
        return self.aggregate(using: "min", attribute: attribute)
    }
    
    public func max<U>(_ closure: (Self.Item.Type) -> Attribute<U>) -> U {
        let attribute = closure(Self.Item.self)
        return self.aggregate(using: "max", attribute: attribute)
    }

    // same as average, for convenience
    public func avg<U>(_ closure: (Self.Item.Type) -> Attribute<U>) -> U {
        let attribute = closure(Self.Item.self)
        return self.aggregate(using: "average", attribute: attribute)
    }

    public func average<U>(_ closure: (Self.Item.Type) -> Attribute<U>) -> U {
        let attribute = closure(Self.Item.self)
        return self.aggregate(using: "average", attribute: attribute)
    }
    
    fileprivate func aggregate<U>(using functionName: String, attribute: Attribute<U>) -> U {
        let attributeDescription = self.entityDescription.attributesByName[attribute.___name]!
        
        let keyPathExpression = NSExpression(forKeyPath: attribute.___name)
        let functionExpression = NSExpression(forFunction: "\(functionName):", arguments: [keyPathExpression])
        
        let expressionDescription = NSExpressionDescription()
        expressionDescription.name = "___\(functionName)"
        expressionDescription.expression = functionExpression
        expressionDescription.expressionResultType = attributeDescription.attributeType
        
        let fetchRequest: NSFetchRequest<NSDictionary> = self.toFetchRequest()
        fetchRequest.propertiesToFetch =  [expressionDescription]
        fetchRequest.resultType = NSFetchRequestResultType.dictionaryResultType
        
        do {
            let results = try self.dataContext.fetch(fetchRequest)
            
            guard let firstResult = results.first else { throw AlecrimCoreDataError.unexpectedValue(results) }
            guard let anyObjectValue = firstResult.value(forKey: expressionDescription.name) else { throw AlecrimCoreDataError.unexpectedValue(firstResult) }
            guard let value = anyObjectValue as? U else { throw AlecrimCoreDataError.unexpectedValue(anyObjectValue) }
            
            return value
        }
        catch let error {
            AlecrimCoreDataError.handleError(error)
        }
    }
    
}
