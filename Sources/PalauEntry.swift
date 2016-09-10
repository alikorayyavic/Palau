//
//  PalauEntry.swift
//  Palau
//
//  Created by symentis GmbH on 05.05.16.
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

func pure<T>(t: T) -> T { return t }

// ----------------------------------------------------------------------------------------------
// MARK: - PalauEntryBase
// ----------------------------------------------------------------------------------------------

public protocol PalauEntryBase {

  associatedtype StrategyType: PalauStrategy

  var strategy: StrategyType { get }
  var key: String { get }
  var defaults: NSUD { get }

}

// ----------------------------------------------------------------------------------------------
// MARK: - PalauEntry
// ----------------------------------------------------------------------------------------------

public struct PalauEntry<Strategy>: PalauEntryBase
  where
  Strategy: PalauStrategy,
  Strategy.QuantifierType.DefaultableType: PalauDefaultable {

  public typealias EntryType = Strategy.ReturnType
  public typealias EnsureFunction = (EntryType) -> EntryType
  public typealias DidSetFunction = (EntryType, EntryType) -> ()

  public let strategy: Strategy
  public let key: String
  public let defaults: NSUD

  public func clear() {
    defaults.removeObject(forKey: key)
  }
}

// ----------------------------------------------------------------------------------------------------
// MARK: - Optional Single
// ----------------------------------------------------------------------------------------------------

public extension PalauEntry
  where
  Strategy: PalauStrategyOptional,
  Strategy.ReturnType == Strategy.QuantifierType.ReturnType?,
  Strategy.QuantifierType: PalauQuantifierSingle,
  Strategy.QuantifierType.ReturnType == Strategy.QuantifierType.DefaultableType,
  Strategy.QuantifierType.DefaultableType == Strategy.QuantifierType.DefaultableType.StoredType {

  public init(key: String, defaults: UserDefaults, didSet: DidSetFunction? = nil, ensure: @escaping EnsureFunction = pure) {
    self.key = key
    self.defaults = defaults
    if let didSet = didSet {
      self.strategy = Strategy(for: Strategy.QuantifierType.self, fallback: { nil }, ensure: ensure, didSet: didSet)
    } else {
      self.strategy = Strategy(for: Strategy.QuantifierType.self, fallback: { nil }, ensure: ensure)
    }
  }

  public func ensure(when: @escaping (EntryType) -> Bool, use defaultValue: EntryType) -> PalauEntry {
    return PalauEntry(key: key, defaults: defaults, didSet: strategy.didSet) { value in
      let value = self.strategy.ensure(value)
      return when(value) ? defaultValue : value
    }
  }

  public func didSet(_ callback: @escaping DidSetFunction) -> PalauEntry {
    return PalauEntry(key: key, defaults: defaults, didSet: callback, ensure: strategy.ensure)
  }

  public func withDidSet(_ changeValue: () -> Void) {
    let callback: (() -> Void)?
    if let didSet = strategy.didSet {
      let old = value
      callback = { didSet(self.value, old) }
    } else {
      callback = nil
    }
    changeValue()
    callback?()
  }

  public var value: EntryType {
    get {
      return strategy.resolve(Strategy.QuantifierType.DefaultableType.get(key, from: defaults))
    }
    set {
      Strategy.QuantifierType.DefaultableType.set(strategy.resolve(newValue), forKey: key, in: defaults)
    }
  }

}

// ----------------------------------------------------------------------------------------------------
// MARK: - Optional List
// ----------------------------------------------------------------------------------------------------

