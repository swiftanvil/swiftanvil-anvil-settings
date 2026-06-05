import Foundation

/// Builder for versioned settings migrations.
///
/// ```swift
/// await settings.migrate(from: 1, to: 2) { migrator in
///     migrator.rename("oldKey", to: "newKey")
///     migrator.transform("count", to: "maxItems") { (old: Int) in old * 10 }
///     migrator.delete("deprecatedKey")
/// }
/// ```
public struct SettingsMigration {
    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    /// Renames a key, preserving its value.
    public func rename(_ oldKey: String, to newKey: String) {
        guard let value = defaults.object(forKey: oldKey) else { return }
        defaults.set(value, forKey: newKey)
        defaults.removeObject(forKey: oldKey)
    }

    /// Transforms a value from one key to another, applying a conversion.
    ///
    /// The transform closure receives the old value and returns the new value.
    /// If the old key does not exist or the transform fails, nothing is changed.
    public func transform<T: Codable & Sendable, U: Codable & Sendable>(
        _ oldKey: String,
        to newKey: String,
        _ transform: (T) -> U?
    ) {
        guard let data = defaults.data(forKey: oldKey) else { return }
        do {
            let oldValue = try JSONDecoder().decode(T.self, from: data)
            guard let newValue = transform(oldValue) else { return }
            let newData = try JSONEncoder().encode(newValue)
            defaults.set(newData, forKey: newKey)
            defaults.removeObject(forKey: oldKey)
        } catch {
            // Silently skip failed transforms
        }
    }

    /// Deletes a key and its value.
    public func delete(_ key: String) {
        defaults.removeObject(forKey: key)
    }
}
