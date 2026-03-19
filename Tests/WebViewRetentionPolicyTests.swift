import Foundation

private func expectEqual<T: Equatable>(
    _ actual: T,
    _ expected: T,
    _ message: String
) {
    guard actual == expected else {
        fputs("Assertion failed: \(message)\nexpected: \(expected)\nactual: \(actual)\n", stderr)
        exit(1)
    }
}

@main
struct WebViewRetentionPolicyTests {
    static func main() {
        let policy = WebViewRetentionPolicy(maxRetainedTabs: 3)

        expectEqual(
            policy.retainedKeys(
                selectedKey: "gh",
                recentlySelectedKeys: ["gh", "x", "ggl", "b"],
                availableKeys: ["gh", "x", "ggl", "b", "claude"]
            ),
            Set(["gh", "x", "ggl"]),
            "should keep the selected tab plus the two most recently used tabs"
        )

        expectEqual(
            policy.retainedKeys(
                selectedKey: "claude",
                recentlySelectedKeys: ["gh", "x", "ggl", "b"],
                availableKeys: ["gh", "x", "ggl", "b", "claude"]
            ),
            Set(["claude", "gh", "x"]),
            "should always keep the newly selected tab even if it was not in the previous recency list"
        )

        expectEqual(
            policy.retainedKeys(
                selectedKey: "",
                recentlySelectedKeys: ["gh", "x"],
                availableKeys: ["gh", "x"]
            ),
            Set<String>(),
            "should not retain anything when no tab is selected"
        )

        print("WebViewRetentionPolicyTests passed")
    }
}
