import Foundation

public final class AppDependencies: Sendable {
    internal protocol Factory {}

    internal struct TypedFactory<T>: Factory {
        internal let factory: @Sendable (AppDependencies) -> T
    }

    internal struct FactoryKey: Hashable {
        internal let key: StaticString

        internal init(from key: StaticString) {
            self.key = key
        }

        internal func hash(into hasher: inout Hasher) {
            if key.hasPointerRepresentation {
                hasher.combine(bytes: UnsafeRawBufferPointer(
                    start: key.utf8Start,
                    count: key.utf8CodeUnitCount
                ))
            } else {
                hasher.combine(key.unicodeScalar.value)
            }
        }

        internal static func == (lhs: Self, rhs: Self) -> Bool {
            guard lhs.key.hasPointerRepresentation == rhs.key.hasPointerRepresentation else {
                return false
            }

            if lhs.key.hasPointerRepresentation {
                return lhs.key.utf8Start == rhs.key.utf8Start || strcmp(lhs.key.utf8Start, rhs.key.utf8Start) == 0
            } else {
                return lhs.key.unicodeScalar.value == rhs.key.unicodeScalar.value
            }
        }
    }

    public struct Registration<T> {
        public enum Lifetime {
            case unique
            case singleton
        }

        private let appDependencies: AppDependencies
        private let key: FactoryKey
        private let factory: @Sendable (AppDependencies) -> T

        private var lifetime: Lifetime = .singleton

        public init(
            _ appDependencies: AppDependencies,
            key: StaticString = #function,
            _ factory: @escaping @Sendable (AppDependencies) -> T
        ) {
            self.appDependencies = appDependencies
            self.key = FactoryKey(from: key)
            self.factory = factory
        }

        public func callAsFunction() -> T {
            appDependencies.resolve(T.self, for: key, with: factory, and: lifetime)
        }

        public func use(_ factory: @escaping @Sendable (AppDependencies) -> T) {
            appDependencies.use(factory, for: key)
        }

        public func clear() {
            appDependencies.clear(for: key)
        }

        public func reset() {
            appDependencies.reset(for: key)
        }

        public var unique: Self {
            var copy = self
            copy.lifetime = .unique
            return copy
        }

        public var singleton: Self {
            var copy = self
            copy.lifetime = .singleton
            return copy
        }
    }

    private static let global = AppDependencies()

    @TaskLocal private static var local: AppDependencies?

    public static var shared: AppDependencies {
        if let local {
            return local
        } else {
            return global
        }
    }

    private let lock = NSRecursiveLock()

    nonisolated(unsafe) private var cache: [FactoryKey: Any]
    nonisolated(unsafe) private var factories: [FactoryKey: any Factory]
    nonisolated(unsafe) private var dependenciesGraph: [FactoryKey: Set<FactoryKey>] = [:]
    nonisolated(unsafe) private var resolving: [FactoryKey] = []

    internal init(
        cache: [FactoryKey: Any] = [:],
        factories: [FactoryKey: any Factory] = [:],
        dependenciesGraph: [FactoryKey: Set<FactoryKey>] = [:]
    ) {
        self.cache = cache
        self.factories = factories
        self.dependenciesGraph = dependenciesGraph
    }

    internal func makeCopyOfState() -> (
        cache: [FactoryKey: Any],
        factories: [FactoryKey: any Factory],
        dependenciesGraph: [FactoryKey: Set<FactoryKey>]
    ) {
        lock.withLock {
            let cacheCopy = self.cache.merging([:], uniquingKeysWith: { current, _ in current })
            let factoriesCopy = self.factories.merging([:], uniquingKeysWith: { current, _ in current })
            let dependenciesGraphCopy = self.dependenciesGraph.merging([:], uniquingKeysWith: { current, _ in current })
            return (cache: cacheCopy, factories: factoriesCopy, dependenciesGraph: dependenciesGraphCopy)
        }
    }

    internal func invalidateDependencies(on key: FactoryKey) {
        lock.withLock {
            self.dependenciesGraph[key]?.forEach { dependentKey in
                self.cache[dependentKey] = nil
                self.invalidateDependencies(on: dependentKey)
            }
        }
    }

    internal func clear(for key: FactoryKey) {
        lock.withLock {
            self.cache[key] = nil
            self.invalidateDependencies(on: key)
        }
    }

    internal func reset(for key: FactoryKey) {
        lock.withLock {
            self.cache[key] = nil
            self.factories[key] = nil
            self.invalidateDependencies(on: key)
        }
    }

    internal func use<T>(
        _ factory: @escaping @Sendable (AppDependencies) -> T,
        for key: FactoryKey
    ) {
        lock.withLock {
            self.cache[key] = nil
            self.factories[key] = TypedFactory(factory: factory)
            self.invalidateDependencies(on: key)
        }
    }

    internal func resolve<T>(
        _: T.Type = T.self,
        for key: FactoryKey,
        with factory: @escaping @Sendable (AppDependencies) -> T,
        and lifetime: Registration<T>.Lifetime
    ) -> T {
        lock.withLock {
            if self.resolving.contains(key) {
                fatalError("Circular dependency detected for \(key.key)")
            }

            if let currentlyResolving = self.resolving.last {
                var dependentKeys = self.dependenciesGraph[key] ?? []
                dependentKeys.insert(currentlyResolving)
                self.dependenciesGraph[key] = dependentKeys
            }

            self.resolving.append(key)
            defer { self.resolving.removeLast() }

            if let cached = self.cache[key] as? T {
                return cached
            }

            let factory = self.factories[key] as? TypedFactory<T> ?? TypedFactory(factory: factory)

            let resolved = factory.factory(self)

            switch lifetime {
            case .unique:
                break

            case .singleton:
                self.cache[key] = resolved
            }

            return resolved
        }
    }
}

// MARK: Public Interface

public extension AppDependencies {
    func clear() {
        lock.withLock {
            self.cache.removeAll(keepingCapacity: true)
            self.dependenciesGraph.removeAll(keepingCapacity: true)
        }
    }

    func reset() {
        lock.withLock {
            self.cache.removeAll(keepingCapacity: true)
            self.factories.removeAll(keepingCapacity: true)
            self.dependenciesGraph.removeAll(keepingCapacity: true)
        }
    }

    static func scoped<T>(_ operation: (AppDependencies) throws -> T) rethrows -> T {
        let copy = shared.makeCopyOfState()
        let appDependencies = AppDependencies(
            cache: copy.cache,
            factories: copy.factories,
            dependenciesGraph: copy.dependenciesGraph
        )
        return try $local.withValue(appDependencies) {
            try operation(.shared)
        }
    }

    static func scoped<T>(_ operation: @Sendable (AppDependencies) async throws -> T) async rethrows -> T {
        let copy = shared.makeCopyOfState()
        let appDependencies = AppDependencies(
            cache: copy.cache,
            factories: copy.factories,
            dependenciesGraph: copy.dependenciesGraph
        )
        return try await $local.withValue(appDependencies) {
            try await operation(.shared)
        }
    }
}
