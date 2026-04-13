import Foundation

protocol CredentialsLoading {
    static func loadCredentials() throws -> ClaudeCredentials
}
