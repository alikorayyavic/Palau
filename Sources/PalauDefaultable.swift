//
//  PalauDefaultable.swift
//  Palau
//
//  Created by symentis GmbH on 26.04.16.
//  Copyright © 2016 symentis GmbH. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

#if os(iOS)
  import UIKit
#endif

#if os(tvOS)
  import UIKit
#endif

#if os(watchOS)
  import WatchKit
#endif

#if os(OSX)
  import AppKit
#endif

// -------------------------------------------------------------------------------------------------
// MARK: - PalauDefaultable
// -------------------------------------------------------------------------------------------------

public typealias NSUD = UserDefaults

/// PalauDefaultable Protocol
/// Types that can be written to defaults should implement this
/// By default we provide an implementation for most of the basic types
public protocol PalauDefaultable {

  /// The associatedtype for the Value
  associatedtype StoredType = Self

  /// Static function to get an optional ValueType out of the
  /// provided NSUserDefaults with the key
  /// - param key: The key used in the NSUserDefaults
  /// - param defaults: The NSUserDefaults
  /// - returns: ValueType?
  static func get(_ key: String, from defaults: NSUD) -> StoredType?

  /// Static function to get an optional ValueType out of the
  /// provided NSUserDefaults with the key
  /// - param key: The key used in the NSUserDefaults
  /// - param defaults: The NSUserDefaults
  /// - returns: ValueType?
  static func get(_ key: String, from defaults: NSUD) -> [StoredType]?

  /// Static function to set an optional ValueType in the provided NSUserDefaults with the key
  /// - param value: The optional value to be stored
  /// - param key: The key used in the NSUserDefaults
  /// - param defaults: The NSUserDefaults
  /// - returns: Void
  static func set(_ value: StoredType?, forKey key: String, in defaults: NSUD) -> Void

  /// Static function to set an optional ValueType in the provided NSUserDefaults with the key
  /// - param value: The optional value to be stored
  /// - param key: The key used in the NSUserDefaults
  /// - param defaults: The NSUserDefaults
  /// - returns: Void
  static func set(_ value: [StoredType]?, forKey key: String, in defaults: NSUD) -> Void
}


// -------------------------------------------------------------------------------------------------
// MARK: - Extension Default
//
// The extension will provide set and get for basic types like String, Int and so forth
// -------------------------------------------------------------------------------------------------

/// Extension for basic types like Int, String and so forth
extension PalauDefaultable {

  public static func get(_ key: String, from defaults: NSUD) -> StoredType? {
    return defaults.object(forKey: key) as? StoredType
  }

  public static func get(_ key: String, from defaults: NSUD) -> [StoredType]? {
    return defaults.object(forKey: key) as? [StoredType]
  }

  public static func set(_ value: StoredType?, forKey key: String, in defaults: NSUD) -> Void {
    guard let value = value as? AnyObject else { return defaults.removeObject(forKey: key) }
    defaults.set(value, forKey: key)
  }

  public static func set(_ value: [StoredType]?, forKey key: String, in defaults: NSUD) -> Void {
    guard let value = value as? AnyObject else { return defaults.removeObject(forKey: key) }
    defaults.set(value, forKey: key)
  }
}

// -------------------------------------------------------------------------------------------------
// MARK: - RawRepresentable
//
// The extension will provide set and get for RawRepresentable
// -------------------------------------------------------------------------------------------------

/// Extension for RawRepresentable types aka enums
extension PalauDefaultable where StoredType: RawRepresentable {

  public static func get(_ key: String, from defaults: NSUD) -> StoredType? {
    guard let val = defaults.object(forKey: key) as? StoredType.RawValue else { return nil }
    return StoredType(rawValue: val)
  }

  public static func get(_ key: String, from defaults: NSUD) -> [StoredType]? {
    guard let val = defaults.object(forKey: key) as? [StoredType.RawValue] else { return nil }
    return val.flatMap { StoredType(rawValue: $0) }
  }

  public static func set(_ value: StoredType?, forKey key: String, in defaults: NSUD) -> Void {
    guard let value = value?.rawValue as? AnyObject else { return defaults.removeObject(forKey: key) }
    defaults.set(value, forKey: key)
  }

