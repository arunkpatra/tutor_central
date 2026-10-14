import Data
import Domain
import Foundation

/// A tutor's feedback on a made thing kept beside its generation (D107): a reason at Make it again or Write again, an
/// edit at Send, a replacement by their own. Best effort: a feedback row that does not go through never stops the
/// tutor, and a thing with no generation (the tutor's own) has none.
enum ArtefactFeedback {
    static func again(_ artefact: Artefact, reason: String?, recorder: (any FeedbackRecorder)?, centre: UUID) async {
        guard let reason, !reason.isEmpty, let generation = artefact.generationID else { return }
        await keep(.again(generation, reason: reason), recorder: recorder, centre: centre)
    }

    static func keep(_ feedback: Feedback, recorder: (any FeedbackRecorder)?, centre: UUID) async {
        try? await recorder?.record(feedback, centre: centre)
    }
}
