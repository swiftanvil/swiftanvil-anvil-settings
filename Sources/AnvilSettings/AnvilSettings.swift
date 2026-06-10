import Foundation

/// Actor-isolated type-safe settings store backed by `UserDefaults`.
///
/// `AnvilSettings` provides a concurrency-safe wrapper around `UserDefaults`
/// with automatic `Codable` serialization for complex types.
///
/// ```swift
/// let settings = AnvilSettings()
/// await settings.set("apiEndpoint", value: "https://api.example.com")
/// let endpoint: String? = await settings.get("apiEndpoint")
/// ```
public actor AnvilSettings {
    private let defaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    /// Creates a settings store backed by the given `UserDefaults`.
    /// - Parameter defaults: The `UserDefaults` instance to use. Defaults to `.standard`.
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        encoder = JSONEncoder()
        decoder = JSONDecoder()
    }

    // MARK: - Get / Set

    /// Stores a value for the given key.
    ///
    /// Primitive types (`String`, `Int`, `Double`, `Bool`, `Data`, `URL`)
    /// are stored directly. All other `Codable` types are JSON-encoded.
    public func set(_ key: String, value: some Codable & Sendable) {
        if let direct = value as? any DirectlyStorable {
            direct.store(in: defaults, key: key)
        } else {
            do {
                let data = try encoder.encode(value)
                defaults.set(data, forKey: key)
            } catch {
                // Silently fail for encoding errors; UserDefaults is best-effort
            }
        }
    }

    /// Retrieves a value by key, typed to the expected type.
    ///
    /// Returns `nil` if the key is missing or the stored value cannot be decoded.
    public func get<T: Codable & Sendable>(_ key: String) -> T? {
        if let direct = T.self as? any DirectlyStorable.Type {
            return direct.retrieve(from: defaults, key: key) as? T
        }
        guard let data = defaults.data(forKey: key) else { return nil }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            return nil
        }
    }

    /// Removes the value for the given key.
    public func remove(_ key: String) {
        defaults.removeObject(forKey: key)
    }

    /// Returns `true` if a value exists for the given key.
    public func contains(_ key: String) -> Bool {
        defaults.object(forKey: key) != nil
    }

    /// All keys currently stored by this settings instance.
    ///
    /// Note: This returns all keys in the underlying `UserDefaults`, not just
    /// those set through `AnvilSettings`.
    public var allKeys: [String] {
        Array(defaults.dictionaryRepresentation().keys)
    }

    // MARK: - Migration

    /// The current migration version stored in UserDefaults.
    private var migrationVersionKey: String {
        "anvil.settings.migrationVersion"
    }

    /// Returns the current migration version.
    public func currentMigrationVersion() -> Int {
        defaults.integer(forKey: migrationVersionKey)
    }

    /// Performs a migration if the current version is less than the target version.
    ///
    /// ```swift
    /// await settings.migrate(from: 1, to: 2) { migrator in
    ///     migrator.rename("oldKey", to: "newKey")
    /// }
    /// ```
    public func migrate(from _: Int, to targetVersion: Int, _ block: (SettingsMigration) -> Void) {
        let storedVersion = currentMigrationVersion()
        guard storedVersion < targetVersion else { return }

        let migrator = SettingsMigration(defaults: defaults)
        block(migrator)
        defaults.set(targetVersion, forKey: migrationVersionKey)
    }
}

// MARK: - Directly Storable Types

/// Types that can be stored directly in UserDefaults without JSON encoding.
protocol DirectlyStorable {
    func store(in defaults: UserDefaults, key: String)
    static func retrieve(from defaults: UserDefaults, key: String) -> Self?
}

extension String: DirectlyStorable {
    func store(in defaults: UserDefaults, key: String) {
        defaults.set(self, forKey: key)
    }

    static func retrieve(from defaults: UserDefaults, key: String) -> String? {
        defaults.string(forKey: key)
    }
}

extension Int: DirectlyStorable {
    func store(in defaults: UserDefaults, key: String) {
        defaults.set(self, forKey: key)
    }

    static func retrieve(from defaults: UserDefaults, key: String) -> Int? {
        defaults.object(forKey: key) as? Int
    }
}

extension Double: DirectlyStorable {
    func store(in defaults: UserDefaults, key: String) {
        defaults.set(self, forKey: key)
    }

    static func retrieve(from defaults: UserDefaults, key: String) -> Double? {
        defaults.object(forKey: key) as? Double
    }
}

extension Bool: DirectlyStorable {
    func store(in defaults: UserDefaults, key: String) {
        defaults.set(self, forKey: key)
    }

    static func retrieve(from defaults: UserDefaults, key: String) -> Bool? {
        defaults.object(forKey: key) as? Bool
    }
}

extension Data: DirectlyStorable {
    func store(in defaults: UserDefaults, key: String) {
        defaults.set(self, forKey: key)
    }

    static func retrieve(from defaults: UserDefaults, key: String) -> Data? {
        defaults.data(forKey: key)
    }
}

extension URL: DirectlyStorable {
    func store(in defaults: UserDefaults, key: String) {
        defaults.set(self, forKey: key)
    }

    static func retrieve(from defaults: UserDefaults, key: String) -> URL? {
        defaults.url(forKey: key)
    }
}
