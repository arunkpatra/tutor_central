import Foundation

/// Where an artefact's screen leads; AppShell supplies it (a feature never imports another). Back is the screen's own
/// dismiss, as History's.
public struct ArtefactsActions {
    let openArtefact: (UUID) -> Void

    public init(openArtefact: @escaping (UUID) -> Void) {
        self.openArtefact = openArtefact
    }
}
