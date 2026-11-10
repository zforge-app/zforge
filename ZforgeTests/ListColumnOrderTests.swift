import Foundation
import Testing
@testable import Zforge

/// The default List column order edited in Settings: a dragged row takes the place of
/// each row it passes over, the accessibility actions move one place, and Name stays first.
@Suite("Default List column order")
@MainActor
struct ListColumnOrderTests {
    @Test("Hovering a dragged column over another takes that column's place")
    func dragOverTakesTargetPlace() throws {
        let fixture = try PreferencesFixture()
        defer { fixture.close() }
        let preferences = fixture.preferences
        preferences.setGlobalListColumns([.name, .modificationDate, .size, .kind, .tags])

        preferences.moveGlobalListColumn(.tags, onto: .modificationDate)
        #expect(preferences.globalListColumns == [.name, .tags, .modificationDate, .size, .kind])
        preferences.moveGlobalListColumn(.tags, onto: .kind)
        #expect(preferences.globalListColumns == [.name, .modificationDate, .size, .kind, .tags])
        preferences.moveGlobalListColumn(.modificationDate, onto: .size)
        #expect(preferences.globalListColumns == [.name, .size, .modificationDate, .kind, .tags])

        // Name, hidden columns and the dragged column itself are not targets.
        for (dragged, target) in [(BrowserListColumn.kind, BrowserListColumn.name), (.kind, .comments),
                                  (.comments, .size), (.name, .size), (.kind, .kind)] {
            preferences.moveGlobalListColumn(dragged, onto: target)
        }
        #expect(preferences.globalListColumns == [.name, .size, .modificationDate, .kind, .tags])
    }

    @Test("The dragged order persists")
    func dragPersists() throws {
        let fixture = try PreferencesFixture()
        defer { fixture.close() }
        fixture.preferences.setGlobalListColumns([.name, .modificationDate, .size, .kind])
        fixture.preferences.moveGlobalListColumn(.kind, onto: .modificationDate)

        let reloaded = FileBrowserPreferences(defaults: fixture.defaults)
        #expect(reloaded.globalListColumns == [.name, .kind, .modificationDate, .size])
    }

    @Test("Name stays first and cannot be passed")
    func nameStaysFirst() throws {
        let fixture = try PreferencesFixture()
        defer { fixture.close() }
        let preferences = fixture.preferences
        let order: [BrowserListColumn] = [.name, .modificationDate, .size, .kind]
        preferences.setGlobalListColumns(order)

        preferences.moveGlobalListColumn(.kind, onto: .name)
        preferences.moveGlobalListColumn(.name, onto: .kind)
        #expect(preferences.globalListColumns == order)

        preferences.moveGlobalListColumn(.name, by: 1)
        preferences.moveGlobalListColumn(.modificationDate, by: -1)
        preferences.moveGlobalListColumn(.kind, by: 1)
        #expect(preferences.globalListColumns == order)
    }

    @Test("A drag lands one place per row travelled, between Name and the last visible column")
    func dragTranslationPicksPlace() {
        // Rows 38 pt apart; Kind starts at index 3 of [Name, Date Modified, Size, Kind].
        let place = { (translation: CGFloat) in
            ListColumnReorder.targetIndex(from: 3, translation: translation, rowPitch: 38, count: 4)
        }
        #expect(place(0) == 3)
        #expect(place(-18) == 3, "Less than half a row keeps the place.")
        #expect(place(-20) == 2)
        #expect(place(-76) == 1)
        #expect(place(-200) == 1, "Name keeps the first place.")
        #expect(place(40) == 3, "The last visible column is the end.")
        #expect(ListColumnReorder.targetIndex(from: 1, translation: 40, rowPitch: 38, count: 4) == 2)
        #expect(ListColumnReorder.targetIndex(from: 1, translation: 80, rowPitch: 38, count: 4) == 3,
                "Dragging down two rows lands two places later.")
        #expect(ListColumnReorder.targetIndex(from: 2, translation: 90, rowPitch: 0, count: 4) == 2,
                "Without measured rows the column stays put.")
    }

    @Test("Accessibility moves go one place left or right")
    func stepMoves() throws {
        let fixture = try PreferencesFixture()
        defer { fixture.close() }
        let preferences = fixture.preferences
        preferences.setGlobalListColumns([.name, .modificationDate, .size, .kind])

        preferences.moveGlobalListColumn(.kind, by: -1)
        #expect(preferences.globalListColumns == [.name, .modificationDate, .kind, .size])
        preferences.moveGlobalListColumn(.modificationDate, by: 1)
        #expect(preferences.globalListColumns == [.name, .kind, .modificationDate, .size])
    }
}

@MainActor
private final class PreferencesFixture {
    let defaults: UserDefaults
    let preferences: FileBrowserPreferences
    private let suite = "ZforgeTestSuite.ZforgeListColumnOrder-\(UUID().uuidString)"

    init() throws {
        defaults = try #require(UserDefaults(suiteName: suite))
        preferences = FileBrowserPreferences(defaults: defaults)
    }

    func close() {
        defaults.removeTestSuite(named: suite)
    }
}
