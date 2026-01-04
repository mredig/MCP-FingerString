import MCP
import ServiceLifecycle
import Logging

public enum Entrypoint {
	public static func run() async throws {
		// Configure logging system
		LoggingSystem.bootstrap { label in
			var handler = StreamLogHandler.standardOutput(label: label)
			handler.logLevel = .info
			return handler
		}

		let logger = Logger(label: "pizza.appsby.mcp-fingerstring")

		logger.info("Starting MCP-FingerString...")

		// Create the MCP server with capabilities
		let server = Server(
			name: "MCP-FingerString",
			version: "1.0.0",
			capabilities: .init(
				resources: .init(subscribe: true, listChanged: true),
				tools: .init(listChanged: true)
			)
		)

		// Register all server handlers
		await ServerHandlers.registerHandlers(on: server)

		// Create stdio transport
		let transport = StdioTransport(logger: logger)

		// Create MCP service
		let mcpService = MCPService(server: server, transport: transport, logger: logger)

		// Create service group with signal handling for graceful shutdown
		let serviceGroup = ServiceGroup(
			services: [mcpService],
			gracefulShutdownSignals: [.sigterm, .sigint],
			logger: logger
		)

		logger.info("MCP-FingerString initialized and ready")

		// Run the service group - this blocks until shutdown signal
		try await serviceGroup.run()

		logger.info("MCP-FingerString shutdown complete")
	}
}
