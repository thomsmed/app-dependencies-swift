import Testing

@testable import AppDependencies

fileprivate protocol DependencyOneProtocol {}
fileprivate protocol DependencyTwoProtocol {}
fileprivate protocol DependencyThreeProtocol {
    var dependencyOne: DependencyOneProtocol { get }
    var dependencyTwo: DependencyTwoProtocol { get }
}
fileprivate protocol DependencyFourProtocol {
    var dependencyFive: DependencyFiveProtocol { get }
}
fileprivate protocol DependencyFiveProtocol {
    var dependencyFour: DependencyFourProtocol { get }
}

fileprivate struct DependencyOneVariantOne: DependencyOneProtocol {}
fileprivate struct DependencyOneVariantTwo: DependencyOneProtocol {}

fileprivate struct DependencyTwoVariantOne: DependencyTwoProtocol {}
fileprivate struct DependencyTwoVariantTwo: DependencyTwoProtocol {}

fileprivate struct DependencyThree: DependencyThreeProtocol {
    let dependencyOne: DependencyOneProtocol
    let dependencyTwo: DependencyTwoProtocol
}

fileprivate struct DependencyFour: DependencyFourProtocol {
    let dependencyFive: DependencyFiveProtocol
}

fileprivate struct DependencyFive: DependencyFiveProtocol {
    let dependencyFour: DependencyFourProtocol
}

fileprivate extension AppDependencies {
    var dependencyOne: Registration<DependencyOneProtocol> {
        Registration(self) { _ in
            DependencyOneVariantOne()
        }
    }

    var dependencyTwo: Registration<DependencyTwoProtocol> {
        Registration(self) { _ in
            DependencyTwoVariantOne()
        }
    }

    var dependencyThree: Registration<DependencyThreeProtocol> {
        Registration(self) { appEnvironment in
            DependencyThree(
                dependencyOne: appEnvironment.dependencyOne(),
                dependencyTwo: appEnvironment.dependencyTwo()
            )
        }
    }

    var dependencyFour: Registration<DependencyFourProtocol> {
        Registration(self) { appEnvironment in
            DependencyFour(
                dependencyFive: appEnvironment.dependencyFive()
            )
        }
    }

    var dependencyFive: Registration<DependencyFiveProtocol> {
        Registration(self) { appEnvironment in
            DependencyFive(
                dependencyFour: appEnvironment.dependencyFour()
            )
        }
    }
}

struct AppEnvironmentTests {
    @MainActor
    @Test func test_mainActorBoundRegisterAndResolveMultipleDependencies() async throws {
        struct Model {
            @AppDependency(\.dependencyTwo) var dependencyTwo
            @AppDependency(\.dependencyThree) var dependencyThree
            @AppDependency(\.dependencyOne) var dependencyOne
        }

        AppDependencies.shared.dependencyOne.use { _ in
            DependencyOneVariantOne()
        }

        AppDependencies.shared.dependencyTwo.use { _ in
            DependencyTwoVariantOne()
        }

        AppDependencies.shared.clear()

        var model = Model()

        #expect(model.dependencyOne is DependencyOneVariantOne)
        #expect(model.dependencyTwo is DependencyTwoVariantOne)
        #expect(model.dependencyThree.dependencyOne is DependencyOneVariantOne)
        #expect(model.dependencyThree.dependencyTwo is DependencyTwoVariantOne)

        AppDependencies.shared.dependencyOne.use { _ in
            DependencyOneVariantTwo()
        }

        AppDependencies.shared.dependencyTwo.use { _ in
            DependencyTwoVariantTwo()
        }

        AppDependencies.shared.clear()

        model = Model()

        #expect(model.dependencyOne is DependencyOneVariantTwo)
        #expect(model.dependencyTwo is DependencyTwoVariantTwo)
        #expect(model.dependencyThree.dependencyOne is DependencyOneVariantTwo)
        #expect(model.dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
    }

    @MainActor
    @Test func test_mainActorBoundScoped() {
        struct Model {
            @AppDependency(\.dependencyThree) var dependencyThree
        }

        AppDependencies.shared.dependencyOne.use { _ in
            DependencyOneVariantOne()
        }

        AppDependencies.shared.dependencyTwo.use { _ in
            DependencyTwoVariantOne()
        }

        AppDependencies.shared.dependencyThree.reset()
        var model = Model()

        #expect(model.dependencyThree.dependencyOne is DependencyOneVariantOne)
        #expect(model.dependencyThree.dependencyTwo is DependencyTwoVariantOne)

        model = AppDependencies.scoped {
            $0.dependencyOne.use { _ in
                DependencyOneVariantTwo()
            }

            $0.dependencyTwo.use { _ in
                DependencyTwoVariantTwo()
            }

            AppDependencies.shared.dependencyThree.reset()
            return Model()
        }

        #expect(model.dependencyThree.dependencyOne is DependencyOneVariantTwo)
        #expect(model.dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
    }

