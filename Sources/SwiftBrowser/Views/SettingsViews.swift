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
    @State private var windowUtilityManager = StealthManager.shared
    @State private var windowManager = WindowManager.shared
    
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
                            Toggle("NSPanel Window Cloaking", isOn: Binding(
                                get: { windowUtilityManager.isWindowCloakingEnabled },
                                set: { windowUtilityManager.setWindowCloakingEnabled($0) }
                            ))
                            Text("Makes browser windows invisible to screen recording and screenshot tools")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Toggle("Pin to Current Desktop", isOn: Binding(
                                get: { windowUtilityManager.isPinnedToCurrentDesktop },
                                set: { windowUtilityManager.setPinnedToCurrentDesktop($0) }
                            ))
                            .disabled(!windowUtilityManager.isWindowCloakingEnabled)
                            Text("When enabled, window stays on current virtual desktop only")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    GroupBox("Window Behavior") {
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle("Always on Top", isOn: Binding(
                                    get: { windowUtilityManager.isAlwaysOnTop },
                                    set: { windowUtilityManager.setAlwaysOnTop($0) }
                                ))
                                Text("Keep browser window above all other windows")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle("Hide window in Mission Control", isOn: Binding(
                                    get: { windowUtilityManager.hideInMissionControl },
                                    set: { windowUtilityManager.setHideInMissionControl($0) }
                                ))
                                .disabled(!windowUtilityManager.isAlwaysOnTop)
                                Text("When Always on Top is enabled, hide window during Mission Control")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    GroupBox("Window Transparency") {
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle("Enable Window Transparency", isOn: $windowManager.isTranslucencyEnabled)
                                Text("Make the browser window semi-transparent")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if windowManager.isTranslucencyEnabled {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Transparency Level")
                                            .font(.subheadline)
                                        Spacer()
                                        Text("\(Int((1.0 - windowManager.translucencyLevel) * 100))%")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Slider(
                                        value: Binding(
                                            get: { 1.0 - windowManager.translucencyLevel },
                                            set: { windowManager.translucencyLevel = 1.0 - $0 }
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
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle("Accessory App Mode", isOn: Binding(
                                    get: { windowUtilityManager.isAccessoryApp },
                                    set: { windowUtilityManager.setAccessoryApp($0) }
                                ))
                                Text("App runs as accessory without appearing in Dock or menu bar when focused")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle("Show Dock Icon", isOn: Binding(
                                    get: { windowUtilityManager.showDockIcon },
                                    set: { windowUtilityManager.setShowDockIcon($0) }
                                ))
                                .disabled(windowUtilityManager.isAccessoryApp)
                                Text("When disabled, app won't appear in Dock (accessory mode overrides this)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
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
