import SwiftUI
import CoreImage

enum KimiWebAuthorizationState: Equatable {
    case idle
    case creating
    case waiting
    case scanned
    case succeeded
    case failed(String)
}

enum KimiWebAuthError: Error, LocalizedError {
    case httpError(Int)
    case invalidResponse
    case expired
    case timeout

    var errorDescription: String? {
        switch self {
        case .httpError(let code): return LanguageManager.tr("网页授权请求失败（%d）", arguments: [code])
        case .invalidResponse: return LanguageManager.tr("网页授权响应无效")
        case .expired: return LanguageManager.tr("二维码已过期，请重新生成")
        case .timeout: return LanguageManager.tr("扫码超时，请重新生成")
        }
    }
}

@MainActor
final class KimiWebAuthService: ObservableObject {
    static let shared = KimiWebAuthService()

    @Published private(set) var authorizationState: KimiWebAuthorizationState = .idle
    @Published private(set) var qrCodeURL: URL?
    @Published private(set) var authorizationAccountID: UUID?
    @Published private(set) var authorizedAccountIDs: Set<UUID> = []

    private var authorizationTask: Task<Void, Never>?
    private var authorizationSessionID: UUID?
    private var refreshTasks: [UUID: Task<String?, Never>] = [:]
    private var credentials: [String: KimiWebCredential] = [:]

    private init() {
        if let data = try? Data(contentsOf: Self.credentialsFileURL),
           let stored = try? JSONDecoder().decode([String: KimiWebCredential].self, from: data) {
            credentials = stored
            authorizedAccountIDs = Set(stored.keys.compactMap { UUID(uuidString: $0) })
        }
    }

    private static var credentialsFileURL: URL {
        KimiAccountStore.credentialsFileURL()
            .deletingLastPathComponent()
            .appendingPathComponent("web-credentials.json")
    }

    func hasCredential(for accountID: UUID) -> Bool {
        boundCredential(for: accountID) != nil
    }

    func accessToken(for accountID: UUID) -> String? {
        boundCredential(for: accountID)?.accessToken
    }

    func authorizationDate(for accountID: UUID) -> Date? {
        if let date = boundCredential(for: accountID)?.authorizedAt {
            return date
        }
        let attributes = try? FileManager.default.attributesOfItem(atPath: Self.credentialsFileURL.path)
        return attributes?[.creationDate] as? Date
    }

    func refreshAccessToken(for accountID: UUID) async -> String? {
        if let task = refreshTasks[accountID] {
            return await task.value
        }
        guard let current = boundCredential(for: accountID) else { return nil }
        let task = Task { [weak self] in
            await self?.performRefresh(current: current, for: accountID) ?? nil
        }
        refreshTasks[accountID] = task
        let accessToken = await task.value
        refreshTasks.removeValue(forKey: accountID)
        return accessToken
    }

    private func performRefresh(current: KimiWebCredential, for accountID: UUID) async -> String? {
        struct Response: Decodable {
            let accessToken: String
            let refreshToken: String
            let userId: String?

            enum CodingKeys: String, CodingKey {
                case accessToken = "access_token"
                case refreshToken = "refresh_token"
                case userId = "user_id"
                case accessTokenCamel = "accessToken"
                case refreshTokenCamel = "refreshToken"
                case userIdCamel = "userId"
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                accessToken = try container.decodeIfPresent(String.self, forKey: .accessToken)
                    ?? container.decode(String.self, forKey: .accessTokenCamel)
                refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken)
                    ?? container.decode(String.self, forKey: .refreshTokenCamel)
                userId = try container.decodeIfPresent(String.self, forKey: .userId)
                    ?? container.decodeIfPresent(String.self, forKey: .userIdCamel)
            }
        }

