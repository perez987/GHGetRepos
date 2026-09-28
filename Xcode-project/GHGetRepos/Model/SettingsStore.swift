import Foundation

#if canImport(AppKit)
import AppKit
#endif

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case spanish = "es"

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .english:
            "English"
        case .spanish:
            "Español"
        }
    }

    var locale: Locale {
        switch self {
        case .english:
            Locale(identifier: "en")
        case .spanish:
            Locale(identifier: "es")
        }
    }

    func text(_ key: L10nKey) -> String {
        switch self {
        case .english:
            switch key {
            case .settingsTitle: "Settings"
            case .settingsSubtitle: "Store the shared GitHub username locally and the classic token securely in the macOS Keychain for both tools."
            case .githubUsername: "GitHub username"
            case .usernamePlaceholder: "perez987"
            case .usernameStoredHint: "This value is stored in UserDefaults and should match the account that owns the repositories you want to inspect."
            case .githubToken: "GitHub classic private token"
            case .tokenStored: "Stored in Keychain"
            case .tokenNotSaved: "Not saved"
            case .tokenStoredHint: "The token is stored only in the Keychain service \"github-repo-downloads\" for the configured GitHub username."
            case .saveToken: "Save Token"
            case .deleteToken: "Delete Token"
            case .tokenSavedMessage: "Token saved securely in the Keychain."
            case .tokenDeletedMessage: "Token removed from the Keychain."
            case .languageSelectorTitle: "Language"
            case .languageSelectorSubtitle: "Choose the app language. The change is applied immediately in all windows."
            case .appLanguage: "App language"
            case .appTitle: "GitHub Get Repos"
            case .appSubtitle: "Download all public and private repositories from a GitHub account into a destination folder."
            case .totalDownloadsAppTitle: "GitHub Total Downloads"
            case .totalDownloadsAppSubtitle: "Display the total number of release asset downloads across all repositories owned by the configured account."
            case .repositoriesTab: "Get Repos"
            case .totalDownloadsTab: "Total Downloads"
            case .githubUser: "GitHub user"
            case .notSet: "Not set"
            case .tokenLabel: "Token"
            case .tokenRequired: "Required"
            case .tokenOptional: "Optional"
            case .destinationLabel: "Destination"
            case .chooseFolder: "Choose Folder"
            case .chooseAFolder: "Choose a folder"
            case .repositories: "Repositories"
            case .downloaded: "Downloaded"
            case .skipped: "Skipped"
            case .failed: "Failed"
            case .withDownloads: "With Downloads"
            case .totalDownloads: "Total Downloads"
            case .downloadRepositories: "Run"
            case .downloading: "Downloading…"
            case .runReport: "Run"
            case .running: "Running…"
            case .cancel: "Cancel"
            case .copy: "Copy"
            case .clear: "Clear"
            case .settings: "Settings"
            case .openSettingsHint: "Open Settings to enter the GitHub username and classic token, and choose a destination folder before downloading repositories."
            case .reportSettingsHint: "Open Settings to enter the GitHub username before running the downloads report."
            case .reportPublicOnlyHint: "No token is stored. The report will include only public repositories until you save a token."
            case .liveOutput: "Live output"
            case .selectableAutoScrolls: ""
            case .outputEmpty: "The repository download log will be displayed here."
            case .reportOutputEmpty: "Downloads by repository and the combined total will be displayed here."
            case .runStateReady: "Ready"
            case .runStateRunning: "Running"
            case .runStateCompleted: "Completed"
            case .runStateFailed: "Failed"
            case .runStateCancelled: "Cancelled"
            case .chooseDestinationPanelMessage: "Choose the destination folder for downloaded repositories."
            case .chooseDestinationPanelPrompt: "Choose"
            case .errorInvalidUsername: "Enter a GitHub username in Settings before starting."
            case .errorMissingToken: "Save a GitHub classic token in Settings before downloading repositories."
            case .errorInvalidDestination: "Choose a valid destination folder before starting the download."
            case .errorUsernameTokenMismatch: "The configured username %@ does not match the authenticated token owner %@."
            case .errorInvalidResponse: "GitHub returned an invalid response."
            case .errorServer: "GitHub API error (HTTP %d): %@"
            case .errorUnsuccessfulResponse: "GitHub returned an unsuccessful response."
            case .errorGitCloneFailed: "The repository could not be cloned as a Git repository."
            case .errorGitCloneFailedWithDetails: "The repository could not be cloned as a Git repository: %@"
            case .errorExistingDestinationFolder: "A destination folder already exists for %@."
            case .errorExistingDestinationItem: "A non-folder item already exists at the destination path for %@."
            case .errorEmptyUsernameForKeychain: "Enter a GitHub username before saving a token to the Keychain."
            case .errorEmptyTokenForKeychain: "Enter a GitHub token before saving it to the Keychain."
            case .errorKeychainStatus: "Keychain error %d."
            case .logUser: "User: %@"
            case .logDestination: "Destination: %@"
            case .logQueryingRepositories: "Querying repositories, including private repositories owned by the account..."
            case .logQueryingReleaseDownloads: "Querying repositories and release downloads..."
            case .logNoRepositoriesFound: "No repositories were found for this account."
            case .logDownloadingRepository: "… Downloading %@"
            case .logDownloadedRepository: "✓ Downloaded %@"
            case .logSkippedRepository: "↷ Skipped %@: destination folder already exists"
            case .logFailedRepository: "✗ Failed %@: %@"
            case .logRepositoriesFound: "Repositories found: %d"
            case .logDownloadedCount: "Downloaded: %d"
            case .logSkippedCount: "Skipped: %d"
            case .logFailedCount: "Failed: %d"
            case .logRepositoriesAnalyzed: "Repositories analyzed: %d"
            case .logRepositoriesWithDownloads: "Repositories with recorded downloads: %d"
            case .logRunCancelled: "Run cancelled"
            case .downloadsTableRepositoryHeader: "REPOSITORY"
            case .downloadsTableDownloadsHeader: "DOWNLOADS"
            }
        case .spanish:
            switch key {
            case .settingsTitle: "Configuración"
            case .settingsSubtitle: "Guarda el usuario compartido de GitHub localmente y el token clásico de forma segura en el llavero de macOS para ambas herramientas."
            case .githubUsername: "Usuario de GitHub"
            case .usernamePlaceholder: "perez987"
            case .usernameStoredHint: "Este valor se guarda en UserDefaults y debe coincidir con la cuenta propietaria de los repositorios que quieres inspeccionar."
            case .githubToken: "Token clásico privado de GitHub"
            case .tokenStored: "Guardado en el llavero"
            case .tokenNotSaved: "No guardado"
            case .tokenStoredHint: "El token se guarda solamente en el servicio del llavero \"github-repo-downloads\" para el usuario de GitHub configurado."
            case .saveToken: "Guardar token"
            case .deleteToken: "Eliminar token"
            case .tokenSavedMessage: "Token guardado de forma segura en el llavero."
            case .tokenDeletedMessage: "Token eliminado del llavero."
            case .languageSelectorTitle: "Idioma"
            case .languageSelectorSubtitle: "Elige el idioma de la app. El cambio se aplica de inmediato en todas las ventanas."
            case .appLanguage: "Idioma de la app"
            case .appTitle: "GitHub Get Repos"
            case .appSubtitle: "Descarga todos los repositorios públicos y privados de una cuenta de GitHub en una carpeta."
            case .totalDownloadsAppTitle: "Descargas Totales de GitHub"
            case .totalDownloadsAppSubtitle: "Muestra el número total de descargas de assets de las releases en todos los repositorios de la cuenta configurada."
            case .repositoriesTab: "Obtener repositorios"
            case .totalDownloadsTab: "Descargas totales"
            case .githubUser: "Usuario de GitHub"
            case .notSet: "Sin definir"
            case .tokenLabel: "Token"
            case .tokenRequired: "Obligatorio"
            case .tokenOptional: "Opcional"
            case .destinationLabel: "Destino"
            case .chooseFolder: "Destino"
            case .chooseAFolder: "Elige una carpeta"
            case .repositories: "Repositorios"
            case .downloaded: "Descargados"
            case .skipped: "Omitidos"
            case .failed: "Fallidos"
            case .withDownloads: "Con descargas"
            case .totalDownloads: "Descargas totales"
            case .downloadRepositories: "Ejecutar"
            case .downloading: "Descargando…"
            case .runReport: "Ejecutar"
            case .running: "Ejecutando…"
            case .cancel: "Cancelar"
            case .copy: "Copiar"
            case .clear: "Limpiar"
            case .settings: "Configuración"
            case .openSettingsHint: "Abre Configuración para ingresar el usuario de GitHub y el token clásico, y elige una carpeta de destino antes de descargar repositorios."
            case .reportSettingsHint: "Abre Configuración para ingresar el usuario de GitHub antes de ejecutar el informe de descargas."
            case .reportPublicOnlyHint: "No hay token guardado. El informe incluirá solo repositorios públicos hasta que guardes un token."
            case .liveOutput: "Salida en vivo"
            case .selectableAutoScrolls: ""
            case .outputEmpty: "Aquí se mostrará el registro de descarga de repositorios."
            case .reportOutputEmpty: "Aquí se mostrarán las descargas por repositorio y la suma total."
            case .runStateReady: "Listo"
            case .runStateRunning: "Ejecutando"
            case .runStateCompleted: "Completado"
            case .runStateFailed: "Falló"
            case .runStateCancelled: "Cancelado"
            case .chooseDestinationPanelMessage: "Elige la carpeta de destino para los repositorios descargados."
            case .chooseDestinationPanelPrompt: "Elegir"
            case .errorInvalidUsername: "Ingresa un usuario de GitHub en Configuración antes de comenzar."
            case .errorMissingToken: "Guarda un token clásico de GitHub en Configuración antes de descargar repositorios."
            case .errorInvalidDestination: "Elige una carpeta de destino válida antes de iniciar la descarga."
            case .errorUsernameTokenMismatch: "El nombre de usuario configurado %@ no coincide con el propietario autenticado del token %@."
            case .errorInvalidResponse: "GitHub devolvió una respuesta no válida."
            case .errorServer: "Error de la API de GitHub (HTTP %d): %@"
            case .errorUnsuccessfulResponse: "GitHub devolvió una respuesta fallida."
            case .errorGitCloneFailed: "No se pudo clonar el repositorio como un repositorio Git."
            case .errorGitCloneFailedWithDetails: "No se pudo clonar el repositorio como un repositorio Git: %@"
            case .errorExistingDestinationFolder: "Ya existe una carpeta de destino para %@."
            case .errorExistingDestinationItem: "Ya existe un elemento que no es carpeta en la ruta de destino para %@."
            case .errorEmptyUsernameForKeychain: "Ingresa un usuario de GitHub antes de guardar un token en el llavero."
            case .errorEmptyTokenForKeychain: "Ingresa un token de GitHub antes de guardarlo en el llavero."
            case .errorKeychainStatus: "Error del llavero %d."
            case .logUser: "Usuario: %@"
            case .logDestination: "Destino: %@"
            case .logQueryingRepositories: "Consultando repositorios, incluidos los repositorios privados que pertenecen a la cuenta..."
            case .logQueryingReleaseDownloads: "Consultando repositorios y descargas de releases..."
            case .logNoRepositoriesFound: "No se encontraron repositorios para esta cuenta."
            case .logDownloadingRepository: "… Descargando %@"
            case .logDownloadedRepository: "✓ Descargado %@"
            case .logSkippedRepository: "↷ Omitido %@: la carpeta de destino ya existe"
            case .logFailedRepository: "✗ Falló %@: %@"
            case .logRepositoriesFound: "Repositorios encontrados: %d"
            case .logDownloadedCount: "Descargados: %d"
            case .logSkippedCount: "Omitidos: %d"
            case .logFailedCount: "Fallidos: %d"
            case .logRepositoriesAnalyzed: "Repositorios analizados: %d"
            case .logRepositoriesWithDownloads: "Repositorios con descargas registradas: %d"
            case .logRunCancelled: "Ejecución cancelada"
            case .downloadsTableRepositoryHeader: "REPOSITORIO"
            case .downloadsTableDownloadsHeader: "DESCARGAS"
            }
        }
    }

    func formatted(_ key: L10nKey, _ arguments: CVarArg...) -> String {
        String(format: text(key), locale: locale, arguments: arguments)
    }

    func errorMessage(for error: Error) -> String {
        if let error = error as? GitHubAPIError {
            return error.errorDescription(in: self)
        }

        if let error = error as? KeychainTokenStoreError {
            return error.errorDescription(in: self)
        }

        return error.localizedDescription
    }
}

