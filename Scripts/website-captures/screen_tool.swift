// Small window-server helper for the website capture scripts. Compiled once per
// run (swiftc screen_tool.swift -o …); needs the Accessibility permission of the
// terminal for the mouse commands, and Screen Recording for window names.
//
//   windows <pid>          the process's on-screen windows, one JSON line each
//                          (id, layer, name, x, y, width, height in points)
//   move <x> <y>           moves the pointer (top-left screen coordinates)
//   click <x> <y>          left click
//   rightclick <x> <y>     right click (opens a context menu)
//   cmdclick <x> <y>       left click with ⌘ (adds to a selection)
//   down <x> <y>           presses the left button there and keeps it down (a
//                          button drawn pressed)
//   up <x> <y>             drags the pressed button to the point and releases it
//                          there (away from the button, so the click is cancelled)
//   pointer                prints the pointer position
//   activate <pid>         brings that process to the front by its pid (the
//                          accessibility API), never by its bundle identifier: a
//                          second copy of an app shares it with the first
//   frontmost              prints the pid of the frontmost process
//   backdrop <grey>        shows a plain full-screen window of that grey (0–1) under
//                          the app brought forward next, so translucent sidebars and
//                          panes show a neutral colour instead of the user's desktop;
//                          it ignores the mouse and runs until killed
//   screensize             width and height of the main display, in points
//   key <pid> <code> [mods]
//                          a key (virtual key code), posted to that process only;
//                          mods: any of cmd, shift, alt, ctrl joined by commas
//   type <pid> <text>      types the text, posted to that process only
//   axdump <pid>           every accessibility element of the process's windows, one
//                          JSON line each (window index, role, subrole, title,
//                          description, value, identifier, frame in screen points)
//   axwindow <pid>         the main window: title, frame and number of sheets (JSON)
//   axframe <pid> <x> <y> <w> <h>
//                          moves and resizes the process's main window
//   axmenu <pid> <index>   titles of the items of the menu bar item at index (0 is
//                          Apple), one per line
//   axmenus <pid>          the process's open context menu and its open submenus: one
//                          JSON line per menu and per item (level, role, title,
//                          identifier, selected, enabled, frame in screen points)
//   axmenupress <pid> <index> <title>
//                          presses that item of that menu
//   safeclick <pid> <x> <y> [cmd]
//                          a left click, only if the front window at the point
//                          belongs to the process (exits 3 otherwise)
//   safedown <pid> <x> <y> the same for "down"
//   saferightclick <pid> <x> <y>
//                          the same for a right click
//   owner <x> <y>          pid of the process whose window is in front at the point
//   All the ax… commands address the process by pid through the accessibility API:
//   System Events, given a pid, resolves the process by its bundle identifier and may
//   reach another copy of the same app.
//   hidkey <code> [mods], hidtype <text>
//                          the same, posted to whatever has the keyboard focus (an
//                          open panel, which another process draws)
//   compose <out.png> <width> <height> <path> <x> <y> [<path> <x> <y> …]
//                          draws window captures (back to front) on a transparent
//                          canvas of width × height pixels, each at its pixel
//                          offset from the top left: a window and the panels it
//                          shows over itself (a toast), with no desktop behind
//   maskalpha <screen.png> <window.png> <out.png>
//                          the first image with the alpha of the second (same size): a
//                          capture of the screen where a window is, with the window's
//                          own transparent corners
//   ocr <image.png>         every line of text Vision reads in the image, one JSON line
//                          each (text and its frame in pixels from the top left)
//   crop <in.png> <out.png> <x> <y> <w> <h>
//                          cuts a rectangle (pixels) out of an image
//   find <x> <y> <w> <h> <text>
//                          reads the screen inside the rectangle (Vision text
//                          recognition) and prints the frame of the first line
//                          equal to <text>, in screen points ("x y w h"); exits
//                          1 when no line matches. Menus that GUI scripting
//                          cannot reach (SwiftUI and Finder context menus) are
//                          driven by clicking what this finds.
//   findin <image.png> <text>
//                          the same, in an image file (frame in its pixels)
import AppKit
import ImageIO
import Vision
import CoreGraphics
import Foundation

let arguments = CommandLine.arguments
func number(_ index: Int) -> Double { Double(arguments[index]) ?? 0 }

