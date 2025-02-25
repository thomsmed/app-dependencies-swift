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
fileprivate protocol DependencySixProtocol {
    var dependencyOne: DependencyOneProtocol { get }
    var dependencyTwo: DependencyTwoProtocol { get }
    var dependencyThree: DependencyThreeProtocol { get }
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

fileprivate struct DependencySix: DependencySixProtocol {
    let dependencyOne: DependencyOneProtocol
    let dependencyTwo: DependencyTwoProtocol
    let dependencyThree: DependencyThreeProtocol
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
        Registration(self) { appDependencies in
            DependencyThree(
                dependencyOne: appDependencies.dependencyOne(),
                dependencyTwo: appDependencies.dependencyTwo()
            )
        }
    }

    var dependencyFour: Registration<DependencyFourProtocol> {
        Registration(self) { appDependencies in
            DependencyFour(
                dependencyFive: appDependencies.dependencyFive()
            )
        }
    }

    var dependencyFive: Registration<DependencyFiveProtocol> {
        Registration(self) { appDependencies in
            DependencyFive(
                dependencyFour: appDependencies.dependencyFour()
            )
        }
    }

    var dependencySix: Registration<DependencySixProtocol> {
        Registration(self) { appDependencies in
            DependencySix(
                dependencyOne: appDependencies.dependencyOne(),
                dependencyTwo: appDependencies.dependencyTwo(),
                dependencyThree: appDependencies.dependencyThree()
            )
        }
    }
}

struct AppEnvironmentValuesTests {
    @MainActor
    @Test func test_mainActorBoundRegisterAndResolveMultipleDependencies() async throws {
        AppDependencies.shared.dependencyOne.use { _ in
            DependencyOneVariantOne()
        }

        AppDependencies.shared.dependencyTwo.use { _ in
            DependencyTwoVariantOne()
        }

        AppDependencies.shared.clear()

        var dependencyOne = AppDependencies.shared.dependencyOne()
        var dependencyThree = AppDependencies.shared.dependencyThree()
        var dependencyTwo = AppDependencies.shared.dependencyTwo()

        #expect(dependencyOne is DependencyOneVariantOne)
        #expect(dependencyTwo is DependencyTwoVariantOne)
        #expect(dependencyThree.dependencyOne is DependencyOneVariantOne)
        #expect(dependencyThree.dependencyTwo is DependencyTwoVariantOne)

        AppDependencies.shared.dependencyOne.use { _ in
            DependencyOneVariantTwo()
        }

        AppDependencies.shared.dependencyTwo.use { _ in
            DependencyTwoVariantTwo()
        }

        AppDependencies.shared.clear()

        dependencyOne = AppDependencies.shared.dependencyOne()
        dependencyThree = AppDependencies.shared.dependencyThree()
        dependencyTwo = AppDependencies.shared.dependencyTwo()

        #expect(dependencyOne is DependencyOneVariantTwo)
        #expect(dependencyTwo is DependencyTwoVariantTwo)
        #expect(dependencyThree.dependencyOne is DependencyOneVariantTwo)
        #expect(dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
    }

    @MainActor
    @Test func test_mainActorBoundRegisterAndResolveSingleWithMultipleDependencies() async throws {
        AppDependencies.shared.dependencyOne.use { _ in
            DependencyOneVariantOne()
        }

        AppDependencies.shared.dependencyTwo.use { _ in
            DependencyTwoVariantOne()
        }

        AppDependencies.shared.clear()

        var dependencySix = AppDependencies.shared.dependencySix()

        #expect(dependencySix.dependencyOne is DependencyOneVariantOne)
        #expect(dependencySix.dependencyTwo is DependencyTwoVariantOne)
        #expect(dependencySix.dependencyThree is DependencyThree)
        #expect(dependencySix.dependencyThree.dependencyOne is DependencyOneVariantOne)
        #expect(dependencySix.dependencyThree.dependencyTwo is DependencyTwoVariantOne)

        AppDependencies.shared.dependencyOne.use { _ in
            DependencyOneVariantTwo()
        }

        AppDependencies.shared.dependencyTwo.use { _ in
            DependencyTwoVariantTwo()
        }

        AppDependencies.shared.clear()

        dependencySix = AppDependencies.shared.dependencySix()

        #expect(dependencySix.dependencyOne is DependencyOneVariantTwo)
        #expect(dependencySix.dependencyTwo is DependencyTwoVariantTwo)
        #expect(dependencySix.dependencyThree is DependencyThree)
        #expect(dependencySix.dependencyThree.dependencyOne is DependencyOneVariantTwo)
        #expect(dependencySix.dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
    }

