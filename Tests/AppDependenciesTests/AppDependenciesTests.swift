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

struct AppEnvironmentValuesTests {
    @MainActor
    @Test func test_mainActorBoundRegisterAndResolveMultipleDependencies() async throws {
        AppDependencies.shared.dependencyOne.use { _ in
            DependencyOneVariantOne()
        }

        AppDependencies.shared.dependencyTwo.use { _ in
            DependencyTwoVariantOne()
        }

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

            dependencySix = AppDependencies.shared.dependencySix()

            #expect(dependencySix.dependencyOne is DependencyOneVariantTwo)
            #expect(dependencySix.dependencyTwo is DependencyTwoVariantTwo)
            #expect(dependencySix.dependencyThree is DependencyThree)
            #expect(dependencySix.dependencyThree.dependencyOne is DependencyOneVariantTwo)
            #expect(dependencySix.dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
        }
    }

    @Test func test_childTaskInheritScope() async throws {
        try await AppDependencies.scoped {
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

                try await Task.sleep(for: .milliseconds(1))

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

            try await child

            AppDependencies.shared.dependencyThree.reset()
            dependencyThree = AppDependencies.shared.dependencyThree()

            #expect(dependencyThree.dependencyOne is DependencyOneVariantTwo)
            #expect(dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
        }
    }

    @Test func test_unstructuredTaskInheritByCopyingScope() async throws {
        try await AppDependencies.scoped {
            $0.dependencyOne.use { _ in
                DependencyOneVariantOne()
            }

            $0.dependencyTwo.use { _ in
                DependencyTwoVariantOne()
            }

            let task = Task {
                var dependencyThree = AppDependencies.shared.dependencyThree()

                #expect(dependencyThree.dependencyOne is DependencyOneVariantOne)
                #expect(dependencyThree.dependencyTwo is DependencyTwoVariantOne)

                try await Task.sleep(for: .milliseconds(1))

                AppDependencies.shared.dependencyOne.use { _ in
                    DependencyOneVariantTwo()
                }

                AppDependencies.shared.dependencyTwo.use { _ in
                    DependencyTwoVariantTwo()
                }

                dependencyThree = AppDependencies.shared.dependencyThree()

                #expect(dependencyThree.dependencyOne is DependencyOneVariantTwo)
                #expect(dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
            }

            var dependencyThree = AppDependencies.shared.dependencyThree()

            #expect(dependencyThree.dependencyOne is DependencyOneVariantOne)
            #expect(dependencyThree.dependencyTwo is DependencyTwoVariantOne)

            try await task.value

            dependencyThree = AppDependencies.shared.dependencyThree()

            #expect(dependencyThree.dependencyOne is DependencyOneVariantTwo)
            #expect(dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
        }
    }

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

                let dependencyThree = AppDependencies.shared.dependencyThree()

                #expect(dependencyThree.dependencyOne is DependencyOneVariantTwo)
                #expect(dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
            }

            var dependencyThree = AppDependencies.shared.dependencyThree()

            #expect(dependencyThree.dependencyOne is DependencyOneVariantOne)
            #expect(dependencyThree.dependencyTwo is DependencyTwoVariantOne)

            await task.value

            dependencyThree = AppDependencies.shared.dependencyThree()

            #expect(dependencyThree.dependencyOne is DependencyOneVariantOne)
            #expect(dependencyThree.dependencyTwo is DependencyTwoVariantOne)
        }
    }

    @Test func test_multipleDetachedTaskDoNotInheritScope() async throws {
        let tasks = [
            Task.detached {
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

                    var dependencyThree = AppDependencies.shared.dependencyThree()
                    var dependencySix = AppDependencies.shared.dependencySix()

                    #expect(dependencyThree is DependencyThreeVariantOne)
                    #expect(dependencyThree.dependencyOne is DependencyOneVariantOne)
                    #expect(dependencyThree.dependencyTwo is DependencyTwoVariantOne)
                    #expect(dependencySix.dependencyOne is DependencyOneVariantOne)
                    #expect(dependencySix.dependencyTwo is DependencyTwoVariantOne)
                    #expect(dependencySix.dependencyThree is DependencyThreeVariantOne)
                    #expect(dependencySix.dependencyThree.dependencyOne is DependencyOneVariantOne)
                    #expect(dependencySix.dependencyThree.dependencyTwo is DependencyTwoVariantOne)

                    $0.dependencyOne.use { _ in
                        DependencyOneVariantTwo()
                    }

                    $0.dependencyTwo.use { _ in
                        DependencyTwoVariantTwo()
                    }

                    dependencyThree = AppDependencies.shared.dependencyThree()
                    dependencySix = AppDependencies.shared.dependencySix()

                    #expect(dependencyThree is DependencyThreeVariantOne)
                    #expect(dependencyThree.dependencyOne is DependencyOneVariantTwo)
                    #expect(dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
                    #expect(dependencySix.dependencyOne is DependencyOneVariantTwo)
                    #expect(dependencySix.dependencyTwo is DependencyTwoVariantTwo)
                    #expect(dependencySix.dependencyThree is DependencyThreeVariantOne)
                    #expect(dependencySix.dependencyThree.dependencyOne is DependencyOneVariantTwo)
                    #expect(dependencySix.dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
                }
            },
            Task.detached {
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

                    var dependencyThree = AppDependencies.shared.dependencyThree()
                    var dependencySix = AppDependencies.shared.dependencySix()

                    #expect(dependencyThree is DependencyThreeVariantTwo)
                    #expect(dependencyThree.dependencyOne is DependencyOneVariantOne)
                    #expect(dependencyThree.dependencyTwo is DependencyTwoVariantOne)
                    #expect(dependencySix.dependencyOne is DependencyOneVariantOne)
                    #expect(dependencySix.dependencyTwo is DependencyTwoVariantOne)
                    #expect(dependencySix.dependencyThree is DependencyThreeVariantTwo)
                    #expect(dependencySix.dependencyThree.dependencyOne is DependencyOneVariantOne)
                    #expect(dependencySix.dependencyThree.dependencyTwo is DependencyTwoVariantOne)

                    $0.dependencyOne.use { _ in
                        DependencyOneVariantTwo()
                    }

                    $0.dependencyTwo.use { _ in
                        DependencyTwoVariantTwo()
                    }

                    dependencyThree = AppDependencies.shared.dependencyThree()
                    dependencySix = AppDependencies.shared.dependencySix()

                    #expect(dependencyThree is DependencyThreeVariantTwo)
                    #expect(dependencyThree.dependencyOne is DependencyOneVariantTwo)
                    #expect(dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
                    #expect(dependencySix.dependencyOne is DependencyOneVariantTwo)
                    #expect(dependencySix.dependencyTwo is DependencyTwoVariantTwo)
                    #expect(dependencySix.dependencyThree is DependencyThreeVariantTwo)
                    #expect(dependencySix.dependencyThree.dependencyOne is DependencyOneVariantTwo)
                    #expect(dependencySix.dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
                }
            },
            Task.detached {
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

                    var dependencyThree = AppDependencies.shared.dependencyThree()
                    var dependencySix = AppDependencies.shared.dependencySix()

                    #expect(dependencyThree is DependencyThreeVariantThree)
                    #expect(dependencyThree.dependencyOne is DependencyOneVariantOne)
                    #expect(dependencyThree.dependencyTwo is DependencyTwoVariantOne)
                    #expect(dependencySix.dependencyOne is DependencyOneVariantOne)
                    #expect(dependencySix.dependencyTwo is DependencyTwoVariantOne)
                    #expect(dependencySix.dependencyThree is DependencyThreeVariantThree)
                    #expect(dependencySix.dependencyThree.dependencyOne is DependencyOneVariantOne)
                    #expect(dependencySix.dependencyThree.dependencyTwo is DependencyTwoVariantOne)

                    $0.dependencyOne.use { _ in
                        DependencyOneVariantTwo()
                    }

                    $0.dependencyTwo.use { _ in
                        DependencyTwoVariantTwo()
                    }

                    dependencyThree = AppDependencies.shared.dependencyThree()
                    dependencySix = AppDependencies.shared.dependencySix()

                    #expect(dependencyThree is DependencyThreeVariantThree)
                    #expect(dependencyThree.dependencyOne is DependencyOneVariantTwo)
                    #expect(dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
                    #expect(dependencySix.dependencyOne is DependencyOneVariantTwo)
                    #expect(dependencySix.dependencyTwo is DependencyTwoVariantTwo)
                    #expect(dependencySix.dependencyThree is DependencyThreeVariantThree)
                    #expect(dependencySix.dependencyThree.dependencyOne is DependencyOneVariantTwo)
                    #expect(dependencySix.dependencyThree.dependencyTwo is DependencyTwoVariantTwo)
                }
            }
        ]

        for task in tasks {
            await task.value
        }
    }

    @Test(.disabled("Detection of circular dependencies results in crash")) func test_scopedResolveCircularDependencies() async throws {
        AppDependencies.scoped { _ in
            #expect(AppDependencies.shared.dependencyFour() is DependencyFour)
            #expect(AppDependencies.shared.dependencyFive() is DependencyFive)
        }
    }
}
