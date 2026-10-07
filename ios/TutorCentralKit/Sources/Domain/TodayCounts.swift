/// The three numbers on Today's tiles.
public struct TodayCounts: Hashable, Sendable {
    public var students: Int
    public var due: Money
    public var classesToday: Int

    public init(students: Int, due: Money, classesToday: Int) {
        self.students = students
        self.due = due
        self.classesToday = classesToday
    }

    public static let zero = TodayCounts(students: 0, due: .zero, classesToday: 0)
}