    @MainActor
    @Test func test_mainActorBoundRegisterAndResolve() async throws {
        AppDependencies.shared.dependencyOne.use { _ in
            DependencyOneVariantOne()
        }

        AppDependencies.shared.dependencyTwo.use { _ in
            DependencyTwoVariantOne()
        }

        #expect(AppDependencies.shared.dependencyOne() is DependencyOneVariantOne)
        #expect(AppDependencies.shared.dependencyTwo() is DependencyTwoVariantOne)

        AppDependencies.shared.dependencyOne.use { _ in
            DependencyOneVariantTwo()
        }

        AppDependencies.shared.dependencyTwo.use { _ in
            DependencyTwoVariantTwo()
        }

        #expect(AppDependencies.shared.dependencyOne() is DependencyOneVariantTwo)
        #expect(AppDependencies.shared.dependencyTwo() is DependencyTwoVariantTwo)
    }

    @MainActor
    @Test func test_mainActorBoundScopedRegisterAndResolve() async throws {
        AppDependencies.shared.dependencyOne.use { _ in
            DependencyOneVariantOne()
        }

        AppDependencies.shared.dependencyTwo.use { _ in
            DependencyTwoVariantOne()
        }

        #expect(AppDependencies.shared.dependencyOne() is DependencyOneVariantOne)
        #expect(AppDependencies.shared.dependencyTwo() is DependencyTwoVariantOne)

        AppDependencies.scoped {
            #expect(AppDependencies.shared.dependencyOne() is DependencyOneVariantOne)
            #expect(AppDependencies.shared.dependencyTwo() is DependencyTwoVariantOne)

            $0.dependencyOne.use { _ in
                DependencyOneVariantTwo()
            }

            $0.dependencyTwo.use { _ in
                DependencyTwoVariantTwo()
            }

            #expect(AppDependencies.shared.dependencyOne() is DependencyOneVariantTwo)
            #expect(AppDependencies.shared.dependencyTwo() is DependencyTwoVariantTwo)
        }

        #expect(AppDependencies.shared.dependencyOne() is DependencyOneVariantOne)
        #expect(AppDependencies.shared.dependencyTwo() is DependencyTwoVariantOne)
    }

    @Test func test_nestedScopedRegisterAndResolve() async throws {
        AppDependencies.scoped {
            $0.dependencyOne.use { _ in
                DependencyOneVariantOne()
            }

            $0.dependencyTwo.use { _ in
                DependencyTwoVariantOne()
            }

            #expect(AppDependencies.shared.dependencyOne() is DependencyOneVariantOne)
            #expect(AppDependencies.shared.dependencyTwo() is DependencyTwoVariantOne)

            AppDependencies.scoped {
                #expect(AppDependencies.shared.dependencyOne() is DependencyOneVariantOne)
                #expect(AppDependencies.shared.dependencyTwo() is DependencyTwoVariantOne)

                $0.dependencyOne.use { _ in
                    DependencyOneVariantTwo()
                }

                $0.dependencyTwo.use { _ in
                    DependencyTwoVariantTwo()
                }

                #expect(AppDependencies.shared.dependencyOne() is DependencyOneVariantTwo)
                #expect(AppDependencies.shared.dependencyTwo() is DependencyTwoVariantTwo)
            }

            #expect(AppDependencies.shared.dependencyOne() is DependencyOneVariantOne)
            #expect(AppDependencies.shared.dependencyTwo() is DependencyTwoVariantOne)
        }
    }

    @Test func test_scopedResolveDependencies() async throws {
        AppDependencies.scoped {
            $0.dependencyOne.use { _ in
                DependencyOneVariantOne()
            }

            $0.dependencyTwo.use { _ in
                DependencyTwoVariantOne()
            }

            #expect(AppDependencies.shared.dependencyThree() is DependencyThree)
        }
    }

    @Test func test_scopedRegisterAndResolveSingleWithMultipleDependencies() async throws {
        AppDependencies.scoped {
            $0.dependencyOne.use { _ in
                DependencyOneVariantOne()
            }

            $0.dependencyTwo.use { _ in
                DependencyTwoVariantOne()
            }

            $0.clear()

            var dependencySix = AppDependencies.shared.dependencySix()

            #expect(dependencySix.dependencyOne is DependencyOneVariantOne)
            #expect(dependencySix.dependencyTwo is DependencyTwoVariantOne)
            #expect(dependencySix.dependencyThree is DependencyThree)
            #expect(dependencySix.dependencyThree.dependencyOne is DependencyOneVariantOne)
            #expect(dependencySix.dependencyThree.dependencyTwo is DependencyTwoVariantOne)

            $0.dependencyOne.use { _ in
                DependencyOneVariantTwo()
            }

            $0.dependencyTwo.use { _ in
                DependencyTwoVariantTwo()
            }

            $0.clear()

            dependencySix = AppDependencies.shared.dependencySix()

            #expect(dependencySix.dependencyOne is DependencyOneVariantTwo)
            #expect(dependencySix.dependencyTwo is DependencyTwoVariantTwo)
            #expect(dependencySix.dependencyThree is DependencyThree)
            #expect(dependencySix.dependencyThree.dependencyOne is DependencyOneVariantTwo)
            #expect(dependencySix.dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
        }
    }

