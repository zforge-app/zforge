import Foundation
import Darwin

enum UserDirectoryService {
    static var homeURL: URL {
        if let account = getpwuid(getuid()) {
            let path = String(cString: account.pointee.pw_dir)
            if !path.isEmpty {
                return URL(fileURLWithPath: path, isDirectory: true)
            }
        }

        let sandboxHome = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL
        let containerMarker = "/Library/Containers/"
        if let markerRange = sandboxHome.path.range(of: containerMarker) {
            return URL(
                fileURLWithPath: String(sandboxHome.path[..<markerRange.lowerBound]),
                isDirectory: true
            )
        }

        return URL(fileURLWithPath: "/Users", isDirectory: true)
            .appendingPathComponent(NSUserName(), isDirectory: true)
    }

    static var desktopURL: URL {
        homeURL.appendingPathComponent("Desktop", isDirectory: true)
    }

    static var documentsURL: URL {
        homeURL.appendingPathComponent("Documents", isDirectory: true)
    }

    static var downloadsURL: URL {
        homeURL.appendingPathComponent("Downloads", isDirectory: true)
    }

    static func url(forUserEnteredPath path: String) -> URL {
        if path == "~" {
            return homeURL.standardizedFileURL
        }

        if path.hasPrefix("~/") {
            return homeURL
                .appendingPathComponent(String(path.dropFirst(2)), isDirectory: true)
                .standardizedFileURL
        }

        return URL(fileURLWithPath: path, isDirectory: true).standardizedFileURL
    }
}