  public static func set(_ value: [StoredType]?, forKey key: String, in defaults: NSUD) -> Void {
    guard let value = value?.map({ $0.rawValue }) as? AnyObject else { return defaults.removeObject(forKey: key) }
    defaults.set(value, forKey: key)
  }
}

// -------------------------------------------------------------------------------------------------
// MARK: - NSCoding
//
// The extension will provide set and get for NSCoding types
// -------------------------------------------------------------------------------------------------

// swiftlint:disable conditional_binding_cascade
/// Extension for NSCoding types
extension PalauDefaultable where StoredType: NSCoding {

  public static func get(_ key: String, from defaults: NSUD) -> StoredType? {
    guard let data = defaults.object(forKey: key) as? Data,
          let value = NSKeyedUnarchiver.unarchiveObject(with: data) as? StoredType else { return nil }
    return value
  }

  public static func get(_ key: String, from defaults: NSUD) -> [StoredType]? {
    guard let data = defaults.object(forKey: key) as? Data,
          let value = NSKeyedUnarchiver.unarchiveObject(with: data) as? [StoredType] else { return nil }
    return value
  }

  public static func set(_ value: StoredType?, forKey key: String, in defaults: NSUD) -> Void {
    guard let value = value as? AnyObject else { return defaults.removeObject(forKey: key) }
    let data = NSKeyedArchiver.archivedData(withRootObject: value)
    defaults.set(data, forKey: key)
  }

  public static func set(_ value: [StoredType]?, forKey key: String, in defaults: NSUD) -> Void {
    guard let value = value?.flatMap({ $0 as AnyObject }) else { return defaults.removeObject(forKey: key) }
    let data = NSKeyedArchiver.archivedData(withRootObject: value)
    defaults.set(data, forKey: key)
  }
}

// -------------------------------------------------------------------------------------------------
// MARK: - Implementations
// -------------------------------------------------------------------------------------------------

//
/*
 TODO Swift 3:

 Swift 3 will probably give us extensions on generic types.
 This will make it easier for Array and Dictionary, Set
 Maybe like

 extension CollectionType<Element>: PalauDefaultable {
  public typealias StoredType = CollectionType<Element>
 }
*/

/// Make Bool PalauDefaultable
extension Bool: PalauDefaultable {
}

/// Make Int PalauDefaultable
extension Int: PalauDefaultable {
  public typealias StoredType = Int
}

/// Make UInt PalauDefaultable
extension UInt: PalauDefaultable {
  public typealias StoredType = UInt
}

/// Make Float PalauDefaultable
extension Float: PalauDefaultable {
  public typealias StoredType = Float
}

/// Make Double PalauDefaultable
extension Double: PalauDefaultable {
  public typealias StoredType = Double
}

/// Make NSNumber PalauDefaultable
extension NSNumber: PalauDefaultable {
  public typealias StoredType = NSNumber
}

/// Make String PalauDefaultable
extension String: PalauDefaultable {
  public typealias StoredType = String
}

/// Make NSString PalauDefaultable
extension NSString: PalauDefaultable {
  public typealias StoredType = NSString
}

/// Make Array PalauDefaultable
extension Array: PalauDefaultable {
  public typealias StoredType = Array
}

/// Make NSArray PalauDefaultable
extension NSArray: PalauDefaultable {
  public typealias StoredType = NSArray
}

/// Make Dictionary PalauDefaultable
extension Dictionary: PalauDefaultable {
  public typealias StoredType = Dictionary
}

/// Make NSDictionary PalauDefaultable
extension NSDictionary: PalauDefaultable {
  public typealias StoredType = NSDictionary
}

/// Make Date PalauDefaultable
extension Date: PalauDefaultable {
  public typealias StoredType = Date
}

/// Make Data PalauDefaultable
extension Data: PalauDefaultable {
  public typealias StoredType = Data
}

#if os(OSX)
  /// Make NSColor PalauDefaultable
  extension NSColor: PalauDefaultable {
    public typealias StoredType = NSColor
  }
#else
  /// Make UIColor PalauDefaultable
  extension UIColor: PalauDefaultable {
    public typealias StoredType = UIColor
  }
#endif
