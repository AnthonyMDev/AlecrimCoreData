//
//  NSCollectionViewExtensions.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-07-28.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

#if os(OSX)
    
import Foundation
import AppKit
    
@available(OSX 10.12, *)
extension FetchRequestController {
    
    public func bind<ItemType: NSCollectionViewItem>(to collectionView: NSCollectionView, sectionOffset: Int = 0, cellConfigurationHandler: ((ItemType, IndexPath) -> Void)? = nil) -> Self {
        var insertedSectionIndexes = IndexSet()
        var deletedSectionIndexes = IndexSet()
        var updatedSectionIndexes = IndexSet()
        
        var insertedItemIndexPaths = [IndexPath]()
        var deletedItemIndexPaths = [IndexPath]()
        var updatedItemIndexPaths = [IndexPath]()
        
        var reloadData = false
        
        self
            .needsReloadData {
                reloadData = true
            }
            .willChangeContent {
                if !reloadData {
                    insertedSectionIndexes.removeAll()
                    deletedSectionIndexes.removeAll()
                    updatedSectionIndexes.removeAll()
                    
                    insertedItemIndexPaths.removeAll(keepingCapacity: false)
                    deletedItemIndexPaths.removeAll(keepingCapacity: false)
                    updatedItemIndexPaths.removeAll(keepingCapacity: false)
                }
            }
            .didInsertSection { sectionInfo, sectionIndex in
                if !reloadData {
                    insertedSectionIndexes.insert(sectionIndex + sectionOffset)
                }
            }
            .didDeleteSection { sectionInfo, sectionIndex in
                if !reloadData {
                    deletedSectionIndexes.insert(sectionIndex + sectionOffset)
                    deletedItemIndexPaths = deletedItemIndexPaths.filter { $0.section != sectionIndex }
                    updatedItemIndexPaths = updatedItemIndexPaths.filter { $0.section != sectionIndex }
                }
            }
            .didInsertEntity { entity, newIndexPath in
                if !reloadData {
                    let newIndexPath = sectionOffset > 0 ? IndexPath(item: newIndexPath.item, section: newIndexPath.section + sectionOffset) : newIndexPath

                    if !insertedSectionIndexes.contains(newIndexPath.section) {
                        insertedItemIndexPaths.append(newIndexPath)
                    }
                }
            }
            .didDeleteEntity { entity, indexPath in
                if !reloadData {
                    let indexPath = sectionOffset > 0 ? IndexPath(item: indexPath.item, section: indexPath.section + sectionOffset) : indexPath

                    if !deletedSectionIndexes.contains(indexPath.section) {
                        deletedItemIndexPaths.append(indexPath)
                    }
                }
            }
            .didUpdateEntity { entity, indexPath in
                if !reloadData {
                    let indexPath = sectionOffset > 0 ? IndexPath(item: indexPath.item, section: indexPath.section + sectionOffset) : indexPath

                    if !deletedSectionIndexes.contains(indexPath.section) && deletedItemIndexPaths.index(of: indexPath) == nil && updatedItemIndexPaths.index(of: indexPath) == nil {
                        updatedItemIndexPaths.append(indexPath)
                    }
                }
            }
            .didMoveEntity { entity, indexPath, newIndexPath in
                if !reloadData {
                    let newIndexPath = sectionOffset > 0 ? IndexPath(item: newIndexPath.item, section: newIndexPath.section + sectionOffset) : newIndexPath
                    let indexPath = sectionOffset > 0 ? IndexPath(item: indexPath.item, section: indexPath.section + sectionOffset) : indexPath

                    if newIndexPath == indexPath {
                        if !deletedSectionIndexes.contains(indexPath.section) && deletedItemIndexPaths.index(of: indexPath) == nil && updatedItemIndexPaths.index(of: indexPath) == nil {
                            updatedItemIndexPaths.append(indexPath)
                        }
                    }
                    else {
                        if !deletedSectionIndexes.contains(indexPath.section) {
                            deletedItemIndexPaths.append(indexPath)
                        }
                        
                        if !insertedSectionIndexes.contains(newIndexPath.section) {
                            insertedItemIndexPaths.append(newIndexPath)
                        }
                    }
                }
            }
            .didChangeContent { [unowned collectionView] in
                if reloadData {
                    collectionView.reloadData()
                    
                    insertedSectionIndexes.removeAll()
                    deletedSectionIndexes.removeAll()
                    updatedSectionIndexes.removeAll()
                    
                    insertedItemIndexPaths.removeAll(keepingCapacity: false)
                    deletedItemIndexPaths.removeAll(keepingCapacity: false)
                    updatedItemIndexPaths.removeAll(keepingCapacity: false)
                    
                    reloadData = false
                }
                else {
                    collectionView.performBatchUpdates({
                        if deletedSectionIndexes.count > 0 {
                            collectionView.deleteSections(deletedSectionIndexes)
                        }
                        
                        if insertedSectionIndexes.count > 0 {
                            collectionView.insertSections(insertedSectionIndexes)
                        }
                        
                        if updatedSectionIndexes.count > 0 {
                            collectionView.reloadSections(updatedSectionIndexes)
                        }
                        
                        if deletedItemIndexPaths.count > 0 {
                            collectionView.deleteItems(at: Set(deletedItemIndexPaths))
                        }
                        
                        if insertedItemIndexPaths.count > 0 {
                            collectionView.insertItems(at: Set(insertedItemIndexPaths))
                        }
                        
                        if updatedItemIndexPaths.count > 0 && cellConfigurationHandler == nil {
                            collectionView.reloadItems(at: Set(updatedItemIndexPaths))
                        }
                        },
                        completionHandler: { finished in
                            if finished {
                                if let cellConfigurationHandler = cellConfigurationHandler {
                                    for updatedItemIndexPath in updatedItemIndexPaths {
                                        if let item = collectionView.item(at: updatedItemIndexPath) as? ItemType {
                                            cellConfigurationHandler(item, updatedItemIndexPath)
                                        }
                                    }
                                }
                                
                                insertedSectionIndexes.removeAll()
                                deletedSectionIndexes.removeAll()
                                updatedSectionIndexes.removeAll()
                                
                                insertedItemIndexPaths.removeAll(keepingCapacity: false)
                                deletedItemIndexPaths.removeAll(keepingCapacity: false)
                                updatedItemIndexPaths.removeAll(keepingCapacity: false)
                                
                                reloadData = false
                            }
                    })
                }
        }
        
        //
        try! self.performFetch()
        collectionView.reloadData()
        
        //
        return self
    }

}
    
#endif