        do {
            let response = try await post(
                "account.gateway.v1.AuthService/RefreshToken",
                body: ["refresh_token": current.refreshToken],
                responseType: Response.self
            )
            guard credentials[accountID.uuidString]?.refreshToken == current.refreshToken else {
                return boundCredential(for: accountID)?.accessToken
            }
            let updated = KimiWebCredential(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken,
                userId: current.userId,
                authorizedAt: current.authorizedAt
            )
            store(updated, for: accountID)
            return updated.accessToken
        } catch {
            if case KimiWebAuthError.httpError(let code) = error,
               (code == 401 || code == 403),
               credentials[accountID.uuidString]?.refreshToken == current.refreshToken {
                removeCredential(for: accountID)
            }
            return nil
        }
    }

    private func boundCredential(for accountID: UUID) -> KimiWebCredential? {
        credentials[accountID.uuidString]
    }

    func removeCredential(for accountID: UUID) {
        credentials.removeValue(forKey: accountID.uuidString)
        authorizedAccountIDs.remove(accountID)
        saveCredentials()
    }

    func startAuthorization(for accountID: UUID) {
        authorizationTask?.cancel()
        let sessionID = UUID()
        authorizationSessionID = sessionID
        authorizationAccountID = accountID
        authorizationState = .creating
        qrCodeURL = nil
        authorizationTask = Task { [weak self] in
            await self?.runAuthorization(for: accountID, sessionID: sessionID)
        }
    }

    func cancelAuthorization(for accountID: UUID) {
        guard authorizationAccountID == accountID else { return }
        authorizationSessionID = nil
        authorizationAccountID = nil
        authorizationTask?.cancel()
        authorizationTask = nil
        authorizationState = .idle
        qrCodeURL = nil
    }

    private func runAuthorization(for accountID: UUID, sessionID: UUID) async {
        struct CreateResponse: Decodable { let code: String }
        struct StatusResponse: Decodable {
            let status: Int
            let accessToken: String?
            let refreshToken: String?
            let userId: String?

            enum CodingKeys: String, CodingKey {
                case status
                case accessToken = "access_token"
                case refreshToken = "refresh_token"
                case userId = "user_id"
                case accessTokenCamel = "accessToken"
                case refreshTokenCamel = "refreshToken"
                case userIdCamel = "userId"
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                if let value = try? container.decode(Int.self, forKey: .status) {
                    status = value
                } else {
                    switch try container.decode(String.self, forKey: .status) {
                    case "STATUS_PENDING": status = 1
                    case "STATUS_SCANNED": status = 2
                    case "STATUS_EXPIRED": status = 3
                    case "STATUS_SUCCESS": status = 4
                    default: status = 0
                    }
                }
                accessToken = try container.decodeIfPresent(String.self, forKey: .accessToken)
                    ?? container.decodeIfPresent(String.self, forKey: .accessTokenCamel)
                refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken)
                    ?? container.decodeIfPresent(String.self, forKey: .refreshTokenCamel)
                userId = try container.decodeIfPresent(String.self, forKey: .userId)
                    ?? container.decodeIfPresent(String.self, forKey: .userIdCamel)
            }
        }

        do {
            let created = try await post(
                "account.gateway.v1.AuthService/CreateLoginQRCode",
                body: [:],
                responseType: CreateResponse.self
            )
            guard isAuthorizationActive(sessionID) else { return }
            let deviceID = UUID().uuidString
            qrCodeURL = URL(string: "https://www.kimi.com/wechat/mp/auth?id=\(created.code)&device_id=\(deviceID)")
            authorizationState = .waiting
            let deadline = Date().addingTimeInterval(300)

            while isAuthorizationActive(sessionID) && Date() < deadline {
                let result = try await post(
                    "account.gateway.v1.AuthService/GetLoginQRCodeStatus",
                    body: ["code": created.code],
                    responseType: StatusResponse.self
                )
                guard isAuthorizationActive(sessionID) else { return }
                switch result.status {
                case 1:
                    authorizationState = .waiting
                case 2:
                    authorizationState = .scanned
                case 3:
                    throw KimiWebAuthError.expired
                case 4:
                    guard let accessToken = result.accessToken,
                          let refreshToken = result.refreshToken else {
                        throw KimiWebAuthError.invalidResponse
                    }
                    guard isAuthorizationActive(sessionID) else { return }
                    store(
                        KimiWebCredential(
                            accessToken: accessToken,
                            refreshToken: refreshToken,
                            userId: result.userId,
                            authorizedAt: Date()
                        ),
                        for: accountID
                    )
                    authorizationState = .succeeded
                    return
                default:
                    throw KimiWebAuthError.invalidResponse
                }
                try await Task.sleep(nanoseconds: 1_500_000_000)
            }
            if isAuthorizationActive(sessionID) {
                authorizationState = .failed(KimiWebAuthError.timeout.localizedDescription)
            }
        } catch is CancellationError {
            return
        } catch {
            if isAuthorizationActive(sessionID) {
                authorizationState = .failed(error.localizedDescription)
            }
        }
    }

    private func isAuthorizationActive(_ sessionID: UUID) -> Bool {
        authorizationSessionID == sessionID && !Task.isCancelled
    }

    private func store(_ credential: KimiWebCredential, for accountID: UUID) {
        credentials[accountID.uuidString] = credential
        authorizedAccountIDs.insert(accountID)
        saveCredentials()
    }

    private func saveCredentials() {
        let url = Self.credentialsFileURL
        let directory = url.deletingLastPathComponent()
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(credentials)
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700]
            )
            let tempURL = directory.appendingPathComponent(".web-credentials.json.tmp.\(ProcessInfo.processInfo.processIdentifier)")
            try data.write(to: tempURL, options: .atomic)
            if FileManager.default.fileExists(atPath: url.path) {
                _ = try FileManager.default.replaceItemAt(url, withItemAt: tempURL)
            } else {
                try FileManager.default.moveItem(at: tempURL, to: url)
            }
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
        } catch {}
    }

    private func post<Response: Decodable>(
        _ path: String,
        body: [String: Any],
        responseType: Response.Type
    ) async throws -> Response {
        guard let url = URL(string: "https://auth.kimi.com/api/\(path)") else {
            throw KimiWebAuthError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("web", forHTTPHeaderField: "X-Msh-Platform")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw KimiWebAuthError.invalidResponse
        }
        guard http.statusCode == 200 else {
            throw KimiWebAuthError.httpError(http.statusCode)
        }
        return try JSONDecoder().decode(Response.self, from: data)
    }
}

