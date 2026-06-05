# ``AnvilSettings``

Type-safe UserDefaults wrapper with `@AnvilSetting` property wrapper and migration support.

## Overview

`AnvilSettings` provides a concurrency-safe, type-safe interface to `UserDefaults`:

```swift
let settings = AnvilSettings()
await settings.set("apiEndpoint", value: "https://api.example.com")
let endpoint: String? = await settings.get("apiEndpoint")
```

For SwiftUI integration, use the `@AnvilSetting` property wrapper:

```swift
struct SettingsView: View {
    @AnvilSetting("apiEndpoint") var apiEndpoint: String = "https://api.example.com"

    var body: some View {
        TextField("API Endpoint", text: $apiEndpoint)
    }
}
```

## Topics

### Core Types

- ``AnvilSettings``
- ``AnvilSetting``
- ``SettingsMigration``
