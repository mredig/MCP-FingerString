import FingerStringLib
import Foundation
import MCP

extension ToolCommand {
	static let listAll = ToolCommand(rawValue: "fingerstring-list-all")
}

struct ListAllTool: ToolImplementation {
	static let command: ToolCommand = .listAll

	static let tool = Tool(
		name: command.rawValue,
		description: "FingerString: Lists all the stored lists.",
		inputSchema: SchemaGenerator(
			properties: [
				"includeDescriptions": .boolean(
					.init(
						description: "Whether or not to output additional description context with the lists, when they contain anything",
						defaultValue: false))
			]
		).outputSchema)

	let includeDescriptions: Bool

	init(arguments: CallTool.Parameters) throws(ContentError) {
		self.includeDescriptions = arguments.bools.includeDescriptions ?? false
	}
	
	func callAsFunction() async throws(ContentError) -> CallTool.Result {
		let controller = DBController.controller
		let lists = try await wrap(in: ContentError.self) {
			try await controller.getAllLists()
		}

		struct Output: Codable {
			let title: String
			let description: String?
		}

		let listOutput = lists.map {
			Output(title: $0.headerTitle, description: includeDescriptions ? $0.description : nil)
		}

		let output = StructuredContentOutput(
			inputRequest: Self.command.rawValue,
			metaData: nil,
			content: listOutput)

		return output.toResult()
	}
}
