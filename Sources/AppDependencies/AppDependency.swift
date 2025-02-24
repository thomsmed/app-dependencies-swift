import SwiftUI

@propertyWrapper public struct AppDependency<T> {
    public private(set) var wrappedValue: T

    public init(_ keyPath: KeyPath<AppDependencies, AppDependencies.Registration<T>>) {
        wrappedValue = AppDependencies.shared[keyPath: keyPath]()
    }
}

@propertyWrapper public struct DynamicAppDependency<T> {
    private let keyPath: KeyPath<AppDependencies, AppDependencies.Registration<T>>

    public var wrappedValue: T {
        AppDependencies.shared[keyPath: keyPath]()
    }

    public init(_ keyPath: KeyPath<AppDependencies, AppDependencies.Registration<T>>) {
        self.keyPath = keyPath
    }
}

@propertyWrapper public struct LazyAppDependency<T> {
    private let keyPath: KeyPath<AppDependencies, AppDependencies.Registration<T>>

    private var lazyWrappedValue: T?

    public var wrappedValue: T {
        mutating get {
            if let wrappedValue = lazyWrappedValue {
                return wrappedValue
            } else {
                let wrappedValue = AppDependencies.shared[keyPath: keyPath]()
                self.lazyWrappedValue = wrappedValue
                return wrappedValue
            }
        }
    }

    public init(_ keyPath: KeyPath<AppDependencies, AppDependencies.Registration<T>>) {
        self.keyPath = keyPath
    }
}

@propertyWrapper public struct WeakAppDependency<T: AnyObject> {
    private let keyPath: KeyPath<AppDependencies, AppDependencies.Registration<T>>

    private weak var weakWrappedValue: T?

    public var wrappedValue: T {
        mutating get {
            if let wrappedValue = weakWrappedValue {
                return wrappedValue
            } else {
                let wrappedValue = AppDependencies.shared[keyPath: keyPath]()
                self.weakWrappedValue = wrappedValue
                return wrappedValue
            }
        }
    }

    public init(_ keyPath: KeyPath<AppDependencies, AppDependencies.Registration<T>>) {
        self.keyPath = keyPath
        self.weakWrappedValue = AppDependencies.shared[keyPath: keyPath]()
    }
}

@propertyWrapper public struct WeakLazyAppDependency<T: AnyObject> {
    private let keyPath: KeyPath<AppDependencies, AppDependencies.Registration<T>>

    private weak var weakLazyWrappedValue: T?

    public var wrappedValue: T {
        mutating get {
            if let wrappedValue = weakLazyWrappedValue {
                return wrappedValue
            } else {
                let wrappedValue = AppDependencies.shared[keyPath: keyPath]()
                self.weakLazyWrappedValue = wrappedValue
                return wrappedValue
            }
        }
    }

    public init(_ keyPath: KeyPath<AppDependencies, AppDependencies.Registration<T>>) {
        self.keyPath = keyPath
    }
}
