import FingerStringLib

final class DBController: Sendable {
	let controller: ListController

	private init() {
		self.controller = .init(db: ListController.defaultDB)
	}

	static let shared = DBController()

	static var controller: ListController { shared.controller }
}
