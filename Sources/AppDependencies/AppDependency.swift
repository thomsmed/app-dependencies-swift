import SwiftUI

@propertyWrapper public struct AppDependency<T> {
    public private(set) var wrappedValue: T

    public init(_ keyPath: KeyPath<AppDependencies, AppDependencies.Registration<T>>) {
        wrappedValue = AppDependencies.shared[keyPath: keyPath]()
    }
}
