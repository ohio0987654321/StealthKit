import SwiftUI

struct SettingsSecurityPrivacyView: View {
    @State private var securitySettings = SecuritySettings.shared
    @State private var historyManager = HistoryManager.shared
    @State private var cookieManager = CookieManager.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Security & Privacy")
                    .font(UITheme.Typography.title)
                
                Text("Manage browsing history, cookies, JavaScript settings, and HTTPS enforcement.")
                    .font(UITheme.Typography.body)
                    .foregroundColor(UITheme.Colors.secondary)
                
                VStack(alignment: .leading, spacing: 20) {
                    HistoryLinkSection()
                    CookieManagementSection(cookieManager: cookieManager)
                    JavaScriptControlSection(securitySettings: securitySettings)
                    HTTPSEnforcementSection(securitySettings: securitySettings)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct HistoryLinkSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("History Management")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Browsing History")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("View, search, and manage your complete browsing history")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(HistoryManager.shared.historyItems.count) items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.controlBackgroundColor))
                )
                
                // Quick clear option
                HStack {
                    Button("Clear All History") {
                        HistoryManager.shared.clearHistory()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                    
                    Spacer()
                    
                    Text("Use the History tab in the sidebar for detailed management")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct CookieManagementSection: View {
    @Bindable var cookieManager: CookieManager
    @State private var selectedDomain: String? = nil
    @State private var showingClearAllCookiesAlert = false
    @State private var showingClearDomainCookiesAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cookie Management")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Button("Refresh Cookies") {
                        Task {
                            await cookieManager.loadCookies()
                        }
                    }
                    
                    Spacer()
                    
                    Button("Clear All Cookies") {
                        showingClearAllCookiesAlert = true
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
                
                let domains = cookieManager.getAllDomains()
                if domains.isEmpty {
                    Text("No cookies found")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                } else {
                    List(domains, id: \.self) { domain in
                        CookieDomainRow(
                            domain: domain,
                            cookieManager: cookieManager,
                            selectedDomain: $selectedDomain,
                            showingClearDomainCookiesAlert: $showingClearDomainCookiesAlert
                        )
                    }
                    .frame(maxHeight: 200)
                }
            }
        }
        .onAppear {
            Task {
                await cookieManager.loadCookies()
            }
        }
        .alert("Clear All Cookies", isPresented: $showingClearAllCookiesAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                Task {
                    await cookieManager.clearAllCookies()
                }
            }
        } message: {
            Text("This will log you out of all websites and clear all stored cookies.")
        }
        .alert("Clear Domain Cookies", isPresented: $showingClearDomainCookiesAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                if let domain = selectedDomain {
                    Task {
                        await cookieManager.clearCookiesForDomain(domain)
                    }
                }
            }
        } message: {
            if let domain = selectedDomain {
                Text("This will clear all cookies for \(domain) and may log you out of that website.")
            }
        }
    }
}

struct CookieDomainRow: View {
    let domain: String
    let cookieManager: CookieManager
    @Binding var selectedDomain: String?
    @Binding var showingClearDomainCookiesAlert: Bool
    
    var body: some View {
        DisclosureGroup {
            let cookies = cookieManager.getCookies(for: domain)
            ForEach(cookies, id: \.id) { cookie in
                VStack(alignment: .leading, spacing: 2) {
                    Text(cookie.name)
                        .font(.caption)
                        .fontWeight(.medium)
                    Text("Path: \(cookie.path)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    if let expiresDate = cookie.expiresDate {
                        Text("Expires: \(expiresDate, style: .date)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.leading, 16)
            }
            
            Button("Clear Cookies for \(domain)") {
                selectedDomain = domain
                showingClearDomainCookiesAlert = true
            }
            .buttonStyle(.bordered)
            .foregroundColor(.red)
            .font(.caption)
            .padding(.leading, 16)
            .padding(.top, 4)
        } label: {
            HStack {
                Text(domain)
                    .font(.subheadline)
                Spacer()
                Text("\(cookieManager.getCookies(for: domain).count) cookies")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct JavaScriptControlSection: View {
    @Bindable var securitySettings: SecuritySettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("JavaScript Control")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Enable JavaScript", isOn: $securitySettings.isJavaScriptEnabled)
                
                Text("Controls whether JavaScript is enabled globally for all websites")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 20)
            }
        }
    }
}

struct HTTPSEnforcementSection: View {
    @Bindable var securitySettings: SecuritySettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HTTPS Enforcement")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Force HTTPS", isOn: $securitySettings.isHTTPSEnforcementEnabled)
                
                Text("Automatically redirects HTTP requests to HTTPS when possible")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 20)
            }
        }
    }
}
