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
                hasher.combine(bytes: UnsafeRawBufferPointer(start: key.utf8Start, count: key.utf8CodeUnitCount))
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
        private let appEnvironment: AppDependencies
        private let key: FactoryKey
        private let factory: @Sendable (AppDependencies) -> T

        public init(
            _ appEnvironment: AppDependencies,
            key: StaticString = #function,
            _ factory: @escaping @Sendable (AppDependencies) -> T
        ) {
            self.appEnvironment = appEnvironment
            self.key = FactoryKey(from: key)
            self.factory = factory
        }

        public func callAsFunction() -> T {
            appEnvironment.resolve(T.self, for: key, with: factory)
        }

        public func use(_ factory: @escaping @Sendable (AppDependencies) -> T) {
            appEnvironment.use(factory, for: key)
        }

        public func clear() {
            appEnvironment.clear(for: key)
        }

        public func reset() {
            appEnvironment.reset(for: key)
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

    nonisolated(unsafe) internal var cache: [FactoryKey: Any]
    nonisolated(unsafe) internal var factories: [FactoryKey: any Factory]
    nonisolated(unsafe) internal var resolving: Set<FactoryKey> = []

    internal init(
        cache: [FactoryKey: Any] = [:],
        factories: [FactoryKey: any Factory] = [:]
    ) {
        self.cache = cache
        self.factories = factories
    }

    internal func makeCopyOfCacheAndFactories() -> (cache: [FactoryKey: Any], factories: [FactoryKey: any Factory]) {
        lock.withLock {
            let cacheCopy = self.cache.merging([:], uniquingKeysWith: { current, _ in current })
            let factoriesCopy = self.factories.merging([:], uniquingKeysWith: { current, _ in current })
            return (cache: cacheCopy, factories: factoriesCopy)
        }
    }

    internal func clear(for key: FactoryKey) {
        lock.withLock {
            cache[key] = nil
        }
    }

    internal func reset(for key: FactoryKey) {
        lock.withLock {
            factories[key] = nil
            cache[key] = nil
        }
    }

    internal func use<T>(
        _ factory: @escaping @Sendable (AppDependencies) -> T,
        for key: FactoryKey
    ) {
        lock.withLock {
            factories[key] = TypedFactory(factory: factory)
            cache[key] = nil
        }
    }

    internal func resolve<T>(
        _: T.Type = T.self,
        for key: FactoryKey,
        with factory: @escaping @Sendable (AppDependencies) -> T
    ) -> T {
        lock.withLock {
            if let cached = cache[key] as? T {
                return cached
            }

            let factory = factories[key] as? TypedFactory<T> ?? TypedFactory(factory: factory)

            if resolving.contains(key) {
                fatalError("Circular dependency detected for \(key)")
            }

            resolving.insert(key)
            let resolved = factory.factory(self)
            resolving.remove(key)

            cache[key] = resolved

            return resolved
        }
    }

    public func clear() {
        lock.withLock {
            cache.removeAll(keepingCapacity: true)
        }
    }

    public func reset() {
        lock.withLock {
            cache.removeAll(keepingCapacity: true)
            factories.removeAll(keepingCapacity: true)
        }
    }

    public static func scoped<T>(_ operation: (AppDependencies) throws -> T) rethrows -> T {
        let copy = shared.makeCopyOfCacheAndFactories()
        let appDependencies = AppDependencies(
            cache: copy.cache,
            factories: copy.factories
        )
        return try $local.withValue(appDependencies) {
            try operation(AppDependencies.shared)
        }
    }

    public static func scoped<T>(_ operation: @Sendable (AppDependencies) async throws -> T) async rethrows -> T {
        let copy = shared.makeCopyOfCacheAndFactories()
        let appDependencies = AppDependencies(
            cache: copy.cache,
            factories: copy.factories
        )
        return try await $local.withValue(appDependencies) {
            try await operation(AppDependencies.shared)
        }
    }
}
