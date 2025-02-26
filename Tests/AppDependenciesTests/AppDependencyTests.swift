import Testing

@testable import AppDependencies

fileprivate protocol DependencyOneProtocol {}
fileprivate protocol DependencyTwoProtocol {}
fileprivate protocol DependencyThreeProtocol {
    var dependencyOne: any DependencyOneProtocol { get }
    var dependencyTwo: any DependencyTwoProtocol { get }
}
fileprivate protocol DependencyFourProtocol {
    var dependencyFive: any DependencyFiveProtocol { get }
}
fileprivate protocol DependencyFiveProtocol {
    var dependencyFour: any DependencyFourProtocol { get }
}
fileprivate protocol DependencySixProtocol {
    var dependencyOne: any DependencyOneProtocol { get }
    var dependencyTwo: any DependencyTwoProtocol { get }
    var dependencyThree: any DependencyThreeProtocol { get }
}

fileprivate struct DependencyOneVariantOne: DependencyOneProtocol {}
fileprivate struct DependencyOneVariantTwo: DependencyOneProtocol {}

fileprivate struct DependencyTwoVariantOne: DependencyTwoProtocol {}
fileprivate struct DependencyTwoVariantTwo: DependencyTwoProtocol {}

fileprivate struct DependencyThree: DependencyThreeProtocol {
    let dependencyOne: any DependencyOneProtocol
    let dependencyTwo: any DependencyTwoProtocol
}

fileprivate struct DependencyFour: DependencyFourProtocol {
    let dependencyFive: any DependencyFiveProtocol
}

fileprivate struct DependencyFive: DependencyFiveProtocol {
    let dependencyFour: any DependencyFourProtocol
}

