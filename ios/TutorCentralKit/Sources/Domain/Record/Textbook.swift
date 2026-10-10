import Foundation

/// A textbook captured once per school, class and subject (D58); its chapters are copied to each student of that class.
public struct Textbook: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public let schoolID: UUID
    public var classLevel: ClassLevel
    public var subject: String
    public var title: String
    public var publisher: String?
    public var edition: String?
    public var chapters: [TextbookChapter]

    public init(
        id: UUID,
        schoolID: UUID,
        classLevel: ClassLevel,
        subject: String,
        title: String,
        publisher: String?,
        edition: String?,
        chapters: [TextbookChapter]
    ) {
        self.id = id
        self.schoolID = schoolID
        self.classLevel = classLevel
        self.subject = subject
        self.title = title
        self.publisher = publisher
        self.edition = edition
        self.chapters = chapters
    }
}

/// A chapter as read from the contents page, before it is copied to a student.
public struct TextbookChapter: Hashable, Sendable, Codable {
    public var position: Int
    public var name: String
    public var skills: [String]

    public init(position: Int, name: String, skills: [String]) {
        self.position = position
        self.name = name
        self.skills = skills
    }
}