enum L10nKey {
    case settingsTitle
    case settingsSubtitle
    case githubUsername
    case usernamePlaceholder
    case usernameStoredHint
    case githubToken
    case tokenStored
    case tokenNotSaved
    case tokenStoredHint
    case saveToken
    case deleteToken
    case tokenSavedMessage
    case tokenDeletedMessage
    case languageSelectorTitle
    case languageSelectorSubtitle
    case appLanguage
    case appTitle
    case appSubtitle
    case totalDownloadsAppTitle
    case totalDownloadsAppSubtitle
    case repositoriesTab
    case totalDownloadsTab
    case githubUser
    case notSet
    case tokenLabel
    case tokenRequired
    case tokenOptional
    case destinationLabel
    case chooseFolder
    case chooseAFolder
    case repositories
    case downloaded
    case skipped
    case failed
    case withDownloads
    case totalDownloads
    case downloadRepositories
    case downloading
    case runReport
    case running
    case cancel
    case copy
    case clear
    case settings
    case openSettingsHint
    case reportSettingsHint
    case reportPublicOnlyHint
    case liveOutput
    case selectableAutoScrolls
    case outputEmpty
    case reportOutputEmpty
    case runStateReady
    case runStateRunning
    case runStateCompleted
    case runStateFailed
    case runStateCancelled
    case chooseDestinationPanelMessage
    case chooseDestinationPanelPrompt
    case errorInvalidUsername
    case errorMissingToken
    case errorInvalidDestination
    case errorUsernameTokenMismatch
    case errorInvalidResponse
    case errorServer
    case errorUnsuccessfulResponse
    case errorGitCloneFailed
    case errorGitCloneFailedWithDetails
    case errorExistingDestinationFolder
    case errorExistingDestinationItem
    case errorEmptyUsernameForKeychain
    case errorEmptyTokenForKeychain
    case errorKeychainStatus
    case logUser
    case logDestination
    case logQueryingRepositories
    case logQueryingReleaseDownloads
    case logNoRepositoriesFound
    case logDownloadingRepository
    case logDownloadedRepository
    case logSkippedRepository
    case logFailedRepository
    case logRepositoriesFound
    case logDownloadedCount
    case logSkippedCount
    case logFailedCount
    case logRepositoriesAnalyzed
    case logRepositoriesWithDownloads
    case logRunCancelled
    case downloadsTableRepositoryHeader
    case downloadsTableDownloadsHeader
}

