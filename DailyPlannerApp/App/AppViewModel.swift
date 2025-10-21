import SwiftUI
import SwiftData
internal import Combine
import Network
@MainActor
class AppViewModel: ObservableObject {
    @Published var showSplash = true
    @Published var isLoading = true
    @Published var showWebView = false
    @Published var showOfflineScreen = false
    @Published var showNativeFallback = false
    @Published var webURL: String?
    @Published var isConnected = true
    
    private let webManager = WebRequestManager.shared
    private let monitor = NWPathMonitor()
    
    let webRequestManager = WebRequestManager.shared
    
    init() {
        startNetworkMonitor()
        setupObservers()
    }
    
    private func setupObservers() {
        Task {
            for await _ in NotificationCenter.default.notifications(named: NSNotification.Name("WebURLUpdated")) {
                await updateWebViewState()
            }
        }
    }
    
    private func startNetworkMonitor() {
        monitor.pathUpdateHandler = { path in
            Task { @MainActor in
                self.isConnected = path.status == .satisfied
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
    
    func initialize() async {
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        await webManager.checkServerResponse()
        
        await updateWebViewState()
        
        if webURL == nil {
            showNativeFallback = true
        } else if !isConnected {
            showOfflineScreen = true
        }
        
        isLoading = false
    }
    
    private func updateWebViewState() async {
        await MainActor.run {
            showWebView = webManager.shouldShowWeb && isConnected
            webURL = webManager.urlString
        }
    }
    
    func reloadWebViewIfConnected() async {
        if isConnected, let url = webManager.urlString {
            showWebView = true
            showOfflineScreen = false
        }
    }
}