struct MonthlyQuotaAuthorizationCard: View {
    let accountID: UUID

    @StateObject private var webAuth = KimiWebAuthService.shared
    @StateObject private var model = KimiCodeBarModel.shared
    @State private var isPresented = false
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                LText("本月用量")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.kimiTextPrimary)
                LText(webAuth.hasCredential(for: accountID) ? "已授权，月度数据暂不可用" : "网页扫码授权后显示")
                    .font(.system(size: 11))
                    .foregroundStyle(.kimiTextTertiary)
            }

            Spacer()

            Button {
                if webAuth.hasCredential(for: accountID) {
                    model.refresh()
                } else {
                    isPresented = true
                    webAuth.startAuthorization(for: accountID)
                }
            } label: {
                LText(webAuth.hasCredential(for: accountID) ? "刷新" : "扫码授权")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isHovered ? Color.white : Color.kimiBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.kimiBlue.opacity(isHovered ? 0.9 : 0.10))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .onHover { isHovered = $0 }
            .cursor(.pointingHand)
        }
        .padding(14)
        .background(Color.kimiCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .popover(isPresented: $isPresented, arrowEdge: .trailing) {
            KimiWebAuthorizationView(accountID: accountID) {
                model.subscriptionAuthorizationDidChange(for: accountID)
                isPresented = false
            }
        }
        .onChange(of: isPresented) { _, presented in
            if !presented { webAuth.cancelAuthorization(for: accountID) }
        }
    }
}

private struct KimiWebAuthorizationView: View {
    let accountID: UUID
    let onSuccess: () -> Void

    @StateObject private var webAuth = KimiWebAuthService.shared
    @State private var isActionHovered = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 14) {
            LText("网页额度授权")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.kimiTextPrimary)

            Group {
                if let qrCodeURL = webAuth.qrCodeURL,
                   let image = Self.qrCodeImage(for: qrCodeURL.absoluteString) {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.none)
                        .aspectRatio(contentMode: .fit)
                } else {
                    ProgressView()
                }
            }
            .frame(width: 160, height: 160)
            .padding(8)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(statusText)
                .font(.system(size: 11))
                .foregroundStyle(.kimiTextSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: buttonAction) {
                LText(buttonTitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isActionHovered ? Color.kimiBlue : Color.kimiTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(Color.kimiBlue.opacity(isActionHovered ? 0.12 : 0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 7))
            }
            .buttonStyle(.plain)
            .onHover { isActionHovered = $0 }
            .cursor(.pointingHand)
        }
        .padding(16)
        .frame(width: 240)
        .background(Color.kimiPanelBackground)
        .onChange(of: webAuth.authorizationState) { _, state in
            if case .succeeded = state, webAuth.authorizationAccountID == accountID {
                onSuccess()
            }
        }
        .onDisappear {
            webAuth.cancelAuthorization(for: accountID)
        }
    }

    private var statusText: String {
        switch webAuth.authorizationState {
        case .idle, .creating: return LanguageManager.tr("正在生成二维码…")
        case .waiting: return LanguageManager.tr("请使用同一 Kimi 账号扫码")
        case .scanned: return LanguageManager.tr("已扫码，请在手机上确认")
        case .succeeded: return LanguageManager.tr("授权成功")
        case .failed(let message): return message
        }
    }

    private var buttonTitle: String {
        if case .failed = webAuth.authorizationState { return "重新生成" }
        return "取消"
    }

    private func buttonAction() {
        if case .failed = webAuth.authorizationState {
            webAuth.startAuthorization(for: accountID)
        } else {
            dismiss()
        }
    }

    private static func qrCodeImage(for string: String) -> NSImage? {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(Data(string.utf8), forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let output = filter.outputImage else { return nil }
        let representation = NSCIImageRep(ciImage: output)
        let image = NSImage(size: representation.size)
        image.addRepresentation(representation)
        return image
    }
}

struct AccountAuthorizationDetailsView: View {
    let account: KimiAccount
    let onLogoutCLI: () -> Void

    @StateObject private var webAuth = KimiWebAuthService.shared
    @StateObject private var model = KimiCodeBarModel.shared
    @State private var isAuthorizationPresented = false

