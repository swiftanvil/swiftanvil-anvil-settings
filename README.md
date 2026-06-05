# AnvilSettings

Type-safe UserDefaults wrapper with `@AnvilSetting` property wrapper and migration support.

## Features

- **Type-safe**: `Codable` values are automatically serialized; primitives stored directly
- **Actor-isolated**: `AnvilSettings` is an actor — safe concurrent access
- **SwiftUI integration**: `@AnvilSetting` property wrapper with `Binding` support
- **Migration**: Versioned key renames, transforms, and deletions
- **Zero dependencies**: Foundation + Observation only

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/swiftanvil/swiftanvil-anvil-settings.git", from: "1.0.0"),
]
```

## Usage

### Direct API

```swift
import AnvilSettings

let settings = AnvilSettings()
await settings.set("apiEndpoint", value: "https://api.example.com")
await settings.set("maxItems", value: 100)

let endpoint: String? = await settings.get("apiEndpoint")
let maxItems: Int? = await settings.get("maxItems")
```

### Property Wrapper

```swift
import SwiftUI
import AnvilSettings

struct SettingsView: View {
    @AnvilSetting("apiEndpoint") var apiEndpoint: String = "https://api.example.com"
    @AnvilSetting("maxItems") var maxItems: Int = 100

    var body: some View {
        Form {
            TextField("API Endpoint", text: $apiEndpoint)
            Stepper("Max Items: \(maxItems)", value: $maxItems)
        }
    }
}
```

### Codable Values

```swift
struct AppTheme: Codable, Sendable {
    var name: String
    var accentColor: String
}

await settings.set("theme", value: AppTheme(name: "Dark", accentColor: "#FF0000"))
let theme: AppTheme? = await settings.get("theme")
```

### Migration

```swift
await settings.migrate(from: 1, to: 2) { migrator in
    migrator.rename("oldKey", to: "newKey")
    migrator.transform("count", to: "maxItems") { (old: Int) in old * 10 }
    migrator.delete("deprecatedKey")
}
```

## Platforms

- iOS 18+
- macOS 15+
- tvOS 18+
- watchOS 11+
- visionOS 2+

## License

MIT