func post(_ type: CGEventType, _ point: CGPoint, _ button: CGMouseButton = .left,
          flags: CGEventFlags = []) {
    let event = CGEvent(mouseEventSource: CGEventSource(stateID: .hidSystemState), mouseType: type,
                        mouseCursorPosition: point, mouseButton: button)
    if !flags.isEmpty { event?.flags = flags }
    event?.post(tap: .cghidEventTap)
    usleep(40_000)
}

func flags(_ text: String) -> CGEventFlags {
    var result: CGEventFlags = []
    for name in text.split(separator: ",") {
        switch name {
        case "cmd": result.insert(.maskCommand)
        case "shift": result.insert(.maskShift)
        case "alt": result.insert(.maskAlternate)
        case "ctrl": result.insert(.maskControl)
        default: break
        }
    }
    return result
}

func keyEvents(code: CGKeyCode, modifiers: CGEventFlags, text: String? = nil) -> [CGEvent] {
    let source = CGEventSource(stateID: .hidSystemState)
    return [true, false].compactMap { down in
        let event = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: down)
        event?.flags = modifiers
        if let text {
            let units = Array(text.utf16)
            event?.keyboardSetUnicodeString(stringLength: units.count, unicodeString: units)
        }
        return event
    }
}

func send(_ events: [CGEvent], to pid: pid_t?) {
    for event in events {
        if let pid { event.postToPid(pid) } else { event.post(tap: .cghidEventTap) }
        usleep(12_000)
    }
}

func typeText(_ text: String, to pid: pid_t?) {
    for character in text {
        send(keyEvents(code: 0, modifiers: [], text: String(character)), to: pid)
    }
}

func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
    var value: CFTypeRef?
    return AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success ? value : nil
}

func text(_ element: AXUIElement, _ name: String) -> String {
    guard let value = attribute(element, name) else { return "" }
    if let string = value as? String { return string }
    if let number = value as? NSNumber { return number.stringValue }
    return ""
}

func frame(_ element: AXUIElement) -> CGRect? {
    guard let position = attribute(element, kAXPositionAttribute), let size = attribute(element, kAXSizeAttribute)
    else { return nil }
    var point = CGPoint.zero, extent = CGSize.zero
    AXValueGetValue(position as! AXValue, .cgPoint, &point)
    AXValueGetValue(size as! AXValue, .cgSize, &extent)
    return CGRect(origin: point, size: extent)
}

func children(_ element: AXUIElement) -> [AXUIElement] {
    (attribute(element, kAXChildrenAttribute) as? [AXUIElement]) ?? []
}

func windows(of pid: pid_t) -> [AXUIElement] {
    (attribute(AXUIElementCreateApplication(pid), kAXWindowsAttribute) as? [AXUIElement]) ?? []
}

/// The browser window: the largest standard window of the process.
func mainWindow(of pid: pid_t) -> AXUIElement? {
    windows(of: pid).max { (frame($0)?.width ?? 0) * (frame($0)?.height ?? 0)
        < (frame($1)?.width ?? 0) * (frame($1)?.height ?? 0) }
}

func menuItems(_ pid: pid_t, _ index: Int) -> [AXUIElement] {
    guard let bar = attribute(AXUIElementCreateApplication(pid), kAXMenuBarAttribute) else { return [] }
    let items = children(bar as! AXUIElement)
    guard items.indices.contains(index), let menu = children(items[index]).first else { return [] }
    return children(menu)
}

/// Whether the front window at `point` (screen points) belongs to `pid`.
func frontWindowOwner(at point: CGPoint) -> Int {
    let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
        as? [[String: Any]] ?? []
    for window in list {
        let bounds = window[kCGWindowBounds as String] as? [String: Double] ?? [:]
        let rect = CGRect(x: bounds["X"] ?? 0, y: bounds["Y"] ?? 0, width: bounds["Width"] ?? 0,
                          height: bounds["Height"] ?? 0)
        let alpha = window[kCGWindowAlpha as String] as? Double ?? 1
        let layer = window[kCGWindowLayer as String] as? Int ?? 0
        // Skip the menu bar, the Dock, the window manager's overlays and invisible windows.
        let owner = window[kCGWindowOwnerName as String] as? String ?? ""
        guard rect.contains(point), alpha > 0, layer < 1000, layer != 24, layer != 25,
              !["Dock", "Window Server", "WindowManager", "Control Center", "SystemUIServer"].contains(owner)
        else { continue }
        return window[kCGWindowOwnerPID as String] as? Int ?? 0
    }
    return 0
}

