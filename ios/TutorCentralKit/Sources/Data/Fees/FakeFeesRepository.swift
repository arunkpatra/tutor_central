import Domain
import Foundation

/// The in-memory ledger for tests, previews and `bun shots`: October's ten fees of `supabase/seed.sql` (six paid on
/// 4 October by UPI), September's ten (all paid on 3 September but Nikhil's), Hemanth's August (cash) and July
/// (waived), with fixed ids; a scripted error, a delay, a record of every write.
@MainActor public final class FakeFeesRepository: FeesRepository {
    public nonisolated static let devOctober = id(4)
    public nonisolated static let hemanthOctober = id(5)
    public nonisolated static let sahilOctober = id(10)
    public nonisolated static let nikhilSeptember = id(18)

    public nonisolated static let seed: [FeeInvoice] = {
        let students = FakeStudentsRepository.seed
        let october = Period(year: 2026, month: 10)
        let september = Period(year: 2026, month: 9)
        let paidInOctober: Set = [
            "Akshita Rao",
            "Ananya Iyer",
            "Bir Bikram Singh",
            "Lakshmi Menon",
            "Meher Shah",
            "Riya Sharma",
        ]
        let octoberFees = students.enumerated().map { index, student in
            let paid = paidInOctober.contains(student.name)
            return invoice(SeedFee(
                number: index + 1, student: student.id, month: october,
                paidAt: paid ? at(day: 4, of: october) : nil, method: paid ? .upi : nil
            ))
        }
        let septemberFees = students.enumerated().map { index, student in
            let paid = student.name != "Nikhil Das"
            return invoice(SeedFee(
                number: index + 11, student: student.id, month: september,
                paidAt: paid ? at(day: 3, of: september) : nil, method: paid ? .upi : nil
            ))
        }
        let hemanth = students[4].id
        let august = Period(year: 2026, month: 8)
        let hemanthsPast = [
            invoice(SeedFee(
                number: 21,
                student: hemanth,
                month: august,
                paidAt: at(day: 5, of: august),
                method: .cash
            )),
            invoice(SeedFee(
                number: 22, student: hemanth, month: Period(year: 2026, month: 7), paidAt: nil, method: nil,
                reason: "Joined mid-month"
            )),
        ]
        return octoberFees + septemberFees + hemanthsPast
    }()

    /// October's ten alone, for states without a past.
    public nonisolated static let octoberOnly = Array(seed.prefix(10))

    public var invoices: [FeeInvoice]
    public var nextError: (any Error)?
    /// Every call waits this long first: lets a store show its loading state.
    public var delay: Duration?
    /// What `generate` answers when set (then it appends nothing): a scripted count for the stores' tests.
    public var generateCount: Int?
    public private(set) var generated: [Period] = []
    public private(set) var paid: [UUID] = []
    public private(set) var undone: [UUID] = []
    public private(set) var waived: [UUID] = []
    private let now: @Sendable () -> Date

    public init(invoices: [FeeInvoice] = [], now: @escaping @Sendable () -> Date = { FakeCountsRepository.fixedNow }) {
        self.invoices = invoices
        self.now = now
    }

    public func invoices(centre _: UUID, month: Period) async throws -> [FeeInvoice] {
        try await begin()
        return invoices.filter { $0.period == month }
    }

    public func invoices(centre _: UUID, student: UUID) async throws -> [FeeInvoice] {
        try await begin()
        return invoices.filter { $0.studentID == student }.sorted { $0.period > $1.period }
    }

    public func dueBefore(centre _: UUID, month: Period) async throws -> [FeeInvoice] {
        try await begin()
        return invoices.filter { $0.status == .due && $0.period < month }
    }

    /// One due fee per seed student without one for the month, at the seed's amounts, as `generate_fees` makes them.
    public func generate(centre _: UUID, month: Period) async throws -> Int {
        try await begin()
        generated.append(month)
        if let generateCount {
            return generateCount
        }
        let covered = Set(invoices.filter { $0.period == month }.map(\.studentID))
        let made = FakeStudentsRepository.seed.filter { !covered.contains($0.id) }.map { student in
            FeeInvoice(
                id: UUID(), studentID: student.id, period: month, amount: Self.amount(of: student), status: .due,
                paidAt: nil, paidMethod: nil, waivedReason: nil
            )
        }
        invoices += made
        return made.count
    }

    public func markPaid(id: UUID, method: MonthFee.PaidMethod, at: Date) async throws -> FeeInvoice {
        try await begin()
        paid.append(id)
        return try rewrite(id) { Self.with($0, status: .paid, paidAt: at, method: method, reason: nil) }
    }

    public func markDue(id: UUID) async throws -> FeeInvoice {
        try await begin()
        undone.append(id)
        return try rewrite(id) { Self.with($0, status: .due, paidAt: nil, method: nil, reason: $0.waivedReason) }
    }

    public func waive(id: UUID, reason: String) async throws -> FeeInvoice {
        try await begin()
        waived.append(id)
        return try rewrite(id) { Self.with($0, status: .waived, paidAt: nil, method: nil, reason: reason) }
    }

    private func begin() async throws {
        if let delay {
            try? await Task.sleep(for: delay)
        }
        guard let error = nextError else { return }
        nextError = nil
        throw error
    }

    private func rewrite(_ id: UUID, _ change: (FeeInvoice) -> FeeInvoice) throws -> FeeInvoice {
        guard let index = invoices.firstIndex(where: { $0.id == id }) else { throw URLError(.fileDoesNotExist) }
        invoices[index] = change(invoices[index])
        return invoices[index]
    }

    private static func with(
        _ invoice: FeeInvoice, status: MonthFee.Status, paidAt: Date?, method: MonthFee.PaidMethod?, reason: String?
    ) -> FeeInvoice {
        FeeInvoice(
            id: invoice.id, studentID: invoice.studentID, period: invoice.period, amount: invoice.amount,
            status: status,
            paidAt: paidAt, paidMethod: method, waivedReason: reason
        )
    }

    /// The seed's rule: the student's own fee, else the class's.
    private nonisolated static func amount(of student: Student) -> Money {
        let classroom = [FakeClassesRepository.maths, FakeClassesRepository.science].first { $0.id == student.classID }
        return student.fee(in: classroom) ?? .zero
    }

    private nonisolated static func invoice(_ fee: SeedFee) -> FeeInvoice {
        let student = FakeStudentsRepository.seed.first { $0.id == fee.student }
        let status: MonthFee.Status = fee.reason != nil ? .waived : fee.paidAt != nil ? .paid : .due
        return FeeInvoice(
            id: id(fee.number), studentID: fee.student, period: fee.month,
            amount: student.map(amount(of:)) ?? .zero, status: status, paidAt: fee.paidAt, paidMethod: fee.method,
            waivedReason: fee.reason
        )
    }

    /// 11:00 in India on a day of the month.
    private nonisolated static func at(day: Int, of month: Period) -> Date {
        DayHeading.india.date(from: DateComponents(year: month.year, month: month.month, day: day, hour: 11))
            ?? .distantPast
    }

    public nonisolated static func id(_ number: Int) -> UUID {
        UUID(uuidString: String(format: "bbbbbbbb-0000-0000-0000-%012d", number))!
    }

    /// One seeded fee.
    private struct SeedFee {
        let number: Int
        let student: UUID
        let month: Period
        let paidAt: Date?
        let method: MonthFee.PaidMethod?
        var reason: String?
    }
}
