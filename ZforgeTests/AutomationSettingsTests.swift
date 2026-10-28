import Foundation
import Testing
@testable import Zforge

/// Language-specific Automation Settings and permission-panel text. The native panels and the
/// pasteboard remain covered by the English `AutomationUITests`.
@Suite("Automation settings")
struct AutomationSettingsTests {
    @Test("Agent setup and folder permission panels use the selected app language", arguments: [
        (AppLanguagePreference.english, ["Open Shortcuts", "Allow", "Authorize Folder to Continue", "Authorize and Continue"]),
        (AppLanguagePreference.portugueseBrazil, ["Abrir Atalhos", "Autorizar", "Autorizar pasta para continuar", "Autorizar e continuar"])
    ])
    func localizedAgentSetup(language: AppLanguagePreference, expected: [String]) {
        let locale = language.locale
        // Settings button, Allow Folder panel prompt, and contextual permission panel title and prompt.
        let resolved = [
            AppLocalization.string("Open Shortcuts", locale: locale),
            AppLocalization.string("Allow", locale: locale),
            AppLocalization.string("Authorize Folder to Continue", locale: locale),
            AppLocalization.string("Authorize and Continue", locale: locale)
        ]
        #expect(resolved == expected)
    }

    @Test("The copied MCP configuration starts this app's executable in MCP mode")
    func copiedConfigurationUsesThisApplication() throws {
        let executable = try #require(Bundle.main.executableURL)
        let data = Data(try AutomationSettingsSection.configuration(executable: executable.path).utf8)
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let servers = try #require(object["mcpServers"] as? [String: [String: Any]])
        #expect(servers.keys.sorted() == ["zforge"])
        #expect(servers["zforge"]?["args"] as? [String] == ["--mcp"])
        let command = try #require(servers["zforge"]?["command"] as? String)
        #expect(command.hasSuffix(".app/Contents/MacOS/Zforge"), "\(command)")
        #expect(FileManager.default.isExecutableFile(atPath: command))
    }
}
