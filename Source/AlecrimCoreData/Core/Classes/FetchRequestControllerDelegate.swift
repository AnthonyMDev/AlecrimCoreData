//
//  FetchRequestControllerDelegate.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-07-26.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation
import CoreData

@available(OSX 10.12, *)
internal final class FetchRequestControllerDelegate<T: NSManagedObject>: NSObject, NSFetchedResultsControllerDelegate {
    
    fileprivate var needsReloadDataClosure: (() -> Void)?
    
    fileprivate lazy var willChangeContentClosures = Array<() -> Void>()
    fileprivate lazy var didChangeContentClosures = Array<() -> Void>()
    
    fileprivate lazy var didInsertSectionClosures = Array<(FetchRequestControllerSection<T>, Int) -> Void>()
    fileprivate lazy var didDeleteSectionClosures = Array<(FetchRequestControllerSection<T>, Int) -> Void>()
    
    fileprivate lazy var didInsertEntityClosures = Array<(T, IndexPath) -> Void>()
    fileprivate lazy var didDeleteEntityClosures = Array<(T, IndexPath) -> Void>()
    fileprivate lazy var didUpdateEntityClosures = Array<(T, IndexPath) -> Void>()
    fileprivate lazy var didMoveEntityClosures = Array<(T, IndexPath, IndexPath) -> Void>()
    
    fileprivate var sectionIndexTitleClosure: ((String) -> String?)?

    // MARK: - NSFetchedResultsControllerDelegate methods
    
    @objc func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case NSFetchedResultsChangeType(rawValue: 0)!:
            // iOS 8 bug - Do nothing if we get an invalid change type.
            break
            
        case .insert:
            for closure in self.didInsertEntityClosures {
                closure(anObject as! T, newIndexPath!)
            }
            
        case .delete:
            for closure in self.didDeleteEntityClosures {
                closure(anObject as! T, indexPath!)
            }
            
        case .update:
            for closure in self.didUpdateEntityClosures {
                closure(anObject as! T, indexPath!)
            }
            
        case .move:
            for closure in self.didMoveEntityClosures {
                closure(anObject as! T, indexPath!, newIndexPath!)
            }
        }
    }
    
    @objc func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            for closure in self.didInsertSectionClosures {
                closure(FetchRequestControllerSection(underlyingSectionInfo: sectionInfo), sectionIndex)
            }
            
        case .delete:
            for closure in self.didDeleteSectionClosures {
                closure(FetchRequestControllerSection(underlyingSectionInfo: sectionInfo), sectionIndex)
            }
            
        default:
            break
        }
    }
    
    @objc func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        for closure in self.willChangeContentClosures {
            closure()
        }
    }
    
    @objc func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        for closure in self.didChangeContentClosures {
            closure()
        }
    }
    
    @objc func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, sectionIndexTitleForSectionName sectionName: String) -> String? {
        return self.sectionIndexTitleClosure?(sectionName)
    }
}

// MARK: - FetchRequestController extensions
@available(OSX 10.12, *)
extension FetchRequestController {
    
    public func refresh() throws {
        self.delegate.needsReloadDataClosure?()
        
        for closure in self.delegate.willChangeContentClosures {
            closure()
        }
        
        if let cacheName = self.cacheName {
            FetchRequestController.deleteCache(withName: cacheName)
        }
        
        try self.performFetch()
        
        for closure in self.delegate.didChangeContentClosures {
            closure()
        }
    }
    
}

@available(OSX 10.12, *)
extension FetchRequestController {
 
    internal func needsReloadData(_ closure: @escaping () -> Void) -> Self {
        self.delegate.needsReloadDataClosure = closure
        return self
    }

}

@available(OSX 10.12, *)
extension FetchRequestController {
    
    @discardableResult
    public func willChangeContent(_ closure: @escaping () -> Void) -> Self {
        self.delegate.willChangeContentClosures.append(closure)
        return self
    }
    
    @discardableResult
    public func didChangeContent(_ closure: @escaping () -> Void) -> Self {
        self.delegate.didChangeContentClosures.append(closure)
        return self
    }
    
    @discardableResult
    public func didInsertSection(_ closure: @escaping (FetchRequestControllerSection<T>, Int) -> Void) -> Self {
        self.delegate.didInsertSectionClosures.append(closure)
        return self
    }
    
    @discardableResult
    public func didDeleteSection(_ closure: @escaping (FetchRequestControllerSection<T>, Int) -> Void) -> Self {
        self.delegate.didDeleteSectionClosures.append(closure)
        return self
    }
    
    @discardableResult
    public func didInsertEntity(_ closure: @escaping (T, IndexPath) -> Void) -> Self {
        self.delegate.didInsertEntityClosures.append(closure)
        return self
    }
    
    @discardableResult
    public func didDeleteEntity(_ closure: @escaping (T, IndexPath) -> Void) -> Self {
        self.delegate.didDeleteEntityClosures.append(closure)
        return self
    }
    
    @discardableResult
    public func didUpdateEntity(_ closure: @escaping (T, IndexPath) -> Void) -> Self {
        self.delegate.didUpdateEntityClosures.append(closure)
        return self
    }
    
    @discardableResult
    public func didMoveEntity(_ closure: @escaping (T, IndexPath, IndexPath) -> Void) -> Self {
        self.delegate.didMoveEntityClosures.append(closure)
        return self
    }
    
    @discardableResult
    public func sectionIndexTitle(_ closure: @escaping (String) -> String?) -> Self {
        self.delegate.sectionIndexTitleClosure = closure
        return self
    }
    
}
