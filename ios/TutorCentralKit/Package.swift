// swift-tools-version: 6.0
import PackageDescription

let features = ["Today", "Students", "Fees", "Attendance", "Schedule", "AITools", "Settings", "Onboarding"]

let package = Package(
    name: "TutorCentralKit",
    platforms: [.iOS("26.0")],
    products: [
        .library(name: "AppShell", targets: ["AppShell"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift.git", exact: "2.55.3"),
    ],
    targets: [
        .target(name: "DesignSystem"),
        .target(name: "Domain"),
        .target(name: "Data", dependencies: [
            "Domain",
            .product(name: "Supabase", package: "supabase-swift"),
        ]),
    ]
        + features.map { name in
            .target(name: name, dependencies: ["Domain", "Data", "DesignSystem"], path: "Sources/Features/\(name)")
        }
        + [
            .target(
                name: "AppShell",
                dependencies: ["Domain", "Data", "DesignSystem"] + features.map { Target.Dependency(stringLiteral: $0) }
            ),
            .testTarget(name: "DesignSystemTests", dependencies: ["DesignSystem"]),
            .testTarget(name: "DomainTests", dependencies: ["Domain"]),
            .testTarget(name: "DataTests", dependencies: ["Data"]),
            .testTarget(name: "AppShellTests", dependencies: ["AppShell"]),
            .testTarget(name: "OnboardingTests", dependencies: ["Onboarding"]),
            .testTarget(name: "TodayTests", dependencies: ["Today"]),
        ],
    swiftLanguageModes: [.v6]
)
