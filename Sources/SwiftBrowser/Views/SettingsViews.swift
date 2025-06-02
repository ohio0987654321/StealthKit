import SwiftUI

struct SettingsSearchEngineView: View {
    @State private var settings = AppSettings.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Search Engine")
                    .font(UITheme.Typography.title)
                
                Text("Choose your default search engine and configure search preferences.")
                    .font(UITheme.Typography.body)
                    .foregroundColor(UITheme.Colors.secondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Default Search Engine")
                        .font(.headline)
                    
                    Picker("Search Engine", selection: $settings.defaultSearchEngine) {
                        ForEach(SearchEngine.allCases) { engine in
                            Text(engine.name).tag(engine)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct SettingsWindowUtilitiesView: View {
    @State private var windowService = WindowService.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Window Utilities")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Configure window management features and privacy utilities.")
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 16) {
                    GroupBox("Screen Recording Bypass") {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("NSPanel Window Cloaking", isOn: $windowService.isCloakingEnabled)
                            Text("Makes browser windows invisible to screen recording and screenshot tools")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Toggle("Pin to Current Desktop", isOn: $windowService.isPinnedToCurrentDesktop)
                            .disabled(!windowService.isCloakingEnabled)
                            Text("When enabled, window stays on current virtual desktop only")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    GroupBox("Window Behavior") {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("Always on Top", isOn: $windowService.isAlwaysOnTop)
                            Text("Keep browser window above all other windows. Note: Always on Top windows are hidden during Mission Control.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    GroupBox("Window Transparency") {
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle("Enable Window Transparency", isOn: $windowService.isTransparencyEnabled)
                                Text("Make the browser window semi-transparent")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if windowService.isTransparencyEnabled {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Transparency Level")
                                            .font(.subheadline)
                                        Spacer()
                                        Text("\(Int((1.0 - windowService.transparencyLevel) * 100))%")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Slider(
                                        value: Binding(
                                            get: { 1.0 - windowService.transparencyLevel },
                                            set: { windowService.transparencyLevel = 1.0 - $0 }
                                        ),
                                        in: 0.1...0.7
                                    ) {
                                        Text("Transparency")
                                    } minimumValueLabel: {
                                        Text("10%")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    } maximumValueLabel: {
                                        Text("70%")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    GroupBox("Application Behavior") {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("Accessory App Mode", isOn: $windowService.isAccessoryApp)
                            Text("When enabled: App won't appear in Dock or menu bar when focused. When disabled: Normal dock icon behavior.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
