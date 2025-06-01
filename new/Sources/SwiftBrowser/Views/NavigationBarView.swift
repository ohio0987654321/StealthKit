//
//  NavigationBarView.swift
//  SwiftBrowser
//
//  Navigation bar with address bar and browser controls.
//  Replaces the Objective-C ToolbarView and AddressBarView combination.
//

import SwiftUI

struct NavigationBarView: View {
    @Binding var currentTab: Tab?
    let onNavigate: (URL) -> Void
    let onBack: () -> Void
    let onForward: () -> Void
    let onReload: () -> Void
    let onNewTab: () -> Void
    
    @State private var addressText: String = ""
    @State private var isEditing: Bool = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Back button
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .frame(width: 24, height: 24)
            }
            .disabled(!(currentTab?.canGoBack ?? false))
            
            // Forward button
            Button(action: onForward) {
                Image(systemName: "chevron.right")
                    .frame(width: 24, height: 24)
            }
            .disabled(!(currentTab?.canGoForward ?? false))
            
            // Reload button
            Button(action: onReload) {
                Image(systemName: currentTab?.isLoading == true ? "xmark" : "arrow.clockwise")
                    .frame(width: 24, height: 24)
            }
            
            // Address bar
            TextField("Enter URL or search", text: $addressText)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    handleAddressSubmit()
                }
                .onTapGesture {
                    isEditing = true
                    addressText = currentTab?.url?.absoluteString ?? ""
                }
            
            // New tab button
            Button(action: onNewTab) {
                Image(systemName: "plus")
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .onChange(of: currentTab?.url) { _, newURL in
            if !isEditing {
                addressText = newURL?.absoluteString ?? ""
            }
        }
        .onAppear {
            addressText = currentTab?.url?.absoluteString ?? ""
        }
    }
    
    private func handleAddressSubmit() {
        isEditing = false
        
        if let url = createURL(from: addressText) {
            onNavigate(url)
        }
    }
    
    private func createURL(from text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return nil
        }
        
        // Try as direct URL first
        if let url = URL(string: trimmed), url.scheme != nil {
            return url
        }
        
        // Add https:// if it looks like a domain
        if trimmed.contains(".") && !trimmed.contains(" ") {
            if let url = URL(string: "https://\(trimmed)") {
                return url
            }
        }
        
        // Fall back to configured search engine
        let searchQuery = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let searchEngine = AppSettings.shared.defaultSearchEngine
        return URL(string: "\(searchEngine.searchURL)\(searchQuery)")
    }
    

}
