# App Dependencies

A simple - yet powerful - Dependency Injection library for Swift.

Heavily inspired by [Factory](https://github.com/hmlongco/Factory) and [Dependencies](https://github.com/pointfreeco/swift-dependencies). 

## Install

Add this package as a dependency to your `Package.swift` or the Package List in Xcode.

```swift
dependencies: [
    .package(url: "https://github.com/thomsmed/app-dependencies-swift.git", .branch: "main)
]
```

Add the `AppDependencies` product of this package as a product dependency to your targets.

```swift
dependencies: [
    .product(name: "AppDependencies", package: "AppDependenciesSwift")
]
```

## Declare

By extending `AppDependencies`:

```swift
extension AppDependencies {
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
}
```

## Resolve

By accessing the shared `AppDependencies` instance explicitly:

```swift
let dependencyOne = AppDependencies.shared.dependencyOne()
let dependencyThree = AppDependencies.shared.dependencyThree()
let dependencyTwo = AppDependencies.shared.dependencyTwo()
```

Using a property wrapper (which implicitly access the shared `AppDependencies` instance):

```swift
struct Model {
    @AppDependency(\.dependencyTwo) var dependencyTwo
    @AppDependency(\.dependencyThree) var dependencyThree
    @AppDependency(\.dependencyOne) var dependencyOne
}
```

Check out [AppDependency](Sources/AppDependencies/AppDependency) for the various property wrapper alternatives.

## Mock

Using a scoped ([Task-Local stored](https://developer.apple.com/documentation/swift/tasklocal)) `AppDependencies` instance:

```swift
AppDependencies.scoped {
    $0.dependencyOne.use { _ in
        MockDependencyOne()
    }

    $0.dependencyTwo.use { _ in
        MockDependencyTwo()
    }

    let dependencyOne = AppDependencies.shared.dependencyOne()
    let dependencyThree = AppDependencies.shared.dependencyThree()
    let dependencyTwo = AppDependencies.shared.dependencyTwo()

    // ...

    #expect(dependencyOne is MockDependencyOne)
    #expect(dependencyTwo is MockDependencyTwo)
}
```

Using a scoped ([Task-Local stored](https://developer.apple.com/documentation/swift/tasklocal)) `AppDependencies` instance (via property wrappers):

```swift
struct Model {
    @AppDependency(\.dependencyTwo) var dependencyTwo
    @AppDependency(\.dependencyThree) var dependencyThree
    @AppDependency(\.dependencyOne) var dependencyOne
}

AppDependencies.scoped {
    $0.dependencyOne.use { _ in
        MockDependencyOne()
    }

    $0.dependencyTwo.use { _ in
        MockDependencyTwo()
    }

    let model = Model()

    // ...

    #expect(model.dependencyOne is MockDependencyOne)
    #expect(model.dependencyTwo is MockDependencyTwo)
}
```

Using a scoped ([Task-Local stored](https://developer.apple.com/documentation/swift/tasklocal)) `AppDependencies` instance during Unit/Model instantiation:

```swift
struct Model {
    @AppDependency(\.dependencyTwo) var dependencyTwo
    @AppDependency(\.dependencyThree) var dependencyThree
    @AppDependency(\.dependencyOne) var dependencyOne
}

let model = AppDependencies.scoped {
    $0.dependencyOne.use { _ in
        MockDependencyOne()
    }

    $0.dependencyTwo.use { _ in
        MockDependencyTwo()
    }

    return Model()
}

// ...

#expect(model.dependencyOne is MockDependencyOne)
#expect(model.dependencyTwo is MockDependencyTwo)
```

## Disclaimer

This library is currently in an early experimentation phase, and might change drastically in all kind of ways.
Use it more as a source of inspiration than anything else.

It is also heavily inspired by [Factory](https://github.com/hmlongco/Factory) and [Dependencies](https://github.com/pointfreeco/swift-dependencies), so definitely check out those! 

## License

MIT License

Copyright (c) 2025 Thomas Asheim Smedmann

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
