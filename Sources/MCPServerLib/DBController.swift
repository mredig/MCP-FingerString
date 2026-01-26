import FingerStringLib

final class DBController: Sendable {
	let controller: ListController

	private init() throws {
		self.controller = try ListController(dbLocation: Constants.defaultDBURL)
	}

	static let shared = try! DBController()

	static var controller: ListController { shared.controller }
}
