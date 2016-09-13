//
//  NSManagedObjectContextExtensions.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-07-27.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
    
    /// Asynchronously performs a given closure on the receiver’s queue.
    ///
    /// - parameter closure: The closure to perform.
    ///
    /// - note: Calling this method is the same as calling `performBlock:` method.
    ///
    /// - seealso: `performBlock:`
    public func perform(_ closure: () -> Void) {
        self.perform(closure)
    }
    
    /// Synchronously performs a given closure on the receiver’s queue.
    ///
    /// - parameter closure: The closure to perform
    ///
    /// - note: Calling this method is the same as calling `performBlockAndWait:` method.
    ///
    /// - seealso: `performBlockAndWait:`
    public func performAndWait(_ closure: () -> Void) {
        self.performAndWait(closure)
    }

}

extension NSManagedObjectContext {
    
    @available(OSX 10.10, iOS 8.0, *)
    internal func executeAsynchronousFetchRequest<T: NSFetchRequestResult>(fetchRequest: NSFetchRequest<T>, completion completionHandler: @escaping ([T]?, Error?) -> Void) throws {
        let asynchronousFetchRequest = NSAsynchronousFetchRequest<T>(fetchRequest: fetchRequest) { (asynchronousFetchResult: NSAsynchronousFetchResult<T>) in
            completionHandler(asynchronousFetchResult.finalResult, asynchronousFetchResult.operationError)
        }
        
        let persistentStoreResult = try self.execute(asynchronousFetchRequest)
        if let _ = persistentStoreResult as? NSAsynchronousFetchResult<T> {
            
        }
        else {
            throw AlecrimCoreDataError.unexpectedValue(persistentStoreResult)
        }
    }
    
}

extension NSManagedObjectContext {
    
    @available(OSX 10.10, iOS 8.0, *)
    internal func executeBatchUpdateRequest(entityDescription: NSEntityDescription, propertiesToUpdate: [AnyHashable: Any], predicate: NSPredicate, completion completionHandler: @escaping (Int, Error?) -> Void) {
        let batchUpdateRequest = NSBatchUpdateRequest(entity: entityDescription)
        batchUpdateRequest.propertiesToUpdate = propertiesToUpdate
        batchUpdateRequest.predicate = predicate
        batchUpdateRequest.resultType = .updatedObjectsCountResultType
        
        //
        // HAX:
        // The `executeRequest:` method for a batch update only works in the root saving context.
        // If called in a context that has a parent context, both the `batchUpdateResult` and the `error` will be quietly set to `nil` by Core Data.
        //
        
        var moc: NSManagedObjectContext = self
        while moc.parent != nil {
            moc = moc.parent!
        }
        
        moc.perform {
            do {
                let persistentStoreResult = try moc.execute(batchUpdateRequest)
                
                if let batchUpdateResult = persistentStoreResult as? NSBatchUpdateResult {
                    if let count = batchUpdateResult.result as? Int {
                        completionHandler(count, nil)
                    }
                    else {
                        throw AlecrimCoreDataError.unexpectedValue(batchUpdateResult.result)
                    }
                }
                else {
                    throw AlecrimCoreDataError.unexpectedValue(persistentStoreResult)
                }
            }
            catch let error {
                completionHandler(0, error)
            }
        }
    }

    @available(OSX 10.11, iOS 9.0, *)
    internal func executeBatchDeleteRequest(entityDescription: NSEntityDescription, objectIDs: [NSManagedObjectID], completion completionHandler: @escaping (Int, Error?) -> Void) {
        let batchDeleteRequest = NSBatchDeleteRequest(objectIDs: objectIDs)
        batchDeleteRequest.resultType = .resultTypeCount
        
        //
        // HAX:
        // The `executeRequest:` method for a batch delete may only works in the root saving context.
        // If called in a context that has a parent context, both the `batchDeleteResult` and the `error` will be quietly set to `nil` by Core Data.
        //
        
        var moc: NSManagedObjectContext = self
        while moc.parent != nil {
            moc = moc.parent!
        }
        
        moc.perform {
            do {
                let persistentStoreResult = try moc.execute(batchDeleteRequest)
                
                if let batchDeleteResult = persistentStoreResult as? NSBatchDeleteResult {
                    if let count = batchDeleteResult.result as? Int {
                        completionHandler(count, nil)
                    }
                    else {
                        throw AlecrimCoreDataError.unexpectedValue(batchDeleteResult.result)
                    }
                }
                else {
                    throw AlecrimCoreDataError.unexpectedValue(persistentStoreResult)
                }
            }
            catch let error {
                completionHandler(0, error)
            }
        }
    }
    
}
