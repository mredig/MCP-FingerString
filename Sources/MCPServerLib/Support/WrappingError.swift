public protocol WrappingError: Error {
	static func wrap(_ anyError: Error) -> Self
}

public func wrap<Success, Failure: WrappingError>(
	in errorType: Failure.Type,
	_ block: () throws -> Success
) throws(Failure) -> Success {
	do {
		return try block()
	} catch let error as Failure {
		throw error
	} catch {
		throw Failure.wrap(error)
	}
}

public func wrap<Success, Failure: WrappingError>(
	isolation actor: isolated (any Actor)? = #isolation,
	in errorType: Failure.Type,
	_ block: () async throws -> Success
) async throws(Failure) -> Success {
	do {
		return try await block()
	} catch let error as Failure {
		throw error
	} catch {
		throw Failure.wrap(error)
	}
}