switch arguments.count > 1 ? arguments[1] : "" {
case "axdump":
    let pid = pid_t(arguments[2]) ?? 0
    func walk(_ element: AXUIElement, window: Int, depth: Int) {
        if let rect = frame(element) {
            let line: [String: Any] = [
                "window": window, "role": text(element, kAXRoleAttribute),
                "subrole": text(element, kAXSubroleAttribute), "title": text(element, kAXTitleAttribute),
                "description": text(element, kAXDescriptionAttribute), "value": text(element, kAXValueAttribute),
                "identifier": text(element, kAXIdentifierAttribute), "help": text(element, kAXHelpAttribute),
                "enabled": (attribute(element, kAXEnabledAttribute) as? Bool) ?? true,
                "selected": (attribute(element, kAXSelectedAttribute) as? Bool) ?? false,
                "x": rect.minX, "y": rect.minY, "width": rect.width, "height": rect.height,
            ]
            let data = try! JSONSerialization.data(withJSONObject: line, options: [.sortedKeys])
            print(String(decoding: data, as: UTF8.self))
        }
        guard depth < 40 else { return }
        for child in children(element) { walk(child, window: window, depth: depth + 1) }
    }
    for (index, window) in windows(of: pid).enumerated() { walk(window, window: index, depth: 0) }
case "axwindow":
    let pid = pid_t(arguments[2]) ?? 0
    guard let window = mainWindow(of: pid), let rect = frame(window) else { exit(1) }
    let sheets = children(window).filter { text($0, kAXRoleAttribute) == "AXSheet" }.count
    let line: [String: Any] = ["title": text(window, kAXTitleAttribute), "x": rect.minX, "y": rect.minY,
                               "width": rect.width, "height": rect.height, "sheets": sheets,
                               "windows": windows(of: pid).count]
    print(String(decoding: try! JSONSerialization.data(withJSONObject: line, options: [.sortedKeys]), as: UTF8.self))
case "axframe":
    let pid = pid_t(arguments[2]) ?? 0
    guard let window = mainWindow(of: pid) else { exit(1) }
    var point = CGPoint(x: number(3), y: number(4)), size = CGSize(width: number(5), height: number(6))
    AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, AXValueCreate(.cgPoint, &point)!)
    AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, AXValueCreate(.cgSize, &size)!)
case "axmenus":
    // The open context menus of the process (Finder's shortcut menu and the submenus open
    // beside it), whatever language their titles are in.
    func walkMenu(_ menu: AXUIElement, level: Int) {
        guard let rect = frame(menu) else { return }
        let line: [String: Any] = ["level": level, "role": "AXMenu", "title": "", "x": rect.minX,
                                   "y": rect.minY, "width": rect.width, "height": rect.height,
                                   "selected": false, "enabled": true, "identifier": ""]
        print(String(decoding: try! JSONSerialization.data(withJSONObject: line, options: [.sortedKeys]), as: UTF8.self))
        for item in children(menu) where text(item, kAXRoleAttribute) == "AXMenuItem" {
            guard let itemRect = frame(item) else { continue }
            let entry: [String: Any] = [
                "level": level, "role": "AXMenuItem", "title": text(item, kAXTitleAttribute),
                "identifier": text(item, kAXIdentifierAttribute),
                "selected": (attribute(item, kAXSelectedAttribute) as? Bool) ?? false,
                "enabled": (attribute(item, kAXEnabledAttribute) as? Bool) ?? true,
                "x": itemRect.minX, "y": itemRect.minY, "width": itemRect.width, "height": itemRect.height,
            ]
            print(String(decoding: try! JSONSerialization.data(withJSONObject: entry, options: [.sortedKeys]),
                         as: UTF8.self))
            for submenu in children(item) where text(submenu, kAXRoleAttribute) == "AXMenu" {
                walkMenu(submenu, level: level + 1)
            }
        }
    }
    // Finder hangs its shortcut menu under the view it was opened on, not under the
    // application: search the windows' trees (the menu bar is left out).
    func findMenus(_ element: AXUIElement, depth: Int) {
        for child in children(element) {
            switch text(child, kAXRoleAttribute) {
            case "AXMenu": walkMenu(child, level: 0)
            case "AXMenuBar": continue
            default: if depth < 40 { findMenus(child, depth: depth + 1) }
            }
        }
    }
    findMenus(AXUIElementCreateApplication(pid_t(arguments[2]) ?? 0), depth: 0)
