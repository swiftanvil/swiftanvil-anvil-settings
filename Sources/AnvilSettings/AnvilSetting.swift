import Foundation
import Observation
import SwiftUI

/// A property wrapper that provides type-safe access to `UserDefaults`.
///
/// Changes are automatically persisted and can be observed via SwiftUI bindings.
///
/// ```swift
/// struct SettingsView: View {
///     @AnvilSetting("apiEndpoint") var apiEndpoint: String = "https://api.example.com"
///
///     var body: some View {
///         TextField("API Endpoint", text: $apiEndpoint)
///     }
/// }
/// ```
@propertyWrapper
public struct AnvilSetting<T: Codable & Sendable>: DynamicProperty {
    @State private var storage: SettingStorage<T>

    /// Creates a setting bound to the given key with a default value.
    /// - Parameters:
    ///   - key: The `UserDefaults` key.
    ///   - defaultValue: The value to use when no value is stored.
    ///   - defaults: The `UserDefaults` instance. Defaults to `.standard`.
    public init(_ key: String, defaultValue: T, defaults: UserDefaults = .standard) {
        _storage = State(initialValue: SettingStorage(key: key, defaultValue: defaultValue, defaults: defaults))
    }

    public var wrappedValue: T {
        get { storage.value }
        nonmutating set { storage.value = newValue }
    }

    public var projectedValue: Binding<T> {
        Binding(
            get: { storage.value },
            set: { storage.value = $0 }
        )
    }
}

// MARK: - Setting Storage

/// Internal observable storage for a single setting value.
@Observable
final class SettingStorage<T: Codable & Sendable> {
    let key: String
    let defaultValue: T
    let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    var value: T {
        didSet { persist(value) }
    }

    init(key: String, defaultValue: T, defaults: UserDefaults) {
        self.key = key
        self.defaultValue = defaultValue
        self.defaults = defaults
        value = SettingStorage.load(key: key, defaultValue: defaultValue, defaults: defaults, decoder: decoder)
    }

    private static func load(key: String, defaultValue: T, defaults: UserDefaults, decoder: JSONDecoder) -> T {
        if
            let direct = T.self as? any DirectlyStorable.Type,
            let retrieved = direct.retrieve(from: defaults, key: key) as? T
        {
            return retrieved
        }
        guard let data = defaults.data(forKey: key) else { return defaultValue }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            return defaultValue
        }
    }

    private func persist(_ value: T) {
        if let direct = value as? any DirectlyStorable {
            direct.store(in: defaults, key: key)
        } else {
            do {
                let data = try encoder.encode(value)
                defaults.set(data, forKey: key)
            } catch {
                // Best-effort persistence
            }
        }
    }
}