    @MainActor
    @Test func test_mainActorBoundRegisterAndResolve() async throws {
        struct Model {
            @AppDependency(\.dependencyOne) var dependencyOne
            @AppDependency(\.dependencyTwo) var dependencyTwo
        }

        AppDependencies.shared.dependencyOne.use { _ in
            DependencyOneVariantOne()
        }

        AppDependencies.shared.dependencyTwo.use { _ in
            DependencyTwoVariantOne()
        }

        var model = Model()

        #expect(model.dependencyOne is DependencyOneVariantOne)
        #expect(model.dependencyTwo is DependencyTwoVariantOne)

        AppDependencies.shared.dependencyOne.use { _ in
            DependencyOneVariantTwo()
        }

        AppDependencies.shared.dependencyTwo.use { _ in
            DependencyTwoVariantTwo()
        }

        model = Model()

        #expect(model.dependencyOne is DependencyOneVariantTwo)
        #expect(model.dependencyTwo is DependencyTwoVariantTwo)
    }

    @MainActor
    @Test func test_mainActorBoundScopedRegisterAndResolve() async throws {
        struct Model {
            @AppDependency(\.dependencyOne) var dependencyOne
            @AppDependency(\.dependencyTwo) var dependencyTwo
        }

        AppDependencies.shared.dependencyOne.use { _ in
            DependencyOneVariantOne()
        }

        AppDependencies.shared.dependencyTwo.use { _ in
            DependencyTwoVariantOne()
        }

        var model = Model()

        #expect(model.dependencyOne is DependencyOneVariantOne)
        #expect(model.dependencyTwo is DependencyTwoVariantOne)

        AppDependencies.scoped {
            var model = Model()

            #expect(model.dependencyOne is DependencyOneVariantOne)
            #expect(model.dependencyTwo is DependencyTwoVariantOne)

            $0.dependencyOne.use { _ in
                DependencyOneVariantTwo()
            }

            $0.dependencyTwo.use { _ in
                DependencyTwoVariantTwo()
            }

            model = Model()

            #expect(model.dependencyOne is DependencyOneVariantTwo)
            #expect(model.dependencyTwo is DependencyTwoVariantTwo)
        }

        model = Model()

        #expect(model.dependencyOne is DependencyOneVariantOne)
        #expect(model.dependencyTwo is DependencyTwoVariantOne)
    }

    @Test func test_nestedScopedRegisterAndResolve() async throws {
        struct Model {
            @AppDependency(\.dependencyOne) var dependencyOne
            @AppDependency(\.dependencyTwo) var dependencyTwo
        }

        AppDependencies.scoped {
            $0.dependencyOne.use { _ in
                DependencyOneVariantOne()
            }

            $0.dependencyTwo.use { _ in
                DependencyTwoVariantOne()
            }

            var model = Model()

            #expect(model.dependencyOne is DependencyOneVariantOne)
            #expect(model.dependencyTwo is DependencyTwoVariantOne)

            AppDependencies.scoped {
                var model = Model()

                #expect(model.dependencyOne is DependencyOneVariantOne)
                #expect(model.dependencyTwo is DependencyTwoVariantOne)

                $0.dependencyOne.use { _ in
                    DependencyOneVariantTwo()
                }

                $0.dependencyTwo.use { _ in
                    DependencyTwoVariantTwo()
                }

                model = Model()

                #expect(model.dependencyOne is DependencyOneVariantTwo)
                #expect(model.dependencyTwo is DependencyTwoVariantTwo)
            }

            model = Model()

            #expect(model.dependencyOne is DependencyOneVariantOne)
            #expect(model.dependencyTwo is DependencyTwoVariantOne)
        }
    }

    @Test func test_scopedResolveDependencies() async throws {
        struct Model {
            @AppDependency(\.dependencyThree) var dependencyThree
        }

        AppDependencies.scoped {
            $0.dependencyOne.use { _ in
                DependencyOneVariantOne()
            }

            $0.dependencyTwo.use { _ in
                DependencyTwoVariantOne()
            }

            let model = Model()

            #expect(model.dependencyThree is DependencyThree)
        }
    }

