import SwiftUI
import os

private let log = Logger(subsystem: "com.flowstate.app", category: "MCPsView")

// MARK: - MCP Server Catalog Definition

struct MCPCatalogEntry: Identifiable {
    let id: String
    let displayName: String
    let description: String
    let icon: String
    let color: Color
    /// Path to a macOS .app bundle to load its real icon (e.g. "/System/Applications/Calendar.app")
    let appIconPath: String?
    let command: String
    let args: [String]
    let requiredEnvVars: [EnvVarField]
    let setupSteps: [SetupStep]

    struct EnvVarField: Identifiable {
        let id: String
        let label: String
        let placeholder: String
        let isSecret: Bool
    }

    struct SetupStep: Identifiable {
        let id = UUID()
        let instruction: String
        let linkLabel: String?
        let linkURL: String?

        init(_ instruction: String, linkLabel: String? = nil, linkURL: String? = nil) {
            self.instruction = instruction
            self.linkLabel = linkLabel
            self.linkURL = linkURL
        }
    }
}

private let catalog: [MCPCatalogEntry] = [
    MCPCatalogEntry(
        id: "mac",
        displayName: "Mac Automator",
        description: "Calendar, Mail, Finder, Apple Music, System controls, and 200+ actions",
        icon: "desktopcomputer",
        color: .orange,
        appIconPath: "/System/Applications/Automator.app",
        command: "npx",
        args: ["-y", "@steipete/macos-automator-mcp"],
        requiredEnvVars: [],
        setupSteps: [
            .init("Open System Settings → Privacy & Security → Accessibility and grant access to Terminal (or iTerm).",
                  linkLabel: "Open Accessibility Settings",
                  linkURL: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"),
            .init("When prompted, allow Automation access for apps like Calendar, Mail, and Reminders."),
            .init("That's it! Claude can now control Calendar, Mail, Finder, Apple Music, System Settings, and 200+ more actions."),
        ]
    ),
    MCPCatalogEntry(
        id: "browser",
        displayName: "Web Browser",
        description: "Browse the web, interact with pages, use your logged-in sessions",
        icon: "globe",
        color: .blue,
        appIconPath: "/Applications/Safari.app",
        command: "npx",
        args: ["-y", "@playwright/mcp@latest", "--extension"],
        requiredEnvVars: [],
        setupSteps: [
            .init("Install the Playwright browser extension in Chrome, Brave, or Edge.",
                  linkLabel: "Install Extension", linkURL: "https://chromewebstore.google.com/detail/playwright-extension/mmlmfjhmonkocbjadbfplnigmagldckm"),
            .init("Make sure Node.js is installed on your system.",
                  linkLabel: "Download Node.js", linkURL: "https://nodejs.org"),
            .init("That's it! FlowState will connect to your open browser and use your existing sessions."),
        ]
    ),
    MCPCatalogEntry(
        id: "shortcuts",
        displayName: "Apple Shortcuts",
        description: "Run any macOS Shortcut by name — automate custom workflows",
        icon: "square.grid.3x3.topleft.filled",
        color: .pink,
        appIconPath: "/System/Applications/Shortcuts.app",
        command: "npx",
        args: ["-y", "mcp-server-apple-shortcuts"],
        requiredEnvVars: [],
        setupSteps: [
            .init("Create Shortcuts in the macOS Shortcuts app — any shortcut you create will be available to Claude.",
                  linkLabel: "Open Shortcuts", linkURL: "shortcuts://"),
            .init("No additional permissions needed. Claude will see and run your shortcuts by name."),
        ]
    ),
    MCPCatalogEntry(
        id: "slack",
        displayName: "Slack",
        description: "Send messages, read channels — no bot or admin approval needed",
        icon: "number",
        color: .purple,
        appIconPath: "/Applications/Slack.app",
        command: "npx",
        args: ["-y", "slack-mcp-server"],
        requiredEnvVars: [
            .init(id: "SLACK_MCP_XOXC_TOKEN", label: "xoxc Token", placeholder: "xoxc-...", isSecret: true),
            .init(id: "SLACK_MCP_XOXD_TOKEN", label: "xoxd Token", placeholder: "xoxd-...", isSecret: true),
        ],
        setupSteps: [
            .init("Open Slack in your browser and log in to your workspace.",
                  linkLabel: "Open Slack", linkURL: "https://app.slack.com"),
            .init("Open browser DevTools (F12) → Application → Cookies → slack.com. Copy the \"d\" cookie value — this is your xoxd token."),
            .init("In DevTools → Network, find any Slack API request, look for the \"token\" parameter starting with \"xoxc-\". This is your xoxc token."),
            .init("No Slack bot or admin approval needed — this uses your existing browser session."),
        ]
    ),
]

// MARK: - MCPs View

struct MCPsView: View {
    @Environment(ClaudeService.self) private var claudeService
    @State private var connectingEntry: MCPCatalogEntry?
    @State private var envValues: [String: String] = [:]

    private var connectedCount: Int {
        catalog.filter { claudeService.isServerConnected($0.id) }.count
    }

    var body: some View {
        ZStack {
            // Main content
            mainContent
                .opacity(connectingEntry == nil ? 1 : 0)
                .allowsHitTesting(connectingEntry == nil)

            // Inline connect panel (replaces .sheet which breaks NSPanel)
            if let entry = connectingEntry {
                connectOverlay(entry: entry)
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: connectingEntry?.id)
        .onAppear {
            log.info("MCPs tab opened — \(connectedCount)/\(catalog.count) connected")
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ZStack(alignment: .topLeading) {
            GhostTextView(
                text: "\(connectedCount)",
                font: FSTypography.monoFallbackLarge
            )
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, FSSpacing.screenPadding)
            .padding(.top, 8)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: FSSpacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Integrations")
                            .font(FSTypography.displayFallbackMD)
                            .foregroundStyle(FSColors.textPrimary)
                        Text("\(connectedCount) of \(catalog.count) connected")
                            .font(FSTypography.uiCaption)
                            .foregroundStyle(FSColors.textSecondary)
                    }

                    if !claudeService.isAvailable {
                        unavailableCard
                    } else {
                        // Server catalog
                        VStack(spacing: 0) {
                            ForEach(Array(catalog.enumerated()), id: \.element.id) { index, entry in
                                let connected = claudeService.isServerConnected(entry.id)
                                MCPCatalogRow(
                                    entry: entry,
                                    isConnected: connected,
                                    onConnect: {
                                        envValues = [:]
                                        connectingEntry = entry
                                    },
                                    onDisconnect: {
                                        log.info("Disconnecting '\(entry.id)'")
                                        claudeService.removeServer(name: entry.id)
                                    }
                                )
                                if index < catalog.count - 1 {
                                    Divider()
                                        .background(FSColors.bgCardBorder)
                                        .padding(.horizontal, FSSpacing.md)
                                }
                            }
                        }
                        .cardStyle()

                        // Extra servers from settings.json not in catalog
                        let extraServers = claudeService.mcpServers.filter { name in
                            !catalog.contains { $0.id == name }
                        }
                        if !extraServers.isEmpty {
                            VStack(alignment: .leading, spacing: FSSpacing.sm) {
                                SectionLabel(text: "Other Servers")
                                VStack(spacing: 0) {
                                    ForEach(extraServers, id: \.self) { server in
                                        ExtraServerRow(
                                            name: server,
                                            config: claudeService.mcpServerConfigs[server]
                                        )
                                        if server != extraServers.last {
                                            Divider()
                                                .background(FSColors.bgCardBorder)
                                                .padding(.horizontal, FSSpacing.md)
                                        }
                                    }
                                }
                                .cardStyle()
                            }
                        }

                        // Info
                        VStack(alignment: .leading, spacing: FSSpacing.xs) {
                            SectionLabel(text: "How it works")
                            Text("Connected integrations let Claude auto-execute tasks. Add \"Schedule lunch tomorrow at noon\" or \"Play Bohemian Rhapsody\" and it runs automatically.")
                                .font(.system(size: 11))
                                .foregroundStyle(FSColors.textMuted)
                                .lineSpacing(3)
                        }
                    }
                }
                .screenPadding()
                .padding(.top, FSSpacing.md)
                .padding(.bottom, FSSpacing.md)
            }
        }
    }

    // MARK: - Connect Overlay

    private func connectOverlay(entry: MCPCatalogEntry) -> some View {
        VStack(spacing: 0) {
            // Header with back button
            HStack {
                Button {
                    connectingEntry = nil
                    envValues = [:]
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 13))
                    }
                    .foregroundStyle(FSColors.textSecondary)
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal, FSSpacing.screenPadding)
            .padding(.top, FSSpacing.md)
            .padding(.bottom, FSSpacing.sm)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: FSSpacing.lg) {
                    // Icon + title
                    HStack(spacing: 12) {
                        AppIconView(entry: entry, size: 44)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.displayName)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(FSColors.textPrimary)
                            Text(entry.description)
                                .font(.system(size: 12))
                                .foregroundStyle(FSColors.textSecondary)
                        }
                    }

                    // Setup steps
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(entry.setupSteps.enumerated()), id: \.element.id) { index, step in
                            HStack(alignment: .top, spacing: 12) {
                                // Step number
                                Text("\(index + 1)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(entry.color)
                                    .frame(width: 22, height: 22)
                                    .background(entry.color.opacity(0.12))
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(step.instruction)
                                        .font(.system(size: 12))
                                        .foregroundStyle(FSColors.textPrimary)
                                        .lineSpacing(3)
                                        .fixedSize(horizontal: false, vertical: true)

                                    if let label = step.linkLabel, let urlString = step.linkURL,
                                       let url = URL(string: urlString) {
                                        Link(destination: url) {
                                            HStack(spacing: 4) {
                                                Image(systemName: "arrow.up.right.square")
                                                    .font(.system(size: 10))
                                                Text(label)
                                                    .font(.system(size: 11, weight: .medium))
                                            }
                                            .foregroundStyle(entry.color)
                                        }
                                    }
                                }

                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, 10)

                            if index < entry.setupSteps.count - 1 {
                                // Connector line between steps
                                HStack(spacing: 12) {
                                    Rectangle()
                                        .fill(entry.color.opacity(0.2))
                                        .frame(width: 1)
                                        .frame(height: 8)
                                        .padding(.leading, 10.5) // center under the circle
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(FSSpacing.md)
                    .background(FSColors.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(FSColors.bgCardBorder, lineWidth: 1)
                    )

                    // Credential fields (if any)
                    if !entry.requiredEnvVars.isEmpty {
                        VStack(alignment: .leading, spacing: FSSpacing.md) {
                            ForEach(entry.requiredEnvVars) { field in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(field.label)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(FSColors.textSecondary)

                                    let binding = Binding<String>(
                                        get: { envValues[field.id, default: ""] },
                                        set: { envValues[field.id] = $0 }
                                    )

                                    Group {
                                        if field.isSecret {
                                            SecureField(field.placeholder, text: binding)
                                        } else {
                                            TextField(field.placeholder, text: binding)
                                        }
                                    }
                                    .font(.system(size: 12))
                                    .textFieldStyle(.plain)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(FSColors.bgCard)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(FSColors.bgCardBorder, lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }

                    // Connect button
                    let hasAll = entry.requiredEnvVars.allSatisfy { field in
                        !(envValues[field.id, default: ""].trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    let canConnect = entry.requiredEnvVars.isEmpty || hasAll

                    Button {
                        let values = entry.requiredEnvVars.isEmpty
                            ? [:]
                            : envValues.filter { !$0.value.trimmingCharacters(in: .whitespaces).isEmpty }
                        log.info("Connecting '\(entry.id)' with \(values.count) env vars")
                        claudeService.addServer(
                            name: entry.id,
                            command: entry.command,
                            args: entry.args,
                            env: values
                        )
                        connectingEntry = nil
                        envValues = [:]
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                            Text("Connect \(entry.displayName)")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(canConnect ? entry.color.opacity(0.9) : Color.gray.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canConnect)
                }
                .screenPadding()
                .padding(.top, FSSpacing.sm)
                .padding(.bottom, FSSpacing.md)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FSColors.bgPrimary)
    }

    private var unavailableCard: some View {
        VStack(spacing: FSSpacing.sm) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28))
                .foregroundStyle(FSColors.textMuted)
            Text("Claude CLI not found")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(FSColors.textSecondary)
            Text("Install Claude Code at /opt/homebrew/bin/claude\nto enable integrations.")
                .font(.system(size: 11))
                .foregroundStyle(FSColors.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, FSSpacing.xl)
    }
}

// MARK: - App Icon View

private struct AppIconView: View {
    let entry: MCPCatalogEntry
    let size: CGFloat

    var body: some View {
        if let path = entry.appIconPath,
           FileManager.default.fileExists(atPath: path) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: path))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        } else {
            Image(systemName: entry.icon)
                .font(.system(size: size * 0.45))
                .foregroundStyle(entry.color)
                .frame(width: size, height: size)
                .background(entry.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
        }
    }
}

// MARK: - Catalog Row

private struct MCPCatalogRow: View {
    let entry: MCPCatalogEntry
    let isConnected: Bool
    var onConnect: () -> Void
    var onDisconnect: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AppIconView(entry: entry, size: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(FSColors.textPrimary)
                Text(entry.description)
                    .font(.system(size: 10))
                    .foregroundStyle(FSColors.textMuted)
                    .lineLimit(1)
            }

            Spacer()

            if isConnected {
                HStack(spacing: 8) {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(.green)
                            .frame(width: 6, height: 6)
                        Text("Connected")
                            .font(.system(size: 10))
                            .foregroundStyle(.green)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.08))
                    .clipShape(Capsule())

                    Button(action: onDisconnect) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(FSColors.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Button(action: onConnect) {
                    Text("Connect")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .background(entry.color.opacity(0.8))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, FSSpacing.md)
        .padding(.vertical, 11)
    }
}

// MARK: - Extra Server Row

private struct ExtraServerRow: View {
    let name: String
    let config: MCPServerConfig?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "puzzlepiece.extension.fill")
                .font(.system(size: 16))
                .foregroundStyle(.gray)
                .frame(width: 32, height: 32)
                .background(Color.gray.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(FSColors.textPrimary)
                if let config {
                    Text("\(config.command) \(config.args.joined(separator: " "))")
                        .font(.system(size: 10))
                        .foregroundStyle(FSColors.textMuted)
                        .lineLimit(1)
                }
            }

            Spacer()

            HStack(spacing: 5) {
                Circle()
                    .fill(.green)
                    .frame(width: 6, height: 6)
                Text("Connected")
                    .font(.system(size: 10))
                    .foregroundStyle(.green)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.green.opacity(0.08))
            .clipShape(Capsule())
        }
        .padding(.horizontal, FSSpacing.md)
        .padding(.vertical, 11)
    }
}

extension MCPCatalogEntry: Equatable {
    static func == (lhs: MCPCatalogEntry, rhs: MCPCatalogEntry) -> Bool {
        lhs.id == rhs.id
    }
}

extension MCPCatalogEntry: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
