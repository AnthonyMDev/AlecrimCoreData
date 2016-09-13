//
//  UITableViewExtensions.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-07-28.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

#if os(iOS)
    
import Foundation
import UIKit
    
extension FetchRequestController {

    public func bind<CellType: UITableViewCell>(to tableView: UITableView, rowAnimation: UITableViewRowAnimation = .fade, sectionOffset: Int = 0, cellConfigurationHandler: ((CellType, IndexPath) -> Void)? = nil) -> Self {
        let insertedSectionIndexes = NSMutableIndexSet()
        let deletedSectionIndexes = NSMutableIndexSet()
        let updatedSectionIndexes = NSMutableIndexSet()
        
        var insertedItemIndexPaths = [IndexPath]()
        var deletedItemIndexPaths = [IndexPath]()
        var updatedItemIndexPaths = [IndexPath]()
        
        var reloadData = false
        
        //
        self
            .needsReloadData {
                reloadData = true
            }
            .willChangeContent {
                if !reloadData {
                    insertedSectionIndexes.removeAllIndexes()
                    deletedSectionIndexes.removeAllIndexes()
                    updatedSectionIndexes.removeAllIndexes()
                    
                    insertedItemIndexPaths.removeAll(keepingCapacity: false)
                    deletedItemIndexPaths.removeAll(keepingCapacity: false)
                    updatedItemIndexPaths.removeAll(keepingCapacity: false)
                    
                    //
                    tableView.beginUpdates()
                }
            }
            .didInsertSection { sectionInfo, sectionIndex in
                if !reloadData {
                    insertedSectionIndexes.add(sectionIndex + sectionOffset)
                }
            }
            .didDeleteSection { sectionInfo, sectionIndex in
                if !reloadData {
                    deletedSectionIndexes.add(sectionIndex + sectionOffset)
                    deletedItemIndexPaths = deletedItemIndexPaths.filter { ($0 as NSIndexPath).section != sectionIndex}
                    updatedItemIndexPaths = updatedItemIndexPaths.filter { ($0 as NSIndexPath).section != sectionIndex}
                }
            }
            .didInsertEntity { entity, newIndexPath in
                if !reloadData {
                    let newIndexPath = sectionOffset > 0 ? IndexPath(row: (newIndexPath as NSIndexPath).item, section: (newIndexPath as NSIndexPath).section + sectionOffset) : newIndexPath as IndexPath

                    if !insertedSectionIndexes.contains((newIndexPath as NSIndexPath).section) {
                        insertedItemIndexPaths.append(newIndexPath)
                    }
                }
            }
            .didDeleteEntity { entity, indexPath in
                if !reloadData {
                    let indexPath = sectionOffset > 0 ? IndexPath(row: (indexPath as NSIndexPath).item, section: (indexPath as NSIndexPath).section + sectionOffset) : indexPath as IndexPath

                    if !deletedSectionIndexes.contains((indexPath as NSIndexPath).section) {
                        deletedItemIndexPaths.append(indexPath)
                    }
                }
            }
            .didUpdateEntity { entity, indexPath in
                if !reloadData {
                    let indexPath = sectionOffset > 0 ? IndexPath(row: (indexPath as NSIndexPath).item, section: (indexPath as NSIndexPath).section + sectionOffset) : indexPath as IndexPath

                    if !deletedSectionIndexes.contains((indexPath as NSIndexPath).section) && deletedItemIndexPaths.index(of: indexPath) == nil && updatedItemIndexPaths.index(of: indexPath) == nil {
                        updatedItemIndexPaths.append(indexPath)
                    }
                }
            }
            .didMoveEntity { entity, indexPath, newIndexPath in
                if !reloadData {
                    let newIndexPath = sectionOffset > 0 ? IndexPath(row: (newIndexPath as NSIndexPath).item, section: (newIndexPath as NSIndexPath).section + sectionOffset) : newIndexPath as IndexPath
                    let indexPath = sectionOffset > 0 ? IndexPath(row: (indexPath as NSIndexPath).item, section: (indexPath as NSIndexPath).section + sectionOffset) : indexPath as IndexPath

                    if newIndexPath == indexPath {
                        if !deletedSectionIndexes.contains((indexPath as NSIndexPath).section) && deletedItemIndexPaths.index(of: indexPath) == nil && updatedItemIndexPaths.index(of: indexPath) == nil {
                            updatedItemIndexPaths.append(indexPath)
                        }
                    }
                    else {
                        if !deletedSectionIndexes.contains((indexPath as NSIndexPath).section) {
                            deletedItemIndexPaths.append(indexPath)
                        }
                        
                        if !insertedSectionIndexes.contains((newIndexPath as NSIndexPath).section) {
                            insertedItemIndexPaths.append(newIndexPath)
                        }
                    }
                }
            }
            .didChangeContent { [unowned tableView] in
                if reloadData {
                    tableView.reloadData()
                }
                else {
                    if deletedSectionIndexes.count > 0 {
                        tableView.deleteSections(deletedSectionIndexes as IndexSet, with: rowAnimation)
                    }
                    
                    if insertedSectionIndexes.count > 0 {
                        tableView.insertSections(insertedSectionIndexes as IndexSet, with: rowAnimation)
                    }
                    
                    if updatedSectionIndexes.count > 0 {
                        tableView.reloadSections(updatedSectionIndexes as IndexSet, with: rowAnimation)
                    }
                    
                    if deletedItemIndexPaths.count > 0 {
                        tableView.deleteRows(at: deletedItemIndexPaths, with: rowAnimation)
                    }
                    
                    if insertedItemIndexPaths.count > 0 {
                        tableView.insertRows(at: insertedItemIndexPaths, with: rowAnimation)
                    }
                    
                    if updatedItemIndexPaths.count > 0 && cellConfigurationHandler == nil {
                        tableView.reloadRows(at: updatedItemIndexPaths, with: rowAnimation)
                    }
                    
                    tableView.endUpdates()
                    
                    if let cellConfigurationHandler = cellConfigurationHandler {
                        for updatedItemIndexPath in updatedItemIndexPaths {
                            if let cell = tableView.cellForRow(at: updatedItemIndexPath) as? CellType {
                                cellConfigurationHandler(cell, updatedItemIndexPath)
                            }
                        }
                    }
                }
                
                //
                insertedSectionIndexes.removeAllIndexes()
                deletedSectionIndexes.removeAllIndexes()
                updatedSectionIndexes.removeAllIndexes()
                
                insertedItemIndexPaths.removeAll(keepingCapacity: false)
                deletedItemIndexPaths.removeAll(keepingCapacity: false)
                updatedItemIndexPaths.removeAll(keepingCapacity: false)
                
                reloadData = false
        }
        
        //
        try! self.performFetch()
        tableView.reloadData()

        //
        return self
    }
        
}

#endif
