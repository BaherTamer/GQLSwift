# GQLSwift

**GQLSwift** is a SwiftPM build-tool plugin that generates Swift code from your GraphQL operation files at build time — no scripts, no manual steps, no network calls.

---

## How It Works

Every time you build, **GQLPlugin** invokes **GQLMain**, which:

1. Recursively scans for all `*.graphql` files under the project root.
2. Parses `fragment` definitions and `query` / `mutation` operations, **inlining all fragment spreads** into each operation's document.
3. Writes a single **`GQLOperations.swift`** file to the plugin output directory.

The generated file contains a root `struct GQLOperations` with one nested `struct` per operation. Each nested struct exposes three static `String` properties:

| Property | Description |
|---|---|
| `name` | The operation name (e.g. `"HelloWorldQuery"`) |
| `type` | Either `"query"` or `"mutation"` |
| `document` | The full, self-contained GraphQL document string |

> Duplicate operation names are automatically disambiguated so the project always compiles cleanly.

---

## Requirements

| Dependency | Minimum Version |
|---|---|
| Xcode | 15.3+ |
| Swift | 5.10+ |
| iOS | 13+ |

---

## Installation

1. In Xcode, go to **File → Add Package Dependencies…** and enter:
   ```
   https://github.com/BaherTamer/GQLSwift
   ```
2. In your **Target** settings, open **Build Phases → Run Build Tool Plug-ins** and add **GQLPlugin** (not *Link Binary With Libraries*).
3. Add your `*.graphql` files anywhere under the `.xcodeproj` directory and build — `GQLOperations` will be available in that target with no import required.

> The scanner searches from the **`.xcodeproj`** directory downward. Keep all `.graphql` files within that tree.

---

## Example

**`HelloWorld.graphql`**

```graphql
query HelloWorld {
  __typename
}
```

**Generated `GQLOperations.swift`**

```swift
struct GQLOperations {
    struct HelloWorldQuery {
        static let name    = "HelloWorldQuery"
        static let type    = "query"
        static let document = """
        query HelloWorld {
          __typename
        }
        """
    }
}
```

Then use it anywhere in your target:

```swift
let document = GQLOperations.HelloWorldQuery.document
```

> If operation names collide, the generated struct names are disambiguated automatically while the `name` property always reflects the original GraphQL name.
