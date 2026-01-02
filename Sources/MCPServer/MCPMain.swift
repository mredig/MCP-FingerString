import ArgumentParser
import MCPServerLib

@main
struct MCPServerMain: AsyncParsableCommand {
	func run() async throws {
		try await Entrypoint.run()
	}
}