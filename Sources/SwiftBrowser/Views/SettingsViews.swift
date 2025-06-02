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
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle("Window Transparency", isOn: Binding(
                                    get: { windowUtilityManager.isWindowTransparencyEnabled },
                                    set: { windowUtilityManager.setWindowTransparencyEnabled($0) }
                                ))
                                Text("Make the browser window semi-transparent")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if windowUtilityManager.isWindowTransparencyEnabled {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text("Transparency Level")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            Text("\(Int((1.0 - windowUtilityManager.windowTransparencyLevel) * 100))%")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Slider(
                                            value: Binding(
                                                get: { 1.0 - windowUtilityManager.windowTransparencyLevel },
                                                set: { windowUtilityManager.setWindowTransparencyLevel(1.0 - $0) }
                                            ),
                                            in: 0.1...0.9
                                        )
                                    }
                                    .padding(.top, 4)
                                }
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
