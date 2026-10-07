import AuthenticationServices
import Domain
import Foundation
import Supabase
import Testing
@testable import Data

struct AuthErrorMappingTests {
    func api(_ code: ErrorCode, _ message: String = "m") throws -> AuthError {
        let url = try #require(URL(string: "https://x"))
        let response = try #require(HTTPURLResponse(url: url, statusCode: 403, httpVersion: nil, headerFields: nil))
        return .api(message: message, errorCode: code, underlyingData: Data(), underlyingResponse: response)
    }

    @Test func supabaseCodesBecomeTheFailuresTheScreensName() throws {
        #expect(try SignInFailure(api(.overEmailSendRateLimit)) == .tooManyRequests)
        #expect(try SignInFailure(api(.overRequestRateLimit)) == .tooManyRequests)
        #expect(try SignInFailure(api(.invalidCredentials)) == .wrongPassword)
        #expect(try SignInFailure(api(.emailProviderDisabled, "Email logins are disabled")) ==
            .other("Email logins are disabled"))
    }

    /// Supabase answers a wrong code and an expired one alike (403 otp_expired, "Token has expired or is invalid",
    /// checked against the local stack); the code screen tells them apart by its own clock.
    @Test func supabasesOneAnswerForAWrongOrExpiredCodeIsAWrongCode() throws {
        #expect(try SignInFailure(api(.otpExpired, "Token has expired or is invalid")) == .wrongCode)
    }

    @Test func aDismissedSheetOrSessionIsCancelled() {
        #expect(SignInFailure(ASAuthorizationError(.canceled)) == .cancelled)
        #expect(SignInFailure(ASWebAuthenticationSessionError(.canceledLogin)) == .cancelled)
    }

    @Test func anotherAppleOrWebSessionErrorIsTheProviderRefusing() {
        #expect(SignInFailure(ASAuthorizationError(.failed)) == .providerRefused)
    }

    @Test func noNetworkIsOffline() {
        #expect(SignInFailure(URLError(.notConnectedToInternet)) == .offline)
        #expect(SignInFailure(URLError(.timedOut)) == .offline)
    }

    @Test func aFailureStaysItself() {
        #expect(SignInFailure(SignInFailure.wrongCode) == .wrongCode)
    }
}