fileprivate struct DependencySix: DependencySixProtocol {
    let dependencyOne: any DependencyOneProtocol
    let dependencyTwo: any DependencyTwoProtocol
    let dependencyThree: any DependencyThreeProtocol
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
        Registration(self) {
            DependencyThree(
                dependencyOne: $0.dependencyOne(),
                dependencyTwo: $0.dependencyTwo()
            )
        }
    }

    var dependencyFour: Registration<DependencyFourProtocol> {
        Registration(self) {
            DependencyFour(
                dependencyFive: $0.dependencyFive()
            )
        }
    }

    var dependencyFive: Registration<DependencyFiveProtocol> {
        Registration(self) {
            DependencyFive(
                dependencyFour: $0.dependencyFour()
            )
        }
    }

    var dependencySix: Registration<DependencySixProtocol> {
        Registration(self) {
            DependencySix(
                dependencyOne: $0.dependencyOne(),
                dependencyTwo: $0.dependencyTwo(),
                dependencyThree: $0.dependencyThree()
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

        model = Model()

        #expect(model.dependencyOne is DependencyOneVariantTwo)
        #expect(model.dependencyTwo is DependencyTwoVariantTwo)
        #expect(model.dependencyThree.dependencyOne is DependencyOneVariantTwo)
        #expect(model.dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
    }

    @MainActor
    @Test func test_mainActorBoundRegisterAndResolveSingleWithMultipleDependencies() async throws {
        struct Model {
            @AppDependency(\.dependencySix) var dependencySix
        }

        AppDependencies.shared.dependencyOne.use { _ in
            DependencyOneVariantOne()
        }

        AppDependencies.shared.dependencyTwo.use { _ in
            DependencyTwoVariantOne()
        }

        var model = Model()

        #expect(model.dependencySix.dependencyOne is DependencyOneVariantOne)
        #expect(model.dependencySix.dependencyTwo is DependencyTwoVariantOne)
        #expect(model.dependencySix.dependencyThree is DependencyThree)
        #expect(model.dependencySix.dependencyThree.dependencyOne is DependencyOneVariantOne)
        #expect(model.dependencySix.dependencyThree.dependencyTwo is DependencyTwoVariantOne)

        AppDependencies.shared.dependencyOne.use { _ in
            DependencyOneVariantTwo()
        }

        AppDependencies.shared.dependencyTwo.use { _ in
            DependencyTwoVariantTwo()
        }

        model = Model()

        #expect(model.dependencySix.dependencyOne is DependencyOneVariantTwo)
        #expect(model.dependencySix.dependencyTwo is DependencyTwoVariantTwo)
        #expect(model.dependencySix.dependencyThree is DependencyThree)
        #expect(model.dependencySix.dependencyThree.dependencyOne is DependencyOneVariantTwo)
        #expect(model.dependencySix.dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
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

    @Test func test_scopedRegisterAndResolveSingleWithMultipleDependencies() async throws {
        struct Model {
            @AppDependency(\.dependencySix) var dependencySix
        }

        AppDependencies.scoped {
            $0.dependencyOne.use { _ in
                DependencyOneVariantOne()
            }

            $0.dependencyTwo.use { _ in
                DependencyTwoVariantOne()
            }

            var model = Model()

            #expect(model.dependencySix.dependencyOne is DependencyOneVariantOne)
            #expect(model.dependencySix.dependencyTwo is DependencyTwoVariantOne)
            #expect(model.dependencySix.dependencyThree is DependencyThree)
            #expect(model.dependencySix.dependencyThree.dependencyOne is DependencyOneVariantOne)
            #expect(model.dependencySix.dependencyThree.dependencyTwo is DependencyTwoVariantOne)

            $0.dependencyOne.use { _ in
                DependencyOneVariantTwo()
            }

            $0.dependencyTwo.use { _ in
                DependencyTwoVariantTwo()
            }

            model = Model()

            #expect(model.dependencySix.dependencyOne is DependencyOneVariantTwo)
            #expect(model.dependencySix.dependencyTwo is DependencyTwoVariantTwo)
            #expect(model.dependencySix.dependencyThree is DependencyThree)
            #expect(model.dependencySix.dependencyThree.dependencyOne is DependencyOneVariantTwo)
            #expect(model.dependencySix.dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
        }
    }

    @Test func test_childTaskInheritScope() async throws {
        struct Model {
            @AppDependency(\.dependencyThree) var dependencyThree
        }

        try await AppDependencies.scoped {
            $0.dependencyOne.use { _ in
                DependencyOneVariantOne()
            }

            $0.dependencyTwo.use { _ in
                DependencyTwoVariantOne()
            }

            let work = {
                var model = Model()

                #expect(model.dependencyThree.dependencyOne is DependencyOneVariantOne)
                #expect(model.dependencyThree.dependencyTwo is DependencyTwoVariantOne)

                try await Task.sleep(for: .milliseconds(1))

                AppDependencies.shared.dependencyOne.use { _ in
                    DependencyOneVariantTwo()
                }

                AppDependencies.shared.dependencyTwo.use { _ in
                    DependencyTwoVariantTwo()
                }

                model = Model()

                #expect(model.dependencyThree.dependencyOne is DependencyOneVariantTwo)
                #expect(model.dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
            }

            async let child: Void = work()

            var model = Model()

            #expect(model.dependencyThree.dependencyOne is DependencyOneVariantOne)
            #expect(model.dependencyThree.dependencyTwo is DependencyTwoVariantOne)

            try await child

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
                var model = Model()

                #expect(model.dependencyThree.dependencyOne is DependencyOneVariantOne)
                #expect(model.dependencyThree.dependencyTwo is DependencyTwoVariantOne)

                AppDependencies.shared.dependencyOne.use { _ in
                    DependencyOneVariantTwo()
                }

                AppDependencies.shared.dependencyTwo.use { _ in
                    DependencyTwoVariantTwo()
                }

                model = Model()

                #expect(model.dependencyThree.dependencyOne is DependencyOneVariantTwo)
                #expect(model.dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
            }

            var model = Model()

            #expect(model.dependencyThree.dependencyOne is DependencyOneVariantOne)
            #expect(model.dependencyThree.dependencyTwo is DependencyTwoVariantOne)

            await task.value

            model = Model()

            #expect(model.dependencyThree.dependencyOne is DependencyOneVariantTwo)
            #expect(model.dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
        }
    }

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

                let model = Model()

                #expect(model.dependencyThree.dependencyOne is DependencyOneVariantTwo)
                #expect(model.dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
            }

            var model = Model()

            #expect(model.dependencyThree.dependencyOne is DependencyOneVariantOne)
            #expect(model.dependencyThree.dependencyTwo is DependencyTwoVariantOne)

            await task.value

            model = Model()

            #expect(model.dependencyThree.dependencyOne is DependencyOneVariantOne)
            #expect(model.dependencyThree.dependencyTwo is DependencyTwoVariantOne)
        }
    }

    @Test func test_multipleDetachedTaskDoNotInheritScope() async throws {
        struct Model {
            @AppDependency(\.dependencyThree) var dependencyThree
            @AppDependency(\.dependencySix) var dependencySix
        }

        let tasks = [
            Task {
                struct DependencyThreeVariantOne: DependencyThreeProtocol {
                    let dependencyOne: any DependencyOneProtocol
                    let dependencyTwo: any DependencyTwoProtocol
                }

                AppDependencies.scoped {
                    $0.dependencyOne.use { _ in
                        DependencyOneVariantOne()
                    }

                    $0.dependencyTwo.use { _ in
                        DependencyTwoVariantOne()
                    }

                    $0.dependencyThree.use {
                        DependencyThreeVariantOne(
                            dependencyOne: $0.dependencyOne(),
                            dependencyTwo: $0.dependencyTwo()
                        )
                    }

                    var model = Model()

                    #expect(model.dependencyThree is DependencyThreeVariantOne)
                    #expect(model.dependencyThree.dependencyOne is DependencyOneVariantOne)
                    #expect(model.dependencyThree.dependencyTwo is DependencyTwoVariantOne)
                    #expect(model.dependencySix.dependencyOne is DependencyOneVariantOne)
                    #expect(model.dependencySix.dependencyTwo is DependencyTwoVariantOne)
                    #expect(model.dependencySix.dependencyThree is DependencyThreeVariantOne)
                    #expect(model.dependencySix.dependencyThree.dependencyOne is DependencyOneVariantOne)
                    #expect(model.dependencySix.dependencyThree.dependencyTwo is DependencyTwoVariantOne)

                    $0.dependencyOne.use { _ in
                        DependencyOneVariantTwo()
                    }

                    $0.dependencyTwo.use { _ in
                        DependencyTwoVariantTwo()
                    }

                    model = Model()

                    #expect(model.dependencyThree is DependencyThreeVariantOne)
                    #expect(model.dependencyThree.dependencyOne is DependencyOneVariantTwo)
                    #expect(model.dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
                    #expect(model.dependencySix.dependencyOne is DependencyOneVariantTwo)
                    #expect(model.dependencySix.dependencyTwo is DependencyTwoVariantTwo)
                    #expect(model.dependencySix.dependencyThree is DependencyThreeVariantOne)
                    #expect(model.dependencySix.dependencyThree.dependencyOne is DependencyOneVariantTwo)
                    #expect(model.dependencySix.dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
                }
            },
            Task {
                struct DependencyThreeVariantTwo: DependencyThreeProtocol {
                    let dependencyOne: any DependencyOneProtocol
                    let dependencyTwo: any DependencyTwoProtocol
                }

                AppDependencies.scoped {
                    $0.dependencyOne.use { _ in
                        DependencyOneVariantOne()
                    }

                    $0.dependencyTwo.use { _ in
                        DependencyTwoVariantOne()
                    }

                    $0.dependencyThree.use {
                        DependencyThreeVariantTwo(
                            dependencyOne: $0.dependencyOne(),
                            dependencyTwo: $0.dependencyTwo()
                        )
                    }

                    var model = Model()

                    #expect(model.dependencyThree is DependencyThreeVariantTwo)
                    #expect(model.dependencyThree.dependencyOne is DependencyOneVariantOne)
                    #expect(model.dependencyThree.dependencyTwo is DependencyTwoVariantOne)
                    #expect(model.dependencySix.dependencyOne is DependencyOneVariantOne)
                    #expect(model.dependencySix.dependencyTwo is DependencyTwoVariantOne)
                    #expect(model.dependencySix.dependencyThree is DependencyThreeVariantTwo)
                    #expect(model.dependencySix.dependencyThree.dependencyOne is DependencyOneVariantOne)
                    #expect(model.dependencySix.dependencyThree.dependencyTwo is DependencyTwoVariantOne)

                    $0.dependencyOne.use { _ in
                        DependencyOneVariantTwo()
                    }

                    $0.dependencyTwo.use { _ in
                        DependencyTwoVariantTwo()
                    }

                    model = Model()

                    #expect(model.dependencyThree is DependencyThreeVariantTwo)
                    #expect(model.dependencyThree.dependencyOne is DependencyOneVariantTwo)
                    #expect(model.dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
                    #expect(model.dependencySix.dependencyOne is DependencyOneVariantTwo)
                    #expect(model.dependencySix.dependencyTwo is DependencyTwoVariantTwo)
                    #expect(model.dependencySix.dependencyThree is DependencyThreeVariantTwo)
                    #expect(model.dependencySix.dependencyThree.dependencyOne is DependencyOneVariantTwo)
                    #expect(model.dependencySix.dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
                }
            },
            Task {
                struct DependencyThreeVariantThree: DependencyThreeProtocol {
                    let dependencyOne: DependencyOneProtocol
                    let dependencyTwo: DependencyTwoProtocol
                }

                AppDependencies.scoped {
                    $0.dependencyOne.use { _ in
                        DependencyOneVariantOne()
                    }

                    $0.dependencyTwo.use { _ in
                        DependencyTwoVariantOne()
                    }

                    $0.dependencyThree.use {
                        DependencyThreeVariantThree(
                            dependencyOne: $0.dependencyOne(),
                            dependencyTwo: $0.dependencyTwo()
                        )
                    }

                    var model = Model()

                    #expect(model.dependencyThree is DependencyThreeVariantThree)
                    #expect(model.dependencyThree.dependencyOne is DependencyOneVariantOne)
                    #expect(model.dependencyThree.dependencyTwo is DependencyTwoVariantOne)
                    #expect(model.dependencySix.dependencyOne is DependencyOneVariantOne)
                    #expect(model.dependencySix.dependencyTwo is DependencyTwoVariantOne)
                    #expect(model.dependencySix.dependencyThree is DependencyThreeVariantThree)
                    #expect(model.dependencySix.dependencyThree.dependencyOne is DependencyOneVariantOne)
                    #expect(model.dependencySix.dependencyThree.dependencyTwo is DependencyTwoVariantOne)

                    $0.dependencyOne.use { _ in
                        DependencyOneVariantTwo()
                    }

                    $0.dependencyTwo.use { _ in
                        DependencyTwoVariantTwo()
                    }

                    model = Model()

                    #expect(model.dependencyThree is DependencyThreeVariantThree)
                    #expect(model.dependencyThree.dependencyOne is DependencyOneVariantTwo)
                    #expect(model.dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
                    #expect(model.dependencySix.dependencyOne is DependencyOneVariantTwo)
                    #expect(model.dependencySix.dependencyTwo is DependencyTwoVariantTwo)
                    #expect(model.dependencySix.dependencyThree is DependencyThreeVariantThree)
                    #expect(model.dependencySix.dependencyThree.dependencyOne is DependencyOneVariantTwo)
                    #expect(model.dependencySix.dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
                }
            }
        ]

        for task in tasks {
            await task.value
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
