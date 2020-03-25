import SQLBuilder

struct Task: Table, Codable {
    let id: Int?
    let name: String
    let isComplete: Bool

    init(id: Int = 0, name: String, isComplete: Bool = false) {
        self.id = id
        self.name = name
        self.isComplete = isComplete
    }
}