case "axmenu":
    for item in menuItems(pid_t(arguments[2]) ?? 0, Int(arguments[3]) ?? 0) {
        print(text(item, kAXTitleAttribute))
    }
case "axmenupress":
    guard let item = menuItems(pid_t(arguments[2]) ?? 0, Int(arguments[3]) ?? 0)
        .first(where: { text($0, kAXTitleAttribute) == arguments[4] }) else { exit(1) }
    exit(AXUIElementPerformAction(item, kAXPressAction as CFString) == .success ? 0 : 1)
case "owner":
    print(frontWindowOwner(at: CGPoint(x: number(2), y: number(3))))
case "saferightclick":
    let point = CGPoint(x: number(3), y: number(4))
    guard frontWindowOwner(at: point) == Int(arguments[2]) ?? 0,
          NSWorkspace.shared.frontmostApplication?.processIdentifier == pid_t(arguments[2]) ?? 0 else {
        FileHandle.standardError.write(Data("the front window at \(point) is not the process's\n".utf8))
        exit(3)
    }
    post(.mouseMoved, point, .right)
    post(.rightMouseDown, point, .right)
    post(.rightMouseUp, point, .right)
case "safeclick", "safedown":
    let pid = Int(arguments[2]) ?? 0
    let point = CGPoint(x: number(3), y: number(4))
    guard frontWindowOwner(at: point) == pid else {
        FileHandle.standardError.write(Data("the front window at \(point) is not the process's\n".utf8))
        exit(3)
    }
    post(.mouseMoved, point)
    let command = arguments.count > 5 && arguments[5] == "cmd"
    let modifiers: CGEventFlags = command ? .maskCommand : []
    // ⌘ is held for real (its key down and up), as the click alone does not carry it reliably.
    let commandKey = { (down: Bool) in
        let event = CGEvent(keyboardEventSource: CGEventSource(stateID: .hidSystemState), virtualKey: 55,
                            keyDown: down)
        event?.flags = down ? .maskCommand : []
        event?.post(tap: .cghidEventTap)
        usleep(40_000)
    }
    if command { commandKey(true) }
    post(.leftMouseDown, point, flags: modifiers)
    if arguments[1] == "safeclick" { post(.leftMouseUp, point, flags: modifiers) }
    if command { commandKey(false) }
case "activate":
    let pid = pid_t(arguments[2]) ?? 0
    let application = AXUIElementCreateApplication(pid)
    AXUIElementSetAttributeValue(application, kAXFrontmostAttribute as CFString, kCFBooleanTrue)
    var windows: CFTypeRef?
    if AXUIElementCopyAttributeValue(application, kAXWindowsAttribute as CFString, &windows) == .success,
       let first = (windows as? [AXUIElement])?.first {
        AXUIElementPerformAction(first, kAXRaiseAction as CFString)
    }
    usleep(300_000)
    exit(NSWorkspace.shared.frontmostApplication?.processIdentifier == pid ? 0 : 1)
case "screensize":
    let size = NSScreen.screens.first?.frame.size ?? .zero
    print("\(Int(size.width)) \(Int(size.height))")
case "backdrop":
    let grey = CGFloat(number(2))
    let application = NSApplication.shared
    application.setActivationPolicy(.accessory)
    var backdrops: [NSWindow] = []
    for screen in NSScreen.screens {
        let window = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.backgroundColor = NSColor(white: grey, alpha: 1)
        window.ignoresMouseEvents = true
        window.level = .normal
        window.setFrame(screen.frame, display: true)
        window.orderFrontRegardless()
        backdrops.append(window)
    }
    application.activate(ignoringOtherApps: true)
    print("ready")
    fflush(stdout)
    application.run()
case "frontmost":
    print(NSWorkspace.shared.frontmostApplication?.processIdentifier ?? 0)
case "key":
    send(keyEvents(code: CGKeyCode(arguments[3]) ?? 0, modifiers: flags(arguments.count > 4 ? arguments[4] : "")),
         to: pid_t(arguments[2]) ?? 0)
case "type":
    typeText(arguments[3], to: pid_t(arguments[2]) ?? 0)
case "hidkey":
    send(keyEvents(code: CGKeyCode(arguments[2]) ?? 0, modifiers: flags(arguments.count > 3 ? arguments[3] : "")),
         to: nil)
