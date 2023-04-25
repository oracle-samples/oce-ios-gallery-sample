// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.
// Copyright © 2023 Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import PackageDescription

let package = Package(
    name: "GallerySample",
    platforms: [.iOS("16.0")],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "GallerySample",
            targets: ["GallerySample"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/oracle-samples/content-management-swift",
                 .upToNextMajor(from: Version(stringLiteral: "1.0.0")))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "GallerySample",
            dependencies: [.product(name: "OracleContentCore", package: "content-management-swift"),
                           .product(name: "OracleContentDelivery", package: "content-management-swift")]),
        .testTarget(
            name: "GallerySampleTests",
            dependencies: [
                "GallerySample",
                .product(name: "OracleContentTest", package: "content-management-swift"),
                .product(name: "OracleContentCore", package: "content-management-swift"),
                .product(name: "OracleContentDelivery", package: "content-management-swift")
            ],
            resources: [.process("Resources")]
        )
    ]
)
