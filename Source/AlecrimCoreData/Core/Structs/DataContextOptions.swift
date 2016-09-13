//
//  DataContextOptions.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-02-26.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation
import CoreData

public enum PersistentStoreType {
    case disk
    case memory
}

public struct DataContextOptions {
    
    // MARK: - options valid for all instances
    
    public static var defaultBatchSize: Int = 20
    public static var defaultComparisonPredicateOptions: NSComparisonPredicate.Options = [.caseInsensitive, .diacriticInsensitive]

    // MARK: -

    public let managedObjectModelURL: URL?
    public let persistentStoreURL: URL?
    
    // MARK: -
    
    public var persistentStoreType: PersistentStoreType = .disk
    public var persistentStoreConfiguration: String? = nil
    public var persistentStoreOptions: [AnyHashable: Any] = [NSMigratePersistentStoresAutomaticallyOption : true, NSInferMappingModelAutomaticallyOption : true]
    
    // MARK: - THE constructor
    
    public init(managedObjectModelURL: URL, persistentStoreURL: URL) {
        self.managedObjectModelURL = managedObjectModelURL
        self.persistentStoreURL = persistentStoreURL
    }
    
    // MARK: - "convenience" initializers
    
    public init(managedObjectModelURL: URL) throws {
        let mainBundle = Bundle.main
        
        self.managedObjectModelURL = managedObjectModelURL
        self.persistentStoreURL = try mainBundle.defaultPersistentStoreURL()
    }
    
    public init(persistentStoreURL: URL) throws {
        let mainBundle = Bundle.main
        
        self.managedObjectModelURL = try mainBundle.defaultManagedObjectModelURL()
        self.persistentStoreURL = persistentStoreURL
    }
    
    public init() throws {
        let mainBundle = Bundle.main
        
        self.managedObjectModelURL = try mainBundle.defaultManagedObjectModelURL()
        self.persistentStoreURL = try mainBundle.defaultPersistentStoreURL()
    }
    
    // MARK: -
    
    public init(managedObjectModelBundle: Bundle, managedObjectModelName: String, bundleIdentifier: String) throws {
        self.managedObjectModelURL = try managedObjectModelBundle.managedObjectModelURL(for: managedObjectModelName)
        self.persistentStoreURL = try managedObjectModelBundle.persistentStoreURL(for: managedObjectModelName, bundleIdentifier: bundleIdentifier)
    }
    
    /// Initializes ContextOptions with properties filled for use by main app and its extensions.
    ///
    /// - parameter managedObjectModelBundle:   The managed object model bundle. You can use `NSBundle(forClass: MyModule.MyDataContext.self)`, for example.
    /// - parameter managedObjectModelName:     The managed object model name without the extension. Example: `"MyGreatApp"`.
    /// - parameter bundleIdentifier:           The bundle identifier for use when creating the directory for the persisent store. Example: `"com.mycompany.MyGreatApp"`.
    /// - parameter applicationGroupIdentifier: The application group identifier (see Xcode target settings). Example: `"group.com.mycompany.MyGreatApp"` for iOS or `"12ABCD3EF4.com.mycompany.MyGreatApp"` for OS X where `12ABCD3EF4` is your team identifier.
    ///
    /// - returns: An initialized ContextOptions with properties filled for use by main app and its extensions.
    public init(managedObjectModelBundle: Bundle, managedObjectModelName: String, bundleIdentifier: String, applicationGroupIdentifier: String) throws {
        self.managedObjectModelURL = try managedObjectModelBundle.managedObjectModelURL(for: managedObjectModelName)
        self.persistentStoreURL = try managedObjectModelBundle.persistentStoreURL(for: managedObjectModelName, bundleIdentifier: bundleIdentifier, applicationGroupIdentifier: applicationGroupIdentifier)
    }
    
}

// MARK: - Ubiquity (iCloud) helpers

extension DataContextOptions {
    
    #if os(OSX) || os(iOS)
    
    public var ubiquityEnabled: Bool {
        return self.persistentStoreType == .disk && self.persistentStoreOptions[NSPersistentStoreUbiquitousContainerIdentifierKey] != nil
    }
    
    public mutating func configureUbiquity(with containerIdentifier: String, contentRelativePath: String = "Data/TransactionLogs", contentName: String = "UbiquityStore") {
        self.persistentStoreOptions[NSPersistentStoreUbiquitousContainerIdentifierKey] = containerIdentifier
        self.persistentStoreOptions[NSPersistentStoreUbiquitousContentURLKey] = contentRelativePath
        self.persistentStoreOptions[NSPersistentStoreUbiquitousContentNameKey] = contentName
        
        self.persistentStoreOptions[NSMigratePersistentStoresAutomaticallyOption] = true
        self.persistentStoreOptions[NSInferMappingModelAutomaticallyOption] = true
    }
    
    #endif
}


// MARK: - private NSBundle extensions

extension Bundle {
    
    /// This variable is used to guess a managedObjectModelName.
    fileprivate var inferredManagedObjectModelName: String? {
        return self.bundleIdentifier?.components(separatedBy: ".").last
    }
    
}

extension Bundle {
    
    fileprivate func defaultManagedObjectModelURL() throws -> URL {
        guard let managedObjectModelName = self.inferredManagedObjectModelName else {
            throw AlecrimCoreDataError.invalidManagedObjectModelURL
        }
        
        return try self.managedObjectModelURL(for: managedObjectModelName)
    }
    
    fileprivate func defaultPersistentStoreURL() throws -> URL {
        guard let managedObjectModelName = self.inferredManagedObjectModelName, let bundleIdentifier = self.bundleIdentifier else {
            throw AlecrimCoreDataError.invalidPersistentStoreURL
        }
        
        return try self.persistentStoreURL(for: managedObjectModelName, bundleIdentifier: bundleIdentifier)
    }
    
}

extension Bundle {
    
    fileprivate func managedObjectModelURL(for managedObjectModelName: String) throws -> URL {
        guard let url = self.url(forResource: managedObjectModelName, withExtension: "momd") else {
            throw AlecrimCoreDataError.invalidManagedObjectModelURL
        }
        
        return url
    }
    
    fileprivate func persistentStoreURL(for managedObjectModelName: String, bundleIdentifier: String) throws -> URL {
        guard let applicationSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last else {
            throw AlecrimCoreDataError.invalidPersistentStoreURL
        }
        
        let url = applicationSupportURL
            .appendingPathComponent(bundleIdentifier, isDirectory: true)
            .appendingPathComponent("CoreData", isDirectory: true)
            .appendingPathComponent((managedObjectModelName as NSString).appendingPathExtension("sqlite")!, isDirectory: false)
        
        return url
    }
    
    fileprivate func persistentStoreURL(for managedObjectModelName: String, bundleIdentifier: String, applicationGroupIdentifier: String) throws -> URL {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: applicationGroupIdentifier) else {
            throw AlecrimCoreDataError.invalidPersistentStoreURL
        }
        
        let url = containerURL
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent(bundleIdentifier, isDirectory: true)
            .appendingPathComponent("CoreData", isDirectory: true)
            .appendingPathComponent((managedObjectModelName as NSString).appendingPathExtension("sqlite")!, isDirectory: false)
        
        return url
    }
    
}
