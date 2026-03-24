import Foundation
import Security

struct ClaudeCredentials {
    let accessToken: String
    let subscriptionType: String
}

enum KeychainError: LocalizedError {
    case notFound
    case invalidData
    case securityError(OSStatus)

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Claude Code credentials not found.\nPlease open a terminal and run 'claude' to sign in first."
        case .invalidData:
            return "Could not parse credentials from Keychain."
        case .securityError(let status):
            return "Keychain error (OSStatus \(status))."
        }
    }
}

struct KeychainService {
    private static let serviceName = "Claude Code-credentials"

    static func loadCredentials() throws -> ClaudeCredentials {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.notFound
            }
            throw KeychainError.securityError(status)
        }

        guard
            let data = item as? Data,
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let oauth = json["claudeAiOauth"] as? [String: Any],
            let token = oauth["accessToken"] as? String,
            !token.isEmpty
        else {
            throw KeychainError.invalidData
        }

        let sub = oauth["subscriptionType"] as? String ?? "unknown"
        return ClaudeCredentials(accessToken: token, subscriptionType: sub)
    }
}