public extension PalauEntry
  where
  Strategy: PalauStrategyOptional,
  Strategy.QuantifierType: PalauQuantifierList,
  Strategy.ReturnType == Strategy.QuantifierType.ReturnType?,
  Strategy.QuantifierType.ReturnType == [Strategy.QuantifierType.DefaultableType],
  Strategy.QuantifierType.DefaultableType == Strategy.QuantifierType.DefaultableType.StoredType {

  public init(key: String, defaults: UserDefaults, didSet: DidSetFunction? = nil, ensure: @escaping EnsureFunction = pure) {
    self.key = key
    self.defaults = defaults
    if let didSet = didSet {
      self.strategy = Strategy(for: Strategy.QuantifierType.self, fallback: { nil }, ensure: ensure, didSet: didSet)
    } else {
      self.strategy = Strategy(for: Strategy.QuantifierType.self, fallback: { nil }, ensure: ensure)
    }
  }

  public func ensure(when: @escaping (EntryType) -> Bool, use defaultValue: EntryType) -> PalauEntry {
    return PalauEntry(key: key, defaults: defaults, didSet: strategy.didSet) { value in
      let value = self.strategy.ensure(value)
      return when(value) ? defaultValue : value
    }
  }

  public func didSet(_ callback: @escaping DidSetFunction) -> PalauEntry {
    return PalauEntry(key: key, defaults: defaults, didSet: callback, ensure: strategy.ensure)
  }

  public func withDidSet(_ changeValue: () -> Void) {
    let callback: (() -> Void)?
    if let didSet = strategy.didSet {
      let old = value
      callback = { didSet(self.value, old) }
    } else {
      callback = nil
    }
    changeValue()
    callback?()
  }

  public var value: EntryType {
    get {
      return strategy.resolve(Strategy.QuantifierType.DefaultableType.get(key, from: defaults))
    }
    set {
      Strategy.QuantifierType.DefaultableType.set(strategy.resolve(newValue), forKey: key, in: defaults)
    }
  }

}

// ----------------------------------------------------------------------------------------------------
// MARK: - Ensured Single
// ----------------------------------------------------------------------------------------------------

public extension PalauEntry
  where
  Strategy: PalauStrategyEnsured,
  Strategy.QuantifierType: PalauQuantifierSingle,
  Strategy.ReturnType == Strategy.QuantifierType.ReturnType,
  Strategy.QuantifierType.ReturnType == Strategy.QuantifierType.DefaultableType,
  Strategy.QuantifierType.DefaultableType == Strategy.QuantifierType.DefaultableType.StoredType {

  public init(key: String, defaults: UserDefaults, didSet: DidSetFunction? = nil, fallback: @autoclosure @escaping () -> EntryType, ensure: @escaping EnsureFunction = pure) {
    self.key = key
    self.defaults = defaults
    if let didSet = didSet {
      self.strategy = Strategy(for: Strategy.QuantifierType.self, fallback: { fallback() }, ensure: ensure, didSet: didSet)
    } else {
      self.strategy = Strategy(for: Strategy.QuantifierType.self, fallback: { fallback() }, ensure: ensure)
    }
  }

  public func ensure(when: @escaping (EntryType) -> Bool, use defaultValue: EntryType) -> PalauEntry {
    return PalauEntry(key: key, defaults: defaults, didSet: strategy.didSet, fallback: self.strategy.fallback()) { value in
      let value = self.strategy.ensure(value)
      return when(value) ? defaultValue : self.strategy.fallback()
    }
  }

  public func didSet(_ callback: @escaping DidSetFunction) -> PalauEntry {
    return PalauEntry(key: key, defaults: defaults, didSet: callback, fallback: self.strategy.fallback(), ensure: strategy.ensure)
  }

  public func withDidSet(_ changeValue: () -> Void) {
    let callback: (() -> Void)?
    if let didSet = strategy.didSet {
      let old = value
      callback = { didSet(self.value, old) }
    } else {
      callback = nil
    }
    changeValue()
    callback?()
  }

  public var value: EntryType {
    get {
      return strategy.resolve(Strategy.QuantifierType.DefaultableType.get(key, from: defaults))
    }
    set {
      Strategy.QuantifierType.DefaultableType.set(strategy.resolve(newValue), forKey: key, in: defaults)
    }
  }

}

// ----------------------------------------------------------------------------------------------------
// MARK: - Ensured List
// ----------------------------------------------------------------------------------------------------

