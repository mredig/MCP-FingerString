import FingerStringLib
import Foundation
import MCP

extension ToolCommand {
	static let listDelete = ToolCommand(rawValue: "fingerstring-list-delete")
}

struct ListDeleteTool: ToolImplementation {
	static let command: ToolCommand = .listDelete

	static let tool = Tool(
		name: command.rawValue,
		description: "FingerString: Deletes a list by slug",
		inputSchema: SchemaGenerator(properties: [
			"slug": .string(.init(description: "Slug of the list to delete", isRequired: true)),
			"force": .boolean(.init(description: "Skip confirmation prompt", defaultValue: false))
		]).outputSchema)

	private let slug: String
	private let force: Bool

	init(arguments: CallTool.Parameters) throws(ContentError) {
		guard
			let slug = arguments.strings.slug
		else { throw .missingArgument("slug") }
		self.slug = slug
		self.force = arguments.bools.force ?? false
	}

	func callAsFunction() async throws(ContentError) -> CallTool.Result {
		let controller = DBController.controller

		let list = try await wrap(in: ContentError.self, {
			try await controller.getList(withSlug: slug)
		})
		guard let list else {
			throw .contentError(message: "No list with slug '\(slug)'")
		}

		try await wrap(in: ContentError.self) {
			try await controller.deleteList(list.id)
		}

		return StructuredContentOutput(
			inputRequest: "\(Self.command.rawValue): \(slug)",
			metaData: nil,
			content: ["Deleted list '\(list.headerTitle)'"])
		.toResult()
	}
}