    var body: some View {
        VStack(spacing: 0) {
            AuthorizationLoginInfoRow(
                title: "Kimi Code 登录",
                detail: cliDetail,
                status: cliStatus,
                statusColor: account.oauthToken?.needsRefresh == true ? .red : .green,
                disabled: false
            ) {
                onLogoutCLI()
            }

            SettingsCardDivider()

            AuthorizationLoginInfoRow(
                title: "订阅授权",
                detail: webDetail,
                status: webAuth.hasCredential(for: account.id) ? "已授权" : "未授权",
                statusColor: webAuth.hasCredential(for: account.id) ? .green : .kimiTextTertiary,
                disabled: !webAuth.hasCredential(for: account.id),
                onAuthorize: {
                    isAuthorizationPresented = true
                    webAuth.startAuthorization(for: account.id)
                }
            ) {
                model.removeSubscriptionAuthorization(for: account.id)
            }
        }
        .popover(isPresented: $isAuthorizationPresented, arrowEdge: .trailing) {
            KimiWebAuthorizationView(accountID: account.id) {
                model.subscriptionAuthorizationDidChange(for: account.id)
                isAuthorizationPresented = false
            }
        }
        .onChange(of: isAuthorizationPresented) { _, presented in
            if !presented { webAuth.cancelAuthorization(for: account.id) }
        }
    }

    private var cliDetail: String {
        if case .apiKey = account.credential {
            return LanguageManager.tr("API Key 登录")
        }
        guard let token = account.oauthToken else { return LanguageManager.tr("尚未授权") }
        return LanguageManager.tr("授权到期 %@", arguments: [Self.dateText(token.expiresAtDate)])
    }

    private var cliStatus: String {
        if case .apiKey = account.credential { return "已授权" }
        return account.oauthToken?.needsRefresh == true ? "已过期" : "已授权"
    }

    private var webDetail: String {
        guard webAuth.hasCredential(for: account.id) else { return LanguageManager.tr("尚未授权") }
        guard let date = webAuth.authorizationDate(for: account.id) else {
            return LanguageManager.tr("网页凭证已保存")
        }
        return LanguageManager.tr("授权时间 %@", arguments: [Self.dateText(date)])
    }

    private static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

private struct AuthorizationLoginInfoRow: View {
    let title: String
    let detail: String
    let status: String
    let statusColor: Color
    let disabled: Bool
    var onAuthorize: (() -> Void)? = nil
    let onLogout: () -> Void

    @State private var isHovered = false
    @State private var isAuthorizationHovered = false

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                LText(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.kimiTextPrimary)
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(.kimiTextTertiary)
            }

            Spacer(minLength: 8)

            LText(status)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(statusColor)

            if let onAuthorize {
                Button(action: onAuthorize) {
                    LText(disabled ? "扫码授权" : "重新扫码")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(isAuthorizationHovered ? .white : .kimiBlue)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color.kimiBlue.opacity(isAuthorizationHovered ? 0.85 : 0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .onHover { isAuthorizationHovered = $0 }
                .cursor(.pointingHand)
            }

            Button(action: onLogout) {
                LText("退出登录")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(disabled ? .kimiTextTertiary : .red)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color.red.opacity(isHovered && !disabled ? 0.16 : 0.09))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .disabled(disabled)
            .onHover { isHovered = $0 }
            .cursor(disabled ? .arrow : .pointingHand)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }
}

struct KimiConsoleSplitButton: View {
    let onOpenOriginal: () -> Void
    let onOpenSubscription: () -> Void

    @State private var isOriginalHovered = false
    @State private var isSubscriptionHovered = false

    var body: some View {
        HStack(spacing: 0) {
            consoleHalf(
                title: "KIMI",
                isHovered: isOriginalHovered,
                onHover: { isOriginalHovered = $0 },
                action: onOpenOriginal
            )

            Rectangle()
                .fill(Color.kimiTextPrimary.opacity(0.10))
                .frame(width: 1, height: 34)

            consoleHalf(
                title: "订阅",
                isHovered: isSubscriptionHovered,
                onHover: { isSubscriptionHovered = $0 },
                action: onOpenSubscription
            )
        }
        .frame(maxWidth: .infinity)
        .frame(height: 62)
        .background(Color.kimiTextPrimary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func consoleHalf(
        title: String,
        isHovered: Bool,
        onHover: @escaping (Bool) -> Void,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                LText(title)
                    .font(.system(size: 11, weight: .bold))
                LText("控制台")
                    .font(.system(size: 11, weight: .medium))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundStyle(isHovered ? .kimiTextPrimary : .kimiTextSecondary)
            .background(isHovered ? Color.kimiTextPrimary.opacity(0.10) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover(perform: onHover)
        .cursor(.pointingHand)
    }
}