@MainActor
final class SettingsStore: ObservableObject {
    private enum Keys {
        static let username = "githubUsername"
        static let destinationPath = "destinationPath"
        static let language = "appLanguage"
    }

    @Published var githubUsername: String {
        didSet {
            UserDefaults.standard.set(githubUsername, forKey: Keys.username)
            refreshStoredTokenState()
        }
    }

    @Published var destinationPath: String {
        didSet {
            UserDefaults.standard.set(destinationPath, forKey: Keys.destinationPath)
        }
    }

    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: Keys.language)
        }
    }

    @Published private(set) var hasStoredToken: Bool

    private let keychain = KeychainTokenStore()

    init() {
        let storedUsername = UserDefaults.standard.string(forKey: Keys.username) ?? ""
        githubUsername = storedUsername
        destinationPath = UserDefaults.standard.string(forKey: Keys.destinationPath)
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads", isDirectory: true).path
        language = AppLanguage(rawValue: UserDefaults.standard.string(forKey: Keys.language) ?? "") ?? .english
        hasStoredToken = keychain.hasToken(for: Self.trimmed(storedUsername))
    }

    func trimmedUsername() -> String {
        Self.trimmed(githubUsername)
    }

    func trimmedDestinationPath() -> String {
        destinationPath.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func destinationURL() -> URL? {
        let trimmedPath = trimmedDestinationPath()
        guard trimmedPath.isEmpty == false else {
            return nil
        }
        return URL(fileURLWithPath: trimmedPath, isDirectory: true)
    }

    func loadToken() -> String? {
        try? keychain.readToken(for: trimmedUsername())
    }

    func saveToken(_ token: String) throws {
        try keychain.saveToken(token, for: trimmedUsername())
        hasStoredToken = true
    }

    func deleteToken() throws {
        try keychain.deleteToken(for: trimmedUsername())
        hasStoredToken = false
    }

    func text(_ key: L10nKey) -> String {
        language.text(key)
    }

    func formatted(_ key: L10nKey, _ arguments: CVarArg...) -> String {
        String(format: text(key), locale: language.locale, arguments: arguments)
    }

    func message(for error: Error) -> String {
        language.errorMessage(for: error)
    }

    func chooseDestinationDirectory() {
        #if canImport(AppKit)
        let panel = NSOpenPanel()
        panel.message = text(.chooseDestinationPanelMessage)
        panel.prompt = text(.chooseDestinationPanelPrompt)
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.directoryURL = destinationURL()

        if panel.runModal() == .OK, let selectedURL = panel.url {
            destinationPath = selectedURL.path
        }
        #endif
    }

    private func refreshStoredTokenState() {
        hasStoredToken = keychain.hasToken(for: trimmedUsername())
    }

    private static func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