case "hidtype":
    typeText(arguments[2], to: nil)
case "windows":
    let pid = Int(arguments[2]) ?? 0
    let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
    for window in list where (window[kCGWindowOwnerPID as String] as? Int) == pid {
        let bounds = window[kCGWindowBounds as String] as? [String: Double] ?? [:]
        let line: [String: Any] = [
            "id": window[kCGWindowNumber as String] as? Int ?? 0,
            "layer": window[kCGWindowLayer as String] as? Int ?? 0,
            "name": window[kCGWindowName as String] as? String ?? "",
            "x": bounds["X"] ?? 0, "y": bounds["Y"] ?? 0,
            "width": bounds["Width"] ?? 0, "height": bounds["Height"] ?? 0,
        ]
        let data = try JSONSerialization.data(withJSONObject: line, options: [.sortedKeys])
        print(String(decoding: data, as: UTF8.self))
    }
case "move":
    post(.mouseMoved, CGPoint(x: number(2), y: number(3)))
case "click":
    let point = CGPoint(x: number(2), y: number(3))
    post(.mouseMoved, point)
    post(.leftMouseDown, point)
    post(.leftMouseUp, point)
case "cmdclick":
    let point = CGPoint(x: number(2), y: number(3))
    post(.mouseMoved, point)
    post(.leftMouseDown, point, flags: .maskCommand)
    post(.leftMouseUp, point, flags: .maskCommand)
case "down":
    let point = CGPoint(x: number(2), y: number(3))
    post(.mouseMoved, point)
    post(.leftMouseDown, point)
case "up":
    let point = CGPoint(x: number(2), y: number(3))
    let start = CGEvent(source: nil)?.location ?? point
    for step in 1...8 {
        let t = Double(step) / 8
        post(.leftMouseDragged, CGPoint(x: start.x + (point.x - start.x) * t, y: start.y + (point.y - start.y) * t))
    }
    post(.leftMouseUp, point)
case "rightclick":
    let point = CGPoint(x: number(2), y: number(3))
    post(.mouseMoved, point, .right)
    post(.rightMouseDown, point, .right)
    post(.rightMouseUp, point, .right)
case "find", "findin":
    let inFile = arguments[1] == "findin"
    let rect = inFile ? CGRect.zero : CGRect(x: number(2), y: number(3), width: number(4), height: number(5))
    // Recognition reads "…" as "..." and may vary the case: compare loosely.
    func loose(_ text: String) -> String {
        text.replacingOccurrences(of: "…", with: "...").replacingOccurrences(of: " ", with: "").lowercased()
    }
    let wanted = loose(arguments[inFile ? 3 : 6])
    // Small titles are sometimes misread by a letter ("Ztorge"): allow one wrong letter in
    // eight.
    func distance(_ a: String, _ b: String) -> Int {
        let a = Array(a), b = Array(b)
        var row = Array(0...b.count)
        for i in 1...max(a.count, 1) where !a.isEmpty {
            var previous = row[0]
            row[0] = i
            for j in stride(from: 1, through: b.count, by: 1) {
                let current = row[j]
                row[j] = min(row[j] + 1, row[j - 1] + 1, previous + (a[i - 1] == b[j - 1] ? 0 : 1))
                previous = current
            }
        }
        return a.isEmpty ? b.count : row[b.count]
    }
    let tolerance = max(1, wanted.count / 8)
    let file = inFile ? URL(fileURLWithPath: arguments[2])
        : FileManager.default.temporaryDirectory.appendingPathComponent("zforge-find-\(getpid()).png")
    if !inFile {
        let capture = Process()
        capture.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        capture.arguments = ["-x", "-R", "\(Int(rect.minX)),\(Int(rect.minY)),\(Int(rect.width)),\(Int(rect.height))",
                             file.path]
        try? capture.run()
        capture.waitUntilExit()
    }
    // exit() skips `defer`: every way out of this case removes the screen capture first.
    func finish(_ code: Int32) -> Never {
        if !inFile { try? FileManager.default.removeItem(at: file) }
        exit(code)
    }
    guard FileManager.default.fileExists(atPath: file.path) else { finish(1) }
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.recognitionLanguages = ["pt-BR", "en-US"]
    request.usesLanguageCorrection = false
    guard (try? VNImageRequestHandler(url: file).perform([request])) != nil else { finish(1) }
    for observation in request.results ?? [] {
        // A menu item's icon may be read as a character before its title.
        guard observation.topCandidates(3).contains(where: {
            let line = loose($0.string)
            return distance(line, wanted) <= tolerance
                || (line.count > wanted.count && line.count <= wanted.count + 2
                    && distance(String(line.suffix(wanted.count)), wanted) <= tolerance)
        }) else { continue }
        // Vision's boxes are normalized, with the origin at the bottom left.
        let box = observation.boundingBox
        var frame = rect
        if inFile, let source = CGImageSourceCreateWithURL(file as CFURL, nil),
           let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] {
            frame = CGRect(x: 0, y: 0, width: properties[kCGImagePropertyPixelWidth] as? Double ?? 0,
                           height: properties[kCGImagePropertyPixelHeight] as? Double ?? 0)
        }
        print(String(format: "%.1f %.1f %.1f %.1f", frame.minX + box.minX * frame.width,
                     frame.minY + (1 - box.maxY) * frame.height, box.width * frame.width, box.height * frame.height))
        finish(0)
    }
    // Not found: the lines that were read, for the caller's error message.
    for observation in request.results ?? [] {
        FileHandle.standardError.write(Data("\(observation.topCandidates(1).first?.string ?? "")\n".utf8))
    }
    finish(1)
