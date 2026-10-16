import Foundation
import Security

enum KeychainTokenStoreError: LocalizedError {
    case emptyUsername
    case emptyToken
    case unexpectedStatus(OSStatus)

    var errorDescription: String? {
        errorDescription(in: .english)
    }

    func errorDescription(in language: AppLanguage) -> String {
        switch self {
        case .emptyUsername:
            return language.text(.errorEmptyUsernameForKeychain)
        case .emptyToken:
            return language.text(.errorEmptyTokenForKeychain)
        case let .unexpectedStatus(status):
            return SecCopyErrorMessageString(status, nil) as String? ?? language.formatted(.errorKeychainStatus, status)
        }
    }
}

struct KeychainTokenStore {
    let service = "github-repo-downloads"

    func hasToken(for username: String) -> Bool {
        (try? readToken(for: username))?.isEmpty == false
    }

    func saveToken(_ token: String, for username: String) throws {
        let trimmedUsername = normalizedUsername(username)
        guard trimmedUsername.isEmpty == false else {
            throw KeychainTokenStoreError.emptyUsername
        }

        let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedToken.isEmpty == false else {
            throw KeychainTokenStoreError.emptyToken
        }

        let encodedToken = Data(trimmedToken.utf8)
        let baseQuery = queryDictionary(for: trimmedUsername)
        let attributes: [String: Any] = [kSecValueData as String: encodedToken]
        let status = SecItemCopyMatching(baseQuery as CFDictionary, nil)

        switch status {
        case errSecSuccess:
            let updateStatus = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainTokenStoreError.unexpectedStatus(updateStatus)
            }
        case errSecItemNotFound:
            var addQuery = baseQuery
            addQuery[kSecValueData as String] = encodedToken
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainTokenStoreError.unexpectedStatus(addStatus)
            }
        default:
            throw KeychainTokenStoreError.unexpectedStatus(status)
        }
    }

    func readToken(for username: String) throws -> String? {
        let trimmedUsername = normalizedUsername(username)
        guard trimmedUsername.isEmpty == false else {
            return nil
        }

        var query = queryDictionary(for: trimmedUsername)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        switch status {
        case errSecSuccess:
            guard let data = item as? Data, let token = String(data: data, encoding: .utf8) else {
                return nil
            }
            return token
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainTokenStoreError.unexpectedStatus(status)
        }
    }

    func deleteToken(for username: String) throws {
        let trimmedUsername = normalizedUsername(username)
        guard trimmedUsername.isEmpty == false else {
            return
        }

        let status = SecItemDelete(queryDictionary(for: trimmedUsername) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainTokenStoreError.unexpectedStatus(status)
        }
    }

    private func queryDictionary(for username: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: username,
        ]
    }

    private func normalizedUsername(_ username: String) -> String {
        username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
