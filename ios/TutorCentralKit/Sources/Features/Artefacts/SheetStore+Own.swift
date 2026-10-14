import Data
import Domain
import Foundation

/// Use my own (spec section 2, plan decision 13): the tutor's photo or typed words take the made sheet's place in the
/// plan and the record; the made sheet stays and can come back.
public extension SheetStore {
    internal static let ownFailed = "Couldn't use your sheet. The made sheet is still here."
    /// The typed sheet is kept to this many characters.
    static let typedLimit = 4000

    /// "Used in place of sheet 1. The plan and the record treat it as sheet 1: homework given, done, not done."
    var inPlaceLine: String {
        let place = ownContent?.inPlaceOf ?? "sheet 1"
        return "Used in place of \(place). The plan and the record treat it as \(place): "
            + "homework given, done, not done."
    }

    var ownContent: OwnContent? {
        if case let .own(own) = artefact?.content {
            return own
        }
        return nil
    }

    /// The photo reduced on this iPhone (D36), uploaded under the centre, kept in the made sheet's place.
    func useOwn(photo: Data) async {
        guard await allowedOwn(), let reduced = PhotoReducer.reduce(photo) else { return }
        do {
            let path = try await photos.add(reduced.data, centre: centre, kind: "own")
            await keepOwn(OwnContent(text: nil, inPlaceOf: place), photoPath: path)
        } catch {
            message = Self.ownFailed
        }
    }

    func useOwn(text: String) async {
        let typed = String(text.trimmingCharacters(in: .whitespacesAndNewlines).unicodeScalars.prefix(Self.typedLimit))
        guard !typed.isEmpty, await allowedOwn() else { return }
        await keepOwn(OwnContent(text: typed, inPlaceOf: place), photoPath: nil)
    }

    /// The made sheet back in its place.
    func useMadeInstead() async {
        guard let made = artefact?.regeneratedFrom, artefact?.source == .own else { return }
        guard await online() else {
            message = OfflineRefusal.words(for: .ownSheet)
            return
        }
        if let own = artefact, own.isMade {
            await keepMadeAgain(made, over: own)
            return
        }
        do {
            try await plans.link(items: items.map(\.id), to: made, centre: centre)
            if let sheet = try await plans.artefact(id: made, centre: centre) {
                await reload(sheet)
            }
        } catch {
            message = Self.ownFailed
        }
    }

    /// "sheet 1", the words the made sheet's title ends with; the tutor's own sheet passes on what it stands in for.
    private var place: String {
        if let own = ownContent {
            return own.inPlaceOf
        }
        return artefact?.title.components(separatedBy: " · ").last ?? "sheet 1"
    }

    private func allowedOwn() async -> Bool {
        guard await online() else {
            message = OfflineRefusal.words(for: .ownSheet)
            return false
        }
        return artefact != nil
    }

    /// A Make sheet has no plan line: the made one is kept again over the tutor's own, so Recent shows it.
    private func keepMadeAgain(_ made: UUID, over own: Artefact) async {
        do {
            guard let sheet = try await plans.artefact(id: made, centre: centre) else {
                message = Self.ownFailed
                return
            }
            let again = NewArtefact(
                kind: .sheet, source: .made, title: sheet.title, content: sheet.content, photoPath: nil,
                generationID: sheet.generationID, regeneratedFrom: own.id
            )
            let kept = try await plans.keep(
                ArtefactWords.carrying(again, from: own), to: ArtefactWords.madeLink(own), centre: centre
            )
            await reload(kept)
        } catch {
            message = Self.ownFailed
        }
    }

    private func keepOwn(_ content: OwnContent, photoPath: String?) async {
        guard let artefact, let link = artefact.isMade ? ArtefactWords.madeLink(artefact) : link() else {
            message = Self.ownFailed
            return
        }
        let base = artefact.title.components(separatedBy: " · ").first ?? artefact.title
        let isOwn = artefact.source == .own
        let made = isOwn ? artefact.regeneratedFrom : artefact.id
        // Replacing the tutor's own sheet keeps its title, which already names the made one.
        let title = isOwn ? artefact.title : "Your sheet · \(base.lowercased())"
        do {
            let own = NewArtefact(
                kind: .sheet, source: .own, title: title, content: .own(content), photoPath: photoPath,
                generationID: nil, regeneratedFrom: made
            )
            let kept = try await plans.keep(ArtefactWords.carrying(own, from: artefact), to: link, centre: centre)
            // The made sheet replaced by the tutor's own (D107): kept beside its generation, a photo never sent.
            if !isOwn, let generation = artefact.generationID {
                let revised: FeedbackRevision = content.text.map(FeedbackRevision.text) ?? .photo
                await ArtefactFeedback.keep(.replace(generation, with: revised), recorder: feedback, centre: centre)
            }
            await reload(kept)
        } catch {
            message = Self.ownFailed
        }
    }
}
