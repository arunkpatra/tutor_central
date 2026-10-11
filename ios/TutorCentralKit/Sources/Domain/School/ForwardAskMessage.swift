/// Ask parents to forward (P10-School-Ask; plan/phase-13-plan.md decision 18): the message once, editable, held to 600.
public enum ForwardAskMessage {
    public static let limit = 600

    public static func text(tutorName: String?, centreName: String) -> String {
        let firstName = tutorName.flatMap { $0.split(separator: " ").first }.map(String.init)
        let who = firstName.map { "\($0) from \(centreName)" } ?? centreName
        let body = """
        Hello, this is \(who). Please forward me whatever the school sends about tests, portions, homework and \
        holidays, as soon as it comes. It helps me prepare your child for exactly what is coming. Thank you.
        """
        return MessageSignature.signed(body, tutorName: tutorName, centreName: centreName)
    }
}
