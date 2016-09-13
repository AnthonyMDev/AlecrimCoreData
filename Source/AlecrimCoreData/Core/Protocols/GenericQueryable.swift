//
//  GenericQueryable.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-07-25.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

public protocol GenericQueryable: Queryable {
    
    associatedtype Item
    
    func toArray() -> [Item]

}

// MARK: - ordering

extension GenericQueryable {
    
    public func orderBy<A: AttributeProtocol, V>(ascending: Bool = true, orderingClosure: (Self.Item.Type) -> A) -> Self where A.ValueType == V {
        return self.sort(using: orderingClosure(Self.Item.self), ascending: ascending)
    }
    
}

// MARK: - filtering

extension GenericQueryable {
    
    public func filter(_ predicateClosure: (Self.Item.Type) -> NSPredicate) -> Self {
        return self.filter(using: predicateClosure(Self.Item.self))
    }
    
}

// MARK: -

extension GenericQueryable {
    
    public func count(_ predicateClosure: (Self.Item.Type) -> NSPredicate) -> Int {
        return self.filter(using: predicateClosure(Self.Item.self)).count()
    }
    
}

extension GenericQueryable {
    
    public func any(_ predicateClosure: (Self.Item.Type) -> NSPredicate) -> Bool {
        return self.filter(using: predicateClosure(Self.Item.self)).any()
    }
    
    public func none(_ predicateClosure: (Self.Item.Type) -> NSPredicate) -> Bool {
        return self.filter(using: predicateClosure(Self.Item.self)).none()
    }
    
}

extension GenericQueryable {
    
    public func first(_ predicateClosure: (Self.Item.Type) -> NSPredicate) -> Self.Item? {
        return self.filter(using: predicateClosure(Self.Item.self)).first()
    }
    
}

// MARK: - entity

extension GenericQueryable {
    
    public func first() -> Self.Item? {
        return self.take(1).toArray().first
    }
    
}


// TODO: this still crashes the compiler - Xcode 7.3.1
// MARK: - SequenceType

//extension GenericQueryable {
//    
//    public typealias Generator = AnyGenerator<Self.Item>
//    
//    public func generate() -> AnyGenerator<Self.Item> {
//        return AnyGenerator(self.toArray().generate())
//    }
//    
//}

extension Table: Sequence {

    public typealias Iterator = AnyIterator<T>

    public func makeIterator() -> Iterator {
        return AnyIterator(self.toArray().makeIterator())
    }
    
    // turns the SequenceType implementation unavailable
    @available(*, unavailable)
    public func filter(includeElement: (Table.Iterator.Element) throws -> Bool) rethrows -> [Table.Iterator.Element] {
        return []
    }
    
}

extension AttributeQuery: Sequence {
    
    public typealias Iterator = AnyIterator<T>
    
    public func makeIterator() -> Iterator {
        return AnyIterator(self.toArray().makeIterator())
    }

    // turns the SequenceType implementation unavailable
    @available(*, unavailable)
    public func filter(includeElement: (AttributeQuery.Iterator.Element) throws -> Bool) rethrows -> [AttributeQuery.Iterator.Element] {
        return []
    }

}