    @Test func test_childTaskInheritScope() async throws {
        await AppDependencies.scoped {
            $0.dependencyOne.use { _ in
                DependencyOneVariantOne()
            }

            $0.dependencyTwo.use { _ in
                DependencyTwoVariantOne()
            }

            let work = {
                AppDependencies.shared.dependencyThree.reset()
                var dependencyThree = AppDependencies.shared.dependencyThree()

                #expect(dependencyThree.dependencyOne is DependencyOneVariantOne)
                #expect(dependencyThree.dependencyTwo is DependencyTwoVariantOne)

                AppDependencies.shared.dependencyOne.use { _ in
                    DependencyOneVariantTwo()
                }

                AppDependencies.shared.dependencyTwo.use { _ in
                    DependencyTwoVariantTwo()
                }

                AppDependencies.shared.dependencyThree.reset()
                dependencyThree = AppDependencies.shared.dependencyThree()

                #expect(dependencyThree.dependencyOne is DependencyOneVariantTwo)
                #expect(dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
            }

            async let child: Void = work()

            AppDependencies.shared.dependencyThree.reset()
            var dependencyThree = AppDependencies.shared.dependencyThree()

            #expect(dependencyThree.dependencyOne is DependencyOneVariantOne)
            #expect(dependencyThree.dependencyTwo is DependencyTwoVariantOne)

            await child

            AppDependencies.shared.dependencyThree.reset()
            dependencyThree = AppDependencies.shared.dependencyThree()

            #expect(dependencyThree.dependencyOne is DependencyOneVariantTwo)
            #expect(dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
        }
    }

    @Test func test_unstructuredTaskInheritByCopyingScope() async throws {
        await AppDependencies.scoped {
            $0.dependencyOne.use { _ in
                DependencyOneVariantOne()
            }

            $0.dependencyTwo.use { _ in
                DependencyTwoVariantOne()
            }

            let task = Task {
                AppDependencies.shared.dependencyThree.reset()
                var dependencyThree = AppDependencies.shared.dependencyThree()

                #expect(dependencyThree.dependencyOne is DependencyOneVariantOne)
                #expect(dependencyThree.dependencyTwo is DependencyTwoVariantOne)

                AppDependencies.shared.dependencyOne.use { _ in
                    DependencyOneVariantTwo()
                }

                AppDependencies.shared.dependencyTwo.use { _ in
                    DependencyTwoVariantTwo()
                }

                AppDependencies.shared.dependencyThree.reset()
                dependencyThree = AppDependencies.shared.dependencyThree()

                #expect(dependencyThree.dependencyOne is DependencyOneVariantTwo)
                #expect(dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
            }

            AppDependencies.shared.dependencyThree.reset()
            var dependencyThree = AppDependencies.shared.dependencyThree()

            #expect(dependencyThree.dependencyOne is DependencyOneVariantOne)
            #expect(dependencyThree.dependencyTwo is DependencyTwoVariantOne)

            await task.value

            AppDependencies.shared.dependencyThree.reset()
            dependencyThree = AppDependencies.shared.dependencyThree()

            #expect(dependencyThree.dependencyOne is DependencyOneVariantTwo)
            #expect(dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
        }
    }

    @MainActor
    @Test func test_detachedTaskDoNotInheritScope() async throws {
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
                let dependencyThree = AppDependencies.shared.dependencyThree()

                #expect(dependencyThree.dependencyOne is DependencyOneVariantTwo)
                #expect(dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
            }

            AppDependencies.shared.dependencyThree.reset()
            var dependencyThree = AppDependencies.shared.dependencyThree()

            #expect(dependencyThree.dependencyOne is DependencyOneVariantOne)
            #expect(dependencyThree.dependencyTwo is DependencyTwoVariantOne)

            await task.value

            AppDependencies.shared.dependencyThree.reset()
            dependencyThree = AppDependencies.shared.dependencyThree()

            #expect(dependencyThree.dependencyOne is DependencyOneVariantOne)
            #expect(dependencyThree.dependencyTwo is DependencyTwoVariantOne)
        }
    }

    @Test(.disabled("Detection of circular dependencies results in crash")) func test_scopedResolveCircularDependencies() async throws {
        AppDependencies.scoped { _ in
            #expect(AppDependencies.shared.dependencyFour() is DependencyFour)
            #expect(AppDependencies.shared.dependencyFive() is DependencyFive)
        }
    }
}
