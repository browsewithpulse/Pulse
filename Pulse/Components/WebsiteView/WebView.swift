import SwiftUI
import WebKit

struct WebView: NSViewRepresentable {
    let urlString: String
    var onTitleChange: ((String) -> Void)? = nil
    var onURLChange: ((String) -> Void)? = nil

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore.default()

        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences
        
        // Important: Enable modern web features
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator

        webView.allowsBackForwardNavigationGestures = true
        webView.allowsMagnification = true

        // Use the exact Chrome user agent that works
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"

        context.coordinator.onTitleChange = onTitleChange
        context.coordinator.onURLChange = onURLChange

        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        guard let url = URL(string: urlString) else { return }

        if webView.url != url {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        context.coordinator.onTitleChange = onTitleChange
        context.coordinator.onURLChange = onURLChange
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}

// MARK: - Coordinator
extension WebView {
    class Coordinator: NSObject {
        var onTitleChange: ((String) -> Void)?
        var onURLChange: ((String) -> Void)?
    }
}

// MARK: - WKNavigationDelegate
extension WebView.Coordinator: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("Started loading: \(webView.url?.absoluteString ?? "")")
        if let url = webView.url?.absoluteString {
            onURLChange?(url)
        }
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print("Content started loading: \(webView.url?.absoluteString ?? "")")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Finished loading: \(webView.url?.absoluteString ?? "")")
        
        webView.evaluateJavaScript("document.title") { [weak self] result, error in
            if let title = result as? String, !title.isEmpty {
                DispatchQueue.main.async {
                    self?.onTitleChange?(title)
                }
            }
        }
        
        if let url = webView.url?.absoluteString {
            onURLChange?(url)
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Navigation failed: \(error.localizedDescription)")
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("Provisional navigation failed: \(error.localizedDescription)")
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.allow)
    }
}

// MARK: - WKUIDelegate
extension WebView.Coordinator: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = NSAlert()
        alert.messageText = "JavaScript Alert"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
        completionHandler()
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = NSAlert()
        alert.messageText = "JavaScript Confirm"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        let response = alert.runModal()
        completionHandler(response == .alertFirstButtonReturn)
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alert = NSAlert()
        alert.messageText = "JavaScript Prompt"
        alert.informativeText = prompt
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        textField.stringValue = defaultText ?? ""
        alert.accessoryView = textField

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            completionHandler(textField.stringValue)
        } else {
            completionHandler(nil)
        }
    }
}
