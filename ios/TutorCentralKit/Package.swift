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
        // Marks.xcassets: Google's "G" for Sign in with Google, in its own colours.
        .target(name: "DesignSystem", resources: [.process("Resources")]),
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
            .testTarget(name: "TodayTests", dependencies: ["Today", "Students"]),
            // A real register (Students) under the attendance store; the feature itself sees only `Register`.
            .testTarget(name: "AttendanceTests", dependencies: ["Attendance", "Students"]),
            .testTarget(name: "ScheduleTests", dependencies: ["Schedule", "Students"]),
            .testTarget(name: "FeesTests", dependencies: ["Fees", "Students"]),
            .testTarget(name: "StudentsTests", dependencies: ["Students"]),
            // A real register (Students) under Delete account's counts; the feature itself sees only `Register`.
            .testTarget(name: "SettingsTests", dependencies: ["Settings", "Students"]),
            .testTarget(name: "AIToolsTests", dependencies: ["AITools", "Students"]),
        ],
    swiftLanguageModes: [.v6]
)
