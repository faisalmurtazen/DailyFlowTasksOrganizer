import Foundation
import SwiftUI
import WebKit
internal import Combine

@MainActor
class WebViewModel: ObservableObject {
    @Published var isLoading = true
    @Published var loadingProgress: Double = 0.0
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var currentURL: String = ""
    
    private var webView: WKWebView?
    
    func setWebView(_ webView: WKWebView) {
        self.webView = webView
    }
    
    func loadURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        let request = URLRequest(url: url)
        webView?.load(request)
    }
    
    func reload() {
        webView?.reload()
    }
    
    func goBack() {
        webView?.goBack()
    }
    
    func goForward() {
        webView?.goForward()
    }
    
    func updateNavigationState() {
        canGoBack = webView?.canGoBack ?? false
        canGoForward = webView?.canGoForward ?? false
        currentURL = webView?.url?.absoluteString ?? ""
    }
}

