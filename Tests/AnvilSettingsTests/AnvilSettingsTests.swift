import Foundation
import Testing
@testable import AnvilSettings

// MARK: - Test Helpers

struct TestTheme: Codable, Sendable, Equatable {
    var name: String
    var accentColor: String
}

// Use a dedicated UserDefaults suite for tests to avoid polluting standard defaults
extension UserDefaults {
    static func testSuite(_ name: String) -> UserDefaults {
        let suite = UserDefaults(suiteName: name)!
        suite.removePersistentDomain(forName: name)
        return suite
    }
}

// MARK: - AnvilSettings Tests

@Suite("AnvilSettings")
struct AnvilSettingsTests {

    @Test("stores and retrieves String")
    func getSetString() async throws {
        let defaults = UserDefaults.testSuite(#function)
        let settings = AnvilSettings(defaults: defaults)

        await settings.set("greeting", value: "hello")
        let value: String? = await settings.get("greeting")

        #expect(value == "hello")
    }

    @Test("stores and retrieves Int")
    func getSetInt() async throws {
        let defaults = UserDefaults.testSuite(#function)
        let settings = AnvilSettings(defaults: defaults)

        await settings.set("count", value: 42)
        let value: Int? = await settings.get("count")

        #expect(value == 42)
    }

    @Test("stores and retrieves Double")
    func getSetDouble() async throws {
        let defaults = UserDefaults.testSuite(#function)
        let settings = AnvilSettings(defaults: defaults)

        await settings.set("pi", value: 3.14)
        let value: Double? = await settings.get("pi")

        #expect(value == 3.14)
    }

    @Test("stores and retrieves Bool")
    func getSetBool() async throws {
        let defaults = UserDefaults.testSuite(#function)
        let settings = AnvilSettings(defaults: defaults)

        await settings.set("enabled", value: true)
        let value: Bool? = await settings.get("enabled")

        #expect(value == true)
    }

    @Test("stores and retrieves Data")
    func getSetData() async throws {
        let defaults = UserDefaults.testSuite(#function)
        let settings = AnvilSettings(defaults: defaults)
        let data = "hello".data(using: .utf8)!

        await settings.set("payload", value: data)
        let value: Data? = await settings.get("payload")

        #expect(value == data)
    }

    @Test("stores and retrieves Codable struct")
    func getSetCodable() async throws {
        let defaults = UserDefaults.testSuite(#function)
        let settings = AnvilSettings(defaults: defaults)
        let theme = TestTheme(name: "Dark", accentColor: "#FF0000")

        await settings.set("theme", value: theme)
        let value: TestTheme? = await settings.get("theme")

        #expect(value == theme)
    }

    @Test("returns nil for missing key")
    func missingKeyReturnsNil() async throws {
        let defaults = UserDefaults.testSuite(#function)
        let settings = AnvilSettings(defaults: defaults)

        let value: String? = await settings.get("nonexistent")

        #expect(value == nil)
    }

    @Test("remove deletes key")
    func remove() async throws {
        let defaults = UserDefaults.testSuite(#function)
        let settings = AnvilSettings(defaults: defaults)

        await settings.set("temp", value: "value")
        await settings.remove("temp")
        let value: String? = await settings.get("temp")

        #expect(value == nil)
    }

    @Test("contains returns correct value")
    func contains() async throws {
        let defaults = UserDefaults.testSuite(#function)
        let settings = AnvilSettings(defaults: defaults)

        let before = await settings.contains("key")
        await settings.set("key", value: "value")
        let after = await settings.contains("key")

        #expect(before == false)
        #expect(after == true)
    }

    @Test("concurrent access is safe")
    func concurrentAccess() async throws {
        let defaults = UserDefaults.testSuite(#function)
        let settings = AnvilSettings(defaults: defaults)

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                group.addTask {
                    await settings.set("counter", value: i)
                }
            }
        }

        let value: Int? = await settings.get("counter")
        #expect(value != nil)
    }
}

// MARK: - Migration Tests

@Suite("SettingsMigration")
struct SettingsMigrationTests {

    @Test("rename preserves value")
    func rename() async throws {
        let defaults = UserDefaults.testSuite(#function)
        let settings = AnvilSettings(defaults: defaults)

        await settings.set("oldKey", value: "preserved")
        await settings.migrate(from: 1, to: 2) { migrator in
            migrator.rename("oldKey", to: "newKey")
        }

        let value: String? = await settings.get("newKey")
        let oldExists = await settings.contains("oldKey")

        #expect(value == "preserved")
        #expect(oldExists == false)
    }

    @Test("delete removes key")
    func delete() async throws {
        let defaults = UserDefaults.testSuite(#function)
        let settings = AnvilSettings(defaults: defaults)

        await settings.set("deprecated", value: "value")
        await settings.migrate(from: 1, to: 2) { migrator in
            migrator.delete("deprecated")
        }

        let exists = await settings.contains("deprecated")
        #expect(exists == false)
    }

    @Test("migration version is tracked")
    func migrationVersion() async throws {
        let defaults = UserDefaults.testSuite(#function)
        let settings = AnvilSettings(defaults: defaults)

        let before = await settings.currentMigrationVersion()
        #expect(before == 0)

        await settings.migrate(from: 1, to: 2) { _ in }
        let after = await settings.currentMigrationVersion()
        #expect(after == 2)
    }

    @Test("migration is idempotent")
    func migrationIdempotent() async throws {
        let defaults = UserDefaults.testSuite(#function)
        let settings = AnvilSettings(defaults: defaults)

        await settings.set("key", value: "original")
        await settings.migrate(from: 1, to: 2) { migrator in
            migrator.rename("key", to: "renamed")
        }
        await settings.migrate(from: 1, to: 2) { migrator in
            migrator.rename("renamed", to: "doubleRenamed")
        }

        let value: String? = await settings.get("renamed")
        let double: String? = await settings.get("doubleRenamed")

        #expect(value == "original")
        #expect(double == nil)
    }
}
