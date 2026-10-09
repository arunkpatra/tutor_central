import AuthenticationServices
import Domain
import SwiftUI

/// Apple's confirmation before a deletion (D38): a fresh Sign in with Apple authorization, no scopes, whose one-time
/// code the API exchanges and revokes. SwiftUI's `AuthorizationController` presents Apple's sheet, so no UIKit
/// delegate is needed. Closing the sheet is `.cancelled`; anything else Apple says is `.appleRefused`.
@MainActor public struct AppleReauthorizer {
    let controller: AuthorizationController

    public init(controller: AuthorizationController) {
        self.controller = controller
    }

    public func authorizationCode() async throws(AccountFailure) -> String {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        let result: ASAuthorizationResult
        do {
            result = try await controller.performRequest(request)
        } catch let apple as ASAuthorizationError where apple.code == .canceled {
            throw .cancelled
        } catch {
            throw .appleRefused
        }
        guard case let .appleID(credential) = result, let data = credential.authorizationCode,
              let code = String(data: data, encoding: .utf8) else { throw .appleRefused }
        return code
    }
}
