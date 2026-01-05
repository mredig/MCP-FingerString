import FingerStringLib
import Foundation
import MCP

extension ToolCommand {
	static let listCreate = ToolCommand(rawValue: "fingerstring-list-create")
}

struct ListCreateTool: ToolImplementation {
	static let command: ToolCommand = .listCreate

	static let tool = Tool(
		name: command.rawValue,
		description: "FingerString: Creates a list of reminders or tasks",
		inputSchema: SchemaGenerator(properties: [
			"slug": .string(.init(description: "Slug for the list (alphanumeric, dots, dashes, underscores)", isRequired: true)),
			"title": .string(.init(description: "Friendly, human readable title for the list")),
			"description": .string(.init(description: "Description for the list"))
		]).outputSchema)

	private let slug: String
	private let title: String?
	private let description: String?

	init(arguments: CallTool.Parameters) throws(ContentError) {
		guard
			let slug = arguments.strings.slug
		else { throw .missingArgument("slug") }
		self.slug = slug
		self.title = arguments.strings.title
		self.description = arguments.strings.description
	}

	func callAsFunction() async throws(ContentError) -> CallTool.Result {
		let controller = DBController.controller

		let createdList = try await wrap(in: ContentError.self) {
			try await controller.createList(with: slug, friendlyTitle: title, description: description)
		}

		return StructuredContentOutput(
			inputRequest: "\(self)",
			metaData: nil,
			content: ["Created list with slug '\(createdList.slug)'"])
		.toResult()
	}
}
