// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "GQLSwift",
    platforms: [.iOS(.v13)],
    products: [
        .plugin(name: "GQLPlugin", targets: ["GQLPlugin"]),
    ],
    targets: [
        .target(name: "GQLGenerator"),
        .executableTarget(
            name: "GQLMain",
            dependencies: ["GQLGenerator"]
        ),
        .plugin(
            name: "GQLPlugin",
            capability: .buildTool(),
            dependencies: ["GQLMain"],
            path: "Plugins/GQLPlugin"
        ),
    ]
)