case "compose":
    let width = Int(number(3)), height = Int(number(4))
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                            space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    var index = 5
    while index + 2 < arguments.count {
        let url = URL(fileURLWithPath: arguments[index]) as CFURL
        guard let source = CGImageSourceCreateWithURL(url, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { exit(1) }
        let x = number(index + 1), y = number(index + 2)
        context.draw(image, in: CGRect(x: x, y: Double(height) - y - Double(image.height),
                                       width: Double(image.width), height: Double(image.height)))
        index += 3
    }
    let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: arguments[2]) as CFURL,
                                                      "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, context.makeImage()!, nil)
    exit(CGImageDestinationFinalize(destination) ? 0 : 1)
case "maskalpha":
    func load(_ path: String) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
    guard let screen = load(arguments[2]), let window = load(arguments[3]),
          screen.width == window.width, screen.height == window.height else { exit(1) }
    let width = screen.width, height = screen.height
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    func pixels(_ image: CGImage) -> [UInt8] {
        var data = [UInt8](repeating: 0, count: width * height * 4)
        let context = CGContext(data: &data, width: width, height: height, bitsPerComponent: 8,
                                bytesPerRow: width * 4, space: space,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return data
    }
    var a = pixels(screen)
    let b = pixels(window)
    for i in stride(from: 0, to: a.count, by: 4) {
        let alpha = UInt16(b[i + 3])
        for c in 0..<3 { a[i + c] = UInt8(UInt16(a[i + c]) * alpha / 255) }
        a[i + 3] = UInt8(alpha)
    }
    let context = CGContext(data: &a, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                            space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: arguments[4]) as CFURL,
                                                      "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, context.makeImage()!, nil)
    exit(CGImageDestinationFinalize(destination) ? 0 : 1)
case "ocr":
    guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: arguments[2]) as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { exit(1) }
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.recognitionLanguages = ["pt-BR", "en-US"]
    request.usesLanguageCorrection = false
    try? VNImageRequestHandler(cgImage: image).perform([request])
    let width = Double(image.width), height = Double(image.height)
    for observation in request.results ?? [] {
        guard let text = observation.topCandidates(1).first?.string else { continue }
        let box = observation.boundingBox
        let line: [String: Any] = ["text": text, "x": box.minX * width, "y": (1 - box.maxY) * height,
                                   "width": box.width * width, "height": box.height * height]
        print(String(decoding: try! JSONSerialization.data(withJSONObject: line, options: [.sortedKeys]), as: UTF8.self))
    }
case "crop":
    guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: arguments[2]) as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
          let part = image.cropping(to: CGRect(x: number(4), y: number(5), width: number(6), height: number(7)))
    else { exit(1) }
    let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: arguments[3]) as CFURL,
                                                      "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, part, nil)
    exit(CGImageDestinationFinalize(destination) ? 0 : 1)
case "pointer":
    let point = CGEvent(source: nil)?.location ?? .zero
    print("\(point.x) \(point.y)")
default:
    FileHandle.standardError.write(Data("usage: screen_tool windows <pid> | move|click|cmdclick|rightclick|down|up <x> <y> | pointer\n".utf8))
    exit(2)
}
