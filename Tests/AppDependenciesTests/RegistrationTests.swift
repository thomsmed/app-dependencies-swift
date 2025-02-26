import Testing

@testable import AppDependencies

fileprivate class SomeDependencyBase {}

fileprivate extension AppDependencies {
    var uniqueRegisteredDependency: Registration<SomeDependencyBase> {
        Registration(self) { _ in
            SomeDependencyBase()
        }
        .unique
    }

    var singeltonRegisteredDependency: Registration<SomeDependencyBase> {
        Registration(self) { _ in
            SomeDependencyBase()
        }
        .singleton
    }
}

struct RegistrationTest {
    @Test func test_uniqueRegistration() async throws {
        final class UniqueRegisteredDependency: SomeDependencyBase {
            nonisolated(unsafe) static var count: Int = 0

            override init() {
                Self.count += 1
            }
        }

        AppDependencies.scoped {
            $0.uniqueRegisteredDependency.use { _ in
                UniqueRegisteredDependency()
            }

            #expect(UniqueRegisteredDependency.count == 0)

            #expect(AppDependencies.shared.uniqueRegisteredDependency() !== AppDependencies.shared.uniqueRegisteredDependency())
            #expect(AppDependencies.shared.uniqueRegisteredDependency() !== AppDependencies.shared.uniqueRegisteredDependency())

            #expect(UniqueRegisteredDependency.count == 4)

            #expect(AppDependencies.shared.uniqueRegisteredDependency() !== AppDependencies.shared.uniqueRegisteredDependency())
            #expect(AppDependencies.shared.uniqueRegisteredDependency() !== AppDependencies.shared.uniqueRegisteredDependency())

            #expect(UniqueRegisteredDependency.count == 8)
        }
    }

    @Test func test_singletonRegistration() async throws {
        final class SingletonRegisteredDependency: SomeDependencyBase {
            nonisolated(unsafe) static var count: Int = 0

            override init() {
                Self.count += 1
            }
        }

        AppDependencies.scoped {
            $0.singeltonRegisteredDependency.use { _ in
                SingletonRegisteredDependency()
            }

            #expect(SingletonRegisteredDependency.count == 0)

            #expect(AppDependencies.shared.singeltonRegisteredDependency() === AppDependencies.shared.singeltonRegisteredDependency())
            #expect(AppDependencies.shared.singeltonRegisteredDependency() === AppDependencies.shared.singeltonRegisteredDependency())

            #expect(SingletonRegisteredDependency.count == 1)

            #expect(AppDependencies.shared.singeltonRegisteredDependency() === AppDependencies.shared.singeltonRegisteredDependency())
            #expect(AppDependencies.shared.singeltonRegisteredDependency() === AppDependencies.shared.singeltonRegisteredDependency())

            #expect(SingletonRegisteredDependency.count == 1)
        }
    }

    @Test func test_scopeEscapingAppDependenciesWithUniqueRegistration() async throws {
        final class UniqueRegisteredDependency: SomeDependencyBase {
            nonisolated(unsafe) static var count: Int = 0

            override init() {
                Self.count += 1
            }
        }

        let appDependencies = AppDependencies.scoped {
            $0.uniqueRegisteredDependency.use { _ in
                UniqueRegisteredDependency()
            }

            return $0
        }

        #expect(UniqueRegisteredDependency.count == 0)

        #expect(appDependencies.uniqueRegisteredDependency() !== appDependencies.uniqueRegisteredDependency())
        #expect(appDependencies.uniqueRegisteredDependency() !== appDependencies.uniqueRegisteredDependency())

        #expect(UniqueRegisteredDependency.count == 4)

        #expect(appDependencies.uniqueRegisteredDependency() !== appDependencies.uniqueRegisteredDependency())
        #expect(appDependencies.uniqueRegisteredDependency() !== appDependencies.uniqueRegisteredDependency())

        #expect(UniqueRegisteredDependency.count == 8)
    }

    @Test func test_scopeEscapingAppDependenciesWithSingletonRegistration() async throws {
        final class SingletonRegisteredDependency: SomeDependencyBase {
            nonisolated(unsafe) static var count: Int = 0

            override init() {
                Self.count += 1
            }
        }

        let appDependencies = AppDependencies.scoped {
            $0.singeltonRegisteredDependency.use { _ in
                SingletonRegisteredDependency()
            }

            return $0
        }

        #expect(SingletonRegisteredDependency.count == 0)

        #expect(appDependencies.singeltonRegisteredDependency() === appDependencies.singeltonRegisteredDependency())
        #expect(appDependencies.singeltonRegisteredDependency() === appDependencies.singeltonRegisteredDependency())

        #expect(SingletonRegisteredDependency.count == 1)

        #expect(appDependencies.singeltonRegisteredDependency() === appDependencies.singeltonRegisteredDependency())
        #expect(appDependencies.singeltonRegisteredDependency() === appDependencies.singeltonRegisteredDependency())

        #expect(SingletonRegisteredDependency.count == 1)
    }
}
