import SwiftUI

struct SettingsSecurityPrivacyView: View {
    @State private var securitySettings = SecuritySettings.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Security & Privacy")
                    .font(UITheme.Typography.title)
                
                Text("Manage JavaScript settings and HTTPS enforcement for secure browsing.")
                    .font(UITheme.Typography.body)
                    .foregroundColor(UITheme.Colors.secondary)
                
                VStack(alignment: .leading, spacing: 20) {
                    JavaScriptControlSection(securitySettings: securitySettings)
                    HTTPSEnforcementSection(securitySettings: securitySettings)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
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
