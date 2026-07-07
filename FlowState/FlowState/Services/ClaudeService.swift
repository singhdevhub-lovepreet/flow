import Foundation
import os

private let log = Logger(subsystem: "com.flowstate.app", category: "ClaudeService")

@Observable
final class ClaudeService: @unchecked Sendable {
    private let claudePath = "/opt/homebrew/bin/claude"
    private(set) var isAvailable: Bool = false
    private(set) var mcpServers: [String] = []
    private(set) var mcpServerConfigs: [String: MCPServerConfig] = [:]

    // Auto-detect a Chromium-based browser for Playwright MCP
    static let detectedBrowserPath: String? = {
        let candidates = [
            "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
            "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser",
            "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
            "/Applications/Chromium.app/Contents/MacOS/Chromium",
        ]
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }()

    // Discover node/npx paths once — macOS apps don't inherit shell PATH (nvm, homebrew, etc.)
    private static let extraPaths: [String] = {
        var paths = ["/opt/homebrew/bin", "/usr/local/bin"]
        // Find active nvm node version
        let nvmDir = NSHomeDirectory() + "/.nvm/versions/node"
        if let versions = try? FileManager.default.contentsOfDirectory(atPath: nvmDir) {
            // Pick the most recent version directory
            if let latest = versions.filter({ $0.hasPrefix("v") }).sorted().last {
                paths.insert(nvmDir + "/\(latest)/bin", at: 0)
            }
        }
        return paths
    }()

    init() {
        isAvailable = FileManager.default.isExecutableFile(atPath: claudePath)
        log.info("Claude CLI available: \(self.isAvailable)")

        if isAvailable {
            mcpServers = discoverMCPServers()
            log.info("Discovered \(self.mcpServers.count) MCP servers: \(self.mcpServers.joined(separator: ", "))")
        } else {
            log.warning("Claude CLI not found at \(self.claudePath) — classification disabled")
        }
    }

    // MARK: - Phase 1: Classify

