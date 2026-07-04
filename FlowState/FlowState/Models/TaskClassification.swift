import Foundation

struct TaskClassification: Codable {
    let category: String
    let isExecutable: Bool
    let mcpServer: String?
    let executionPrompt: String?

    enum CodingKeys: String, CodingKey {
        case category
        case isExecutable = "is_executable"
        case mcpServer = "mcp_server"
        case executionPrompt = "execution_prompt"
    }
}

struct ClaudeResponse: Codable {
    let type: String
    let subtype: String?
    let is_error: Bool
    let result: String?
    let structured_output: TaskClassification?
}

struct ExecutionResult: Codable {
    let type: String
    let subtype: String?
    let is_error: Bool
    let result: String?
    let num_turns: Int?
}