public extension PalauEntry
  where
  Strategy: PalauStrategyEnsured,
  Strategy.QuantifierType: PalauQuantifierList,
  Strategy.ReturnType == Strategy.QuantifierType.ReturnType,
  Strategy.QuantifierType.ReturnType == [Strategy.QuantifierType.DefaultableType],
  Strategy.QuantifierType.DefaultableType == Strategy.QuantifierType.DefaultableType.StoredType {

  public init(key: String, defaults: UserDefaults, didSet: DidSetFunction? = nil, fallback: @autoclosure @escaping () -> EntryType, ensure: @escaping EnsureFunction = pure) {
    self.key = key
    self.defaults = defaults
    if let didSet = didSet {
      self.strategy = Strategy(for: Strategy.QuantifierType.self, fallback: { fallback() }, ensure: ensure, didSet: didSet)
    } else {
      self.strategy = Strategy(for: Strategy.QuantifierType.self, fallback: { fallback() }, ensure: ensure)
    }
  }

  public func ensure(when: @escaping (EntryType) -> Bool, use defaultValue: EntryType) -> PalauEntry {
    return PalauEntry(key: key, defaults: defaults, didSet: strategy.didSet, fallback: self.strategy.fallback()) { value in
      let value = self.strategy.ensure(value)
      return when(value) ? defaultValue : self.strategy.fallback()
    }
  }


  public func didSet(_ callback: @escaping DidSetFunction) -> PalauEntry {
    return PalauEntry(key: key, defaults: defaults, didSet: callback, fallback: self.strategy.fallback(), ensure: strategy.ensure)
  }

  public func withDidSet(_ changeValue: () -> Void) {
    let callback: (() -> Void)?
    if let didSet = strategy.didSet {
      let old = value
      callback = { didSet(self.value, old) }
    } else {
      callback = nil
    }
    changeValue()
    callback?()
  }

  public var value: EntryType {
    get {
      return strategy.resolve(Strategy.QuantifierType.DefaultableType.get(key, from: defaults))
    }
    set {
      Strategy.QuantifierType.DefaultableType.set(strategy.resolve(newValue), forKey: key, in: defaults)
    }
  }

}

// ----------------------------------------------------------------------------------------------------
// MARK: - PalauDefaults
// ----------------------------------------------------------------------------------------------------

public typealias PalauDefaultsEntry<T: PalauDefaultable> = PalauEntry<PalauOptional<PalauSingle<T>>>
public typealias PalauDefaultsEntryEnsured<T: PalauDefaultable> = PalauEntry<PalauEnsured<PalauSingle<T>>>
public typealias PalauDefaultsArrayEntry<T: PalauDefaultable> = PalauEntry<PalauOptional<PalauList<T>>>
public typealias PalauDefaultsArrayEntryEnsured<T: PalauDefaultable> = PalauEntry<PalauEnsured<PalauList<T>>>

/// PalauDefaults
///
/// PalauDefaults wrap the NSUserDefaults
/// The easiest usage is:
/// - extension on PalauDefaults with:
/// ```
///   public static var name: PalauDefaultsEntry<String> {
///   get { return value("name") }
///   set { }
/// }
/// ```
public struct PalauDefaults {

  /// The underlying defaults
  public static var defaults: NSUD {
    return NSUD.standard
  }

  public static func value<T>(_ key: String) -> PalauDefaultsEntry<T>
    where T: PalauDefaultable, T.StoredType == T {
      return PalauEntry(key:key, defaults:defaults)
  }

  public static func value<T>(_ key: String, whenNil fallback: @autoclosure @escaping () -> T) -> PalauDefaultsEntryEnsured<T>
    where T: PalauDefaultable, T.StoredType == T {
      return PalauEntry(key:key, defaults:defaults, fallback: fallback())
  }

  public static func value<T>(_ key: String) -> PalauDefaultsArrayEntry<T>
    where T: PalauDefaultable, T.StoredType == T {
      return PalauEntry(key:key, defaults:defaults)
  }

  public static func value<T>(_ key: String, whenNil fallback: @autoclosure @escaping () -> [T]) -> PalauDefaultsArrayEntryEnsured<T>
    where T: PalauDefaultable, T.StoredType == T {
      return PalauEntry(key:key, defaults:defaults, fallback: fallback())
  }
}