    func classify(_ taskTitle: String) async throws -> TaskClassification {
        log.info("Classifying task: \"\(taskTitle)\"")
        let serverList = mcpServers.isEmpty ? "none" : mcpServers.joined(separator: ", ")

        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "category": [
                    "type": "string",
                    "enum": ["work", "focus", "entertainment", "communication", "system", "personal", "health"]
                ],
                "is_executable": ["type": "boolean"],
                "mcp_server": ["type": "string"],
                "execution_prompt": ["type": "string"]
            ],
            "required": ["category", "is_executable"]
        ]

        let schemaData = try JSONSerialization.data(withJSONObject: schema)
        let schemaString = String(data: schemaData, encoding: .utf8) ?? "{}"

        // Build dynamic descriptions for custom (non-catalog) servers
        let catalogIDs: Set<String> = ["mac", "browser", "shortcuts", "slack"]
        let customDescriptions = mcpServerConfigs
            .filter { !catalogIDs.contains($0.key) }
            .map { name, config in
                let desc = config.description ?? "Custom MCP server"
                return "- \"\(name)\": \(desc)"
            }
            .sorted()
        let customBlock = customDescriptions.isEmpty ? "" : """
            \nFor other connected servers: \
            \(customDescriptions.joined(separator: " \\\n")) \
            If the task seems relevant to a custom server, set is_executable to true.
            """

        let systemPrompt = """
            You are a task classifier. Do NOT execute, browse, search, or perform any actions. \
            Just classify the task into a category and return structured JSON. \
            Available MCP servers the user has configured: \(serverList). \
            If a task can be executed by one of these MCP servers, \
            set is_executable to true, specify which mcp_server to use, and write a clear execution_prompt. \
            Server capabilities: \
            - "mac": Controls macOS apps via AppleScript — Calendar (create/edit events, check availability), \
            Mail (send/read emails), Finder (open files/folders), Apple Music (play/pause/search songs), \
            System (volume, brightness, dark mode, Do Not Disturb, lock screen), Reminders, Notes. \
            Use this for ANY local Mac automation task. \
            - "browser": Navigate websites, click, type, fill forms in the user's real browser. \
            The user is already logged into their accounts — assume authentication is handled. \
            Use for web interactions (Twitter/X, YouTube, Reddit, etc.). \
            - "shortcuts": Run macOS Shortcuts by name. Use when user says "run my X shortcut". \
            - "slack": Send messages, read channels on Slack. \
            \(customBlock) \
            If a task can be executed by one of these servers, set is_executable to true. \
            Prefer "mac" for local Mac tasks. Prefer "browser" for web tasks. \
            Otherwise set is_executable to false.
            """

        let args = [
            claudePath,
            "-p",
            "--model", "sonnet",
            "--output-format", "json",
            "--json-schema", schemaString,
            "--system-prompt", systemPrompt,
            "--tools", ""
        ]

        log.debug("Running classify command, prompt via stdin: \"\(taskTitle)\"")
        let output = try await runProcess(args: args, stdinContent: taskTitle, environment: ["ENABLE_TOOL_SEARCH": "false"])
        log.debug("Classify raw output: \(output.prefix(500))")

        let responseData = Data(output.utf8)
        let response = try JSONDecoder().decode(ClaudeResponse.self, from: responseData)

        if response.is_error {
            let msg = response.result ?? "Unknown error"
            log.error("Classification returned error: \(msg)")
            throw ClaudeError.classificationFailed(msg)
        }

        // Check if budget was exceeded before getting a result
        if response.subtype == "error_max_budget_usd" {
            log.warning("Classification hit budget limit, attempting to parse partial output")
        }

        if let classification = response.structured_output {
            log.info("Classified as: \(classification.category), executable: \(classification.isExecutable), server: \(classification.mcpServer ?? "none")")
            return classification
        }

        // Fallback: try parsing result string directly
        if let resultString = response.result, !resultString.isEmpty {
            log.debug("No structured_output, falling back to parsing result string")
            let resultData = Data(resultString.utf8)
            let classification = try JSONDecoder().decode(TaskClassification.self, from: resultData)
            log.info("Classified (fallback) as: \(classification.category), executable: \(classification.isExecutable)")
            return classification
        }

        log.error("No structured_output and no result string — classification produced no usable output")
        throw ClaudeError.classificationFailed("No output from Claude (subtype: \(response.subtype ?? "unknown"))")
    }

    // MARK: - Phase 2: Execute

    func execute(_ prompt: String, mcpServer: String) async throws -> ExecutionResult {
        log.info("Executing via MCP server '\(mcpServer)': \"\(prompt)\"")

        let systemPrompt = """
            You MUST use the available MCP tools to complete this task. \
            Do NOT respond with text explaining what you would do — actually do it using tool calls. \
            NEVER ask the user for confirmation, clarification, or follow-up questions. \
            You are running autonomously — there is no way for the user to reply. \
            Make reasonable assumptions and COMPLETE the task fully. \
            For calendar events, use the task description as the title and default to 30 minutes if no duration is specified. \
            IMPORTANT: Run everything SILENTLY in the background. The user should not be interrupted. \
            For AppleScript: NEVER use "activate" to bring apps to the foreground. \
            Do NOT open app windows. Use scripting commands that work in the background. \
            For example, use "tell application \\"Calendar\\"" without "activate", \
            use "tell application \\"Music\\" to play" without bringing Music to front. \
            For browser tasks: work in the current tab or a background tab, do not steal window focus. \
            The user is already logged into their accounts in the browser — do not worry about authentication. \
            You are connected to the user's real browser with all their logged-in sessions. \
            If the MCP tools are not available or fail, respond with exactly: EXECUTION_FAILED
            """

        // Allow Bash for the "mac" server — some automation needs shell fallback
        let allowedTools = mcpServer == "mac"
            ? "mcp__\(mcpServer)__*,Bash"
            : "mcp__\(mcpServer)__*"

        // Build a minimal MCP config with only the target server to avoid starting other servers
        // (e.g., Playwright opens a browser window on startup even when not used)
        let mcpConfig = buildSingleServerConfig(for: mcpServer)

        let args = [
            claudePath,
            "-p",
            "--model", "sonnet",
            "--output-format", "json",
            "--mcp-config", mcpConfig,
            "--allowedTools", allowedTools,
            "--dangerously-skip-permissions",
            "--append-system-prompt", systemPrompt,
            prompt
        ]

        log.debug("Running execute command, allowed tools: \(allowedTools)")
        let output = try await runProcess(args: args, environment: ["ENABLE_TOOL_SEARCH": "false"])
        log.debug("Execute raw output: \(output.prefix(500))")

        let responseData = Data(output.utf8)
        let result = try JSONDecoder().decode(ExecutionResult.self, from: responseData)

        if result.is_error {
            let msg = result.result ?? "Unknown execution error"
            log.error("Execution failed (is_error): \(msg)")
            throw ClaudeError.executionFailed(msg)
        }

        // If only 1 turn, Claude never called any tools — it just responded with text
        let turns = result.num_turns ?? 0
        if turns <= 1 {
            let response = result.result ?? ""
            log.error("Execution did nothing — \(turns) turns, no tool calls. Response: \(response.prefix(200))")
            throw ClaudeError.executionFailed("MCP server '\(mcpServer)' tools not available — no tool calls were made")
        }

        // Check if Claude explicitly reported failure
        if let response = result.result, response.contains("EXECUTION_FAILED") {
            log.error("Execution reported failure via sentinel")
            throw ClaudeError.executionFailed("MCP server '\(mcpServer)' could not complete the task")
        }

        log.info("Execution succeeded for server '\(mcpServer)' in \(turns) turns: \(result.result?.prefix(200) ?? "(no output)")")
        return result
    }

    // MARK: - MCP Server Discovery

    private func discoverMCPServers() -> [String] {
        let settingsPath = NSHomeDirectory() + "/.claude/settings.json"
        log.debug("Reading MCP config from: \(settingsPath)")

        guard let data = FileManager.default.contents(atPath: settingsPath) else {
            log.warning("No settings.json found at \(settingsPath)")
            return []
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let servers = json["mcpServers"] as? [String: Any] else {
            log.warning("Failed to parse mcpServers from settings.json")
            return []
        }

        for (name, config) in servers {
            if let configDict = config as? [String: Any] {
                let command = configDict["command"] as? String ?? "unknown"
                let args = configDict["args"] as? [String] ?? []
                let env = configDict["env"] as? [String: String] ?? [:]
                let description = configDict["_flowstate_description"] as? String
                mcpServerConfigs[name] = MCPServerConfig(
                    command: command,
                    args: args,
                    env: env,
                    description: description
                )
                log.info("Found MCP server: \(name) (command: \(command))")
            }
        }

        return Array(servers.keys).sorted()
    }

    // MARK: - Add / Remove MCP Servers

    private var settingsPath: String {
        NSHomeDirectory() + "/.claude/settings.json"
    }

    func addServer(name: String, command: String, args: [String], env: [String: String] = [:], description: String? = nil) {
        log.info("Adding MCP server '\(name)' to settings.json")

        var root = readSettingsFile()

        var servers = root["mcpServers"] as? [String: Any] ?? [:]
        var entry: [String: Any] = [
            "command": command,
            "args": args
        ]
        if !env.isEmpty {
            entry["env"] = env
        }
        if let description, !description.isEmpty {
            entry["_flowstate_description"] = description
        }
        servers[name] = entry
        root["mcpServers"] = servers

        writeSettingsFile(root)
        reloadServers()
        log.info("MCP server '\(name)' added successfully")
    }

    func removeServer(name: String) {
        log.info("Removing MCP server '\(name)' from settings.json")

        var root = readSettingsFile()
        var servers = root["mcpServers"] as? [String: Any] ?? [:]
        servers.removeValue(forKey: name)
        root["mcpServers"] = servers

        writeSettingsFile(root)
        reloadServers()
        log.info("MCP server '\(name)' removed")
    }

    func isServerConnected(_ name: String) -> Bool {
        mcpServers.contains(name)
    }

    func reloadServers() {
        mcpServerConfigs = [:]
        mcpServers = discoverMCPServers()
        log.info("Reloaded servers: \(self.mcpServers.joined(separator: ", "))")
    }

    private func readSettingsFile() -> [String: Any] {
        let fm = FileManager.default

        // Ensure ~/.claude directory exists
        let dir = (settingsPath as NSString).deletingLastPathComponent
        if !fm.fileExists(atPath: dir) {
            try? fm.createDirectory(atPath: dir, withIntermediateDirectories: true)
        }

        guard let data = fm.contents(atPath: settingsPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return json
    }

    private func writeSettingsFile(_ root: [String: Any]) {
        do {
            let data = try JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: URL(fileURLWithPath: settingsPath))
        } catch {
            log.error("Failed to write settings.json: \(error.localizedDescription)")
        }
    }

    // MARK: - Single-Server MCP Config

    /// Writes a temporary JSON config containing only the target MCP server.
    /// This prevents other servers (e.g. Playwright) from starting and opening windows.
    private func buildSingleServerConfig(for serverName: String) -> String {
        let root = readSettingsFile()
        guard let allServers = root["mcpServers"] as? [String: Any],
              let serverEntry = allServers[serverName] else {
            // Fallback to full config if server not found
            log.warning("Server '\(serverName)' not found in settings — falling back to full config")
            return settingsPath
        }

        let singleConfig: [String: Any] = ["mcpServers": [serverName: serverEntry]]
        let tempPath = NSTemporaryDirectory() + "flowstate-mcp-\(serverName).json"
        do {
            let data = try JSONSerialization.data(withJSONObject: singleConfig, options: [.prettyPrinted])
            try data.write(to: URL(fileURLWithPath: tempPath))
            log.debug("Wrote single-server config for '\(serverName)' to \(tempPath)")
            return tempPath
        } catch {
            log.error("Failed to write single-server config: \(error.localizedDescription)")
            return settingsPath
        }
    }

    // MARK: - Process Runner

    private func runProcess(args: [String], stdinContent: String? = nil, environment: [String: String] = [:]) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let outPipe = Pipe()

            process.executableURL = URL(fileURLWithPath: args[0])
            process.arguments = Array(args.dropFirst())
            process.standardOutput = outPipe
            process.standardError = outPipe

            // Pipe prompt via stdin if provided
            if let content = stdinContent {
                let inPipe = Pipe()
                process.standardInput = inPipe
                let inputData = Data(content.utf8)
                inPipe.fileHandleForWriting.write(inputData)
                inPipe.fileHandleForWriting.closeFile()
            }

            var env = ProcessInfo.processInfo.environment
            for (key, value) in environment {
                env[key] = value
            }

            // Ensure node/npx are in PATH — macOS apps don't inherit shell PATH
            let currentPath = env["PATH"] ?? "/usr/bin:/bin"
            env["PATH"] = (Self.extraPaths + [currentPath]).joined(separator: ":")

            process.environment = env

            process.terminationHandler = { proc in
                let data = outPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""

                if proc.terminationStatus != 0 && output.isEmpty {
                    log.error("Process exited with code \(proc.terminationStatus), no output")
                    continuation.resume(throwing: ClaudeError.processError(Int(proc.terminationStatus)))
                } else {
                    if proc.terminationStatus != 0 {
                        log.warning("Process exited with code \(proc.terminationStatus) but produced output")
                    }
                    continuation.resume(returning: output)
                }
            }

            do {
                try process.run()
            } catch {
                log.error("Failed to launch process: \(error.localizedDescription)")
                continuation.resume(throwing: ClaudeError.launchFailed(error))
            }
        }
    }
}

struct MCPServerConfig {
    let command: String
    let args: [String]
    var env: [String: String]
    var description: String?
}

enum ClaudeError: LocalizedError {
    case classificationFailed(String)
    case executionFailed(String)
    case processError(Int)
    case launchFailed(Error)

    var errorDescription: String? {
        switch self {
        case .classificationFailed(let msg): "Classification failed: \(msg)"
        case .executionFailed(let msg): "Execution failed: \(msg)"
        case .processError(let code): "Process exited with code \(code)"
        case .launchFailed(let error): "Failed to launch Claude: \(error.localizedDescription)"
        }
    }
}
