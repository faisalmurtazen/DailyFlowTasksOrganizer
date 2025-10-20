import SwiftUI
import WebKit
import UniformTypeIdentifiers
import PhotosUI

// MARK: - WebViewContainer
struct WebViewContainer: View {
    @StateObject private var viewModel = WebViewModel()
    @State private var showSplash = true
    @State private var isConnected = true

    let url: String

    var body: some View {
        ZStack {
            if isConnected {
                WebView(viewModel: viewModel, url: url)
                    .edgesIgnoringSafeArea(.all)
                    .opacity(showSplash ? 0 : 1)
            } else {
                Color.black
                    .edgesIgnoringSafeArea(.all)
                Text("No internet connection")
                    .foregroundColor(.white)
                    .font(.system(size: 20, weight: .medium, design: .rounded))
            }

            if showSplash {
                SplashView()
                    .transition(.opacity)
            }
        }
        .statusBar(hidden: true)
        .onAppear {
            checkConnection()
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
    }

    private func checkConnection() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.isConnected = path.status == .satisfied
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
}


// MARK: - WebView
struct WebView: UIViewRepresentable {
    @ObservedObject var viewModel: WebViewModel
    let url: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self, viewModel: viewModel)
    }

    func makeUIView(context: Context) -> WKWebView {
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true

        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences = preferences
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        // Enable cookies and file access
        let dataStore = WKWebsiteDataStore.default()
        configuration.websiteDataStore = dataStore
        configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.contentInset = .zero
        webView.scrollView.scrollIndicatorInsets = .zero
        webView.overrideUserInterfaceStyle = .dark

        // Sync shared cookies
        for cookie in HTTPCookieStorage.shared.cookies ?? [] {
            dataStore.httpCookieStore.setCookie(cookie)
        }

        viewModel.setWebView(webView)

        if let url = URL(string: url) {
            let request = URLRequest(url: url)
            webView.load(request)
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

// MARK: - Coordinator
class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, UIDocumentPickerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
    var parent: WebView
    var viewModel: WebViewModel
    var filePickerCompletion: (([URL]?) -> Void)?

    init(_ parent: WebView, viewModel: WebViewModel) {
        self.parent = parent
        self.viewModel = viewModel
    }

    // MARK: - Navigation Delegate
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.viewModel.isLoading = true
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.viewModel.isLoading = false
            self.viewModel.updateNavigationState()
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async {
            self.viewModel.isLoading = false
        }
    }

    // MARK: - File upload handler
    @available(iOS 18.4, *)
    func webView(
        _ webView: WKWebView,
        runOpenPanelWith parameters: WKOpenPanelParameters,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping ([URL]?) -> Void
    ) {
        filePickerCompletion = completionHandler

        let alert = UIAlertController(title: "Select Source", message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Photo / Video", style: .default) { _ in
            self.presentImagePicker()
        })

        alert.addAction(UIAlertAction(title: "Files", style: .default) { _ in
            self.presentDocumentPicker()
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completionHandler(nil)
        })

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(alert, animated: true)
        }
    }

    private func presentImagePicker() {
        var config = PHPickerConfiguration()
        config.filter = .any(of: [.images, .videos])
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker)
    }

    private func presentDocumentPicker() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker)
    }

    private func present(_ controller: UIViewController) {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(controller, animated: true)
        }
    }

    // MARK: - Document picker delegate
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        filePickerCompletion?(urls)
        filePickerCompletion = nil
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        filePickerCompletion?(nil)
        filePickerCompletion = nil
    }

    // MARK: - Photo picker delegate
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let result = results.first else {
            filePickerCompletion?(nil)
            filePickerCompletion = nil
            return
        }

        result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, _ in
            DispatchQueue.main.async {
                self.filePickerCompletion?(url.map { [$0] })
                self.filePickerCompletion = nil
            }
        }
    }

    // MARK: - Alerts
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
        present(alert)
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
        present(alert)
    }
}

// MARK: - Splash View
struct SplashView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 24) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(Color.white)
                Text("Loading...")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
    }
}