    @Test func test_childTaskInheritScope() async throws {
        struct Model {
            @AppDependency(\.dependencyThree) var dependencyThree
        }

        await AppDependencies.scoped {
            $0.dependencyOne.use { _ in
                DependencyOneVariantOne()
            }

            $0.dependencyTwo.use { _ in
                DependencyTwoVariantOne()
            }

            let work = {
                AppDependencies.shared.dependencyThree.reset()
                var model = Model()

                #expect(model.dependencyThree.dependencyOne is DependencyOneVariantOne)
                #expect(model.dependencyThree.dependencyTwo is DependencyTwoVariantOne)

                AppDependencies.shared.dependencyOne.use { _ in
                    DependencyOneVariantTwo()
                }

                AppDependencies.shared.dependencyTwo.use { _ in
                    DependencyTwoVariantTwo()
                }

                AppDependencies.shared.dependencyThree.reset()
                model = Model()

                #expect(model.dependencyThree.dependencyOne is DependencyOneVariantTwo)
                #expect(model.dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
            }

            async let child: Void = work()

            AppDependencies.shared.dependencyThree.reset()
            var model = Model()

            #expect(model.dependencyThree.dependencyOne is DependencyOneVariantOne)
            #expect(model.dependencyThree.dependencyTwo is DependencyTwoVariantOne)

            await child

            AppDependencies.shared.dependencyThree.reset()
            model = Model()

            #expect(model.dependencyThree.dependencyOne is DependencyOneVariantTwo)
            #expect(model.dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
        }
    }

    @Test func test_unstructuredTaskInheritByCopyingScope() async throws {
        struct Model {
            @AppDependency(\.dependencyThree) var dependencyThree
        }

        await AppDependencies.scoped {
            $0.dependencyOne.use { _ in
                DependencyOneVariantOne()
            }

            $0.dependencyTwo.use { _ in
                DependencyTwoVariantOne()
            }

            let task = Task {
                AppDependencies.shared.dependencyThree.reset()
                var model = Model()

                #expect(model.dependencyThree.dependencyOne is DependencyOneVariantOne)
                #expect(model.dependencyThree.dependencyTwo is DependencyTwoVariantOne)

                AppDependencies.shared.dependencyOne.use { _ in
                    DependencyOneVariantTwo()
                }

                AppDependencies.shared.dependencyTwo.use { _ in
                    DependencyTwoVariantTwo()
                }

                AppDependencies.shared.dependencyThree.reset()
                model = Model()

                #expect(model.dependencyThree.dependencyOne is DependencyOneVariantTwo)
                #expect(model.dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
            }

            AppDependencies.shared.dependencyThree.reset()
            var model = Model()

            #expect(model.dependencyThree.dependencyOne is DependencyOneVariantOne)
            #expect(model.dependencyThree.dependencyTwo is DependencyTwoVariantOne)

            await task.value

            AppDependencies.shared.dependencyThree.reset()
            model = Model()

            #expect(model.dependencyThree.dependencyOne is DependencyOneVariantTwo)
            #expect(model.dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
        }
    }

    @MainActor
    @Test func test_detachedTaskDoNotInheritScope() async throws {
        struct Model {
            @AppDependency(\.dependencyThree) var dependencyThree
        }

        await AppDependencies.scoped { @MainActor in
            $0.dependencyOne.use { _ in
                DependencyOneVariantOne()
            }

            $0.dependencyTwo.use { _ in
                DependencyTwoVariantOne()
            }

            let task = Task.detached { @MainActor in
                AppDependencies.shared.dependencyOne.use { _ in
                    DependencyOneVariantTwo()
                }

                AppDependencies.shared.dependencyTwo.use { _ in
                    DependencyTwoVariantTwo()
                }

                AppDependencies.shared.dependencyThree.reset()
                let model = Model()

                #expect(model.dependencyThree.dependencyOne is DependencyOneVariantTwo)
                #expect(model.dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
            }

            AppDependencies.shared.dependencyThree.reset()
            var model = Model()

            #expect(model.dependencyThree.dependencyOne is DependencyOneVariantOne)
            #expect(model.dependencyThree.dependencyTwo is DependencyTwoVariantOne)

            await task.value

            AppDependencies.shared.dependencyThree.reset()
            model = Model()

            #expect(model.dependencyThree.dependencyOne is DependencyOneVariantOne)
            #expect(model.dependencyThree.dependencyTwo is DependencyTwoVariantOne)
        }
    }

    @Test(.disabled("Detection of circular dependencies results in crash")) func test_scopedResolveCircularDependencies() async throws {
        struct Model {
            @AppDependency(\.dependencyFour) var dependencyFour
            @AppDependency(\.dependencyFive) var dependencyFive
        }

        AppDependencies.scoped { _ in
            let model = Model()

            #expect(model.dependencyFour is DependencyFour)
            #expect(model.dependencyFive is DependencyFive)
        }
    }
}
