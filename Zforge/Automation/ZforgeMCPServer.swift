import Foundation
import MCP

/// Only the SDK transport writes stdout. Ordinary application startup is bypassed in --mcp mode.
nonisolated enum ZforgeMCPServer {
    static let instructions = "Zforge manages local files and archives. First call get_capabilities. Missing folder access opens a native authorization picker for the local user; wait for consent or cancellation. Already allowed folders require no prompt. Settings > Automation manages persisted grants. Use absolute paths. Compression and extraction require a NEW destination and never replace items. Jobs return an operation_id; poll operation_status until terminal. Do not retry a started job without checking its status. Jobs and their last 64 results belong to this connection; disconnect cancels running work. Destructive archive editing is not exposed."

    static func make(operations: AutomationOperations) async -> Server {
        let server = Server(name: "Zforge", version: "1.0.0", instructions: instructions,
                            capabilities: .init(tools: .init()), configuration: .strict)
        await server.withMethodHandler(ListTools.self) { _ in .init(tools: tools) }
        await server.withMethodHandler(CallTool.self) { params in
            await call(name: params.name, arguments: params.arguments ?? [:], operations: operations)
        }
        return server
    }

    static func run() async {
        let operations = AutomationOperations(access: ContextualAutomationAccess.shared)
        let server = await make(operations: operations)
        do {
            try await server.start(transport: StdioTransport())
            await server.waitUntilCompleted()
        } catch {
            // No arguments, paths, passwords or native engine diagnostic payloads in transport logs.
            FileHandle.standardError.write(Data("Zforge MCP transport failed.\n".utf8))
        }
        await operations.shutdown()
        await ContextualAutomationAccess.shared.cancelPending()
        await server.stop()
    }

    static let tools: [Tool] = [
        tool("get_capabilities", "Discover Zforge tools, limits, authorization setup and connection behavior.", properties: [:], required: [], readOnly: true),
        tool("list_directory", "List direct children of an authorized folder, sorted by path. Offset pagination is live; restart at zero if the folder changes.",
             properties: ["path": path, "show_hidden": .object(["type": "boolean"]), "offset": offset, "limit": limit], required: ["path"], readOnly: true),
        tool("list_archive", "List direct archive children. internal_path is relative to the archive root. Pagination is live; restart if the archive changes.",
             properties: ["path": path, "internal_path": string, "password": string, "offset": offset, "limit": limit], required: ["path"], readOnly: true),
        tool("compress", "Start ZIP or 7z compression of 1–256 authorized sources into a NEW archive. Returns a job; inspect operation_status. Existing items are never replaced.",
             properties: ["sources": .object(["type": "array", "items": path, "minItems": 1, "maxItems": 256]), "destination": path,
                          "format": .object(["type": "string", "enum": ["zip", "7z"]])], required: ["sources", "destination", "format"], readOnly: false),
        tool("extract", "Start extraction of an authorized archive into a NEW folder. Returns a job; inspect operation_status. Cancellation/failure can leave partial output, reported in output_path.",
             properties: ["archive": path, "destination": path, "password": string], required: ["archive", "destination"], readOnly: false),
        tool("test_archive", "Start an archive integrity test. Poll the returned job until succeeded or failed; password is optional.",
             properties: ["archive": path, "password": string], required: ["archive"], readOnly: true),
        tool("operation_status", "Get current progress and terminal outcome for a job from THIS connection. Result includes output_path and a stable error_code when applicable.",
             properties: ["operation_id": string], required: ["operation_id"], readOnly: true),
        tool("cancel_operation", "Request cancellation of a job from THIS connection. Poll until cancelled or another terminal state; partial extraction output may remain.",
             properties: ["operation_id": string], required: ["operation_id"], readOnly: false)
    ]

    private static let string: Value = .object(["type": "string"])
    private static let path: Value = .object(["type": "string", "description": "Absolute local filesystem path inside an explicitly authorized automation folder."])
    private static let offset: Value = .object(["type": "integer", "minimum": 0])
    private static let limit: Value = .object(["type": "integer", "minimum": 1, "maximum": 200, "default": 100])

    private static func tool(_ name: String, _ description: String, properties: [String: Value], required: [String], readOnly: Bool) -> Tool {
        Tool(name: name, description: description,
             inputSchema: .object(["type": "object", "properties": .object(properties),
                                   "required": .array(required.map(Value.string)), "additionalProperties": false]),
             annotations: .init(readOnlyHint: readOnly, destructiveHint: false, idempotentHint: readOnly && name != "test_archive", openWorldHint: false))
    }

    static func call(name: String, arguments: [String: Value], operations: AutomationOperations) async -> CallTool.Result {
        do {
            guard let definition = tools.first(where: { $0.name == name }),
                  let properties = definition.inputSchema.objectValue?["properties"]?.objectValue,
                  Set(arguments.keys).isSubset(of: Set(properties.keys)) else { throw AutomationError.invalidArguments }
            let input = Arguments(values: arguments)
            switch name {
            case "get_capabilities":
                return try result(Value.object([
                    "server": "Zforge", "api_version": "1.0", "transport": "stdio", "authorization": "Settings > Automation > Allow Folder",
                    "authorized_folders": .array(await operations.authorizedFolders().map(Value.string)),
                    "formats": ["zip", "7z"], "max_active_jobs": 1, "retained_jobs": 64, "max_listing_items": 10000,
                    "page_size": 200, "destructive_actions": false, "instructions": .string(instructions)
                ]))
            case "list_directory":
                return try result(await operations.listDirectory(path: input.required("path"), showHidden: input.boolean("show_hidden", default: false),
                    offset: input.integer("offset", default: 0), limit: input.integer("limit", default: 100)))
            case "list_archive":
                return try result(await operations.listArchive(path: input.required("path"), internalPath: input.optional("internal_path") ?? "",
                    password: input.optional("password"), offset: input.integer("offset", default: 0), limit: input.integer("limit", default: 100)))
            case "compress":
                let format = try input.required("format")
                guard format == "zip" || format == "7z" else { throw AutomationError.invalidArguments }
                return try job(await operations.compress(sources: input.strings("sources"), destination: input.required("destination"),
                    format: format == "zip" ? .zip : .sevenZip))
            case "extract":
                return try job(await operations.extract(archive: input.required("archive"), destination: input.required("destination"), password: input.optional("password")))
            case "test_archive":
                return try job(await operations.test(archive: input.required("archive"), password: input.optional("password")))
            case "operation_status": return try job(await operations.status(input.id()))
            case "cancel_operation": return try job(await operations.cancel(input.id()))
            default: throw AutomationError.invalidArguments
            }
        } catch {
            let code = AutomationOperations.errorCode(error)
            let message: String
            if error is CancellationError {
                message = AppLocalization.string("The automation request was cancelled.")
            } else if let selection = error as? AutomationFolderSelectionError {
                message = selection.errorDescription ?? ""
            } else {
                message = (error as? AutomationError)?.errorDescription ?? AppLocalization.string("The automation operation failed. Check the path, permissions and archive password.")
            }
            return (try? result(Value.object(["error_code": .string(code), "message": .string(message)]), isError: true))
                ?? .init(content: [.text(text: "Automation request failed.", annotations: nil, _meta: nil)], isError: true)
        }
    }

    private static func job(_ job: AutomationOperation) throws -> CallTool.Result {
        var output: [String: Value] = ["operation_id": .string(job.id.uuidString), "kind": .string(job.kind), "state": .string(job.state.rawValue)]
        if let phase = job.phase { output["phase"] = .string(phase) }
        if let fraction = job.fraction { output["fraction"] = .double(fraction) }
        if let path = job.outputPath { output["output_path"] = .string(path) }
        if let error = job.errorCode { output["error_code"] = .string(error) }
        return try result(Value.object(output))
    }

    private static func result<T: Codable>(_ output: T, isError: Bool = false) throws -> CallTool.Result {
        let value = try Value(output)
        let text = String(decoding: try JSONEncoder().encode(value), as: UTF8.self)
        return .init(content: [.text(text: text, annotations: nil, _meta: nil)], structuredContent: Optional.some(value), isError: isError)
    }

    private struct Arguments {
        let values: [String: Value]
        func required(_ key: String) throws -> String {
            guard let value = try optional(key), !value.isEmpty else { throw AutomationError.invalidArguments }
            return value
        }
        func optional(_ key: String) throws -> String? {
            guard let value = values[key] else { return nil }
            guard case let .string(text) = value, text.utf8.count <= 4096 else { throw AutomationError.invalidArguments }
            return text
        }
        func boolean(_ key: String, default fallback: Bool) throws -> Bool {
            guard let value = values[key] else { return fallback }
            guard case let .bool(flag) = value else { throw AutomationError.invalidArguments }
            return flag
        }
        func integer(_ key: String, default fallback: Int) throws -> Int {
            guard let value = values[key] else { return fallback }
            guard case let .int(number) = value, number >= 0, number <= 10000 else { throw AutomationError.invalidArguments }
            return number
        }
        func strings(_ key: String) throws -> [String] {
            guard case let .array(values)? = values[key], (1...256).contains(values.count) else { throw AutomationError.invalidArguments }
            return try values.map { value in
                guard case let .string(text) = value else { throw AutomationError.invalidArguments }
                return text
            }
        }
        func id() throws -> UUID {
            guard let id = UUID(uuidString: try required("operation_id")) else { throw AutomationError.invalidArguments }
            return id
        }
    }
}
