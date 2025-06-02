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

struct SettingsWindowTransparencyView: View {
    @State private var windowManager = WindowManager.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Window Transparency")
                    .font(UITheme.Typography.title)
                
                Text("Configure window transparency settings for privacy and visual customization.")
                    .font(UITheme.Typography.body)
                    .foregroundColor(UITheme.Colors.secondary)
                
                ThemedCard {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Enable Window Transparency")
                                    .font(UITheme.Typography.headline)
                                Text("Make the browser window semi-transparent")
                                    .font(UITheme.Typography.caption)
                                    .foregroundColor(UITheme.Colors.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $windowManager.isTranslucencyEnabled)
                                .toggleStyle(SwitchToggleStyle())
                        }
                        
                        if windowManager.isTranslucencyEnabled {
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Transparency Level")
                                        .font(UITheme.Typography.headline)
                                    Spacer()
                                    Text("\(Int((1.0 - windowManager.translucencyLevel) * 100))%")
                                        .font(UITheme.Typography.caption)
                                        .foregroundColor(UITheme.Colors.secondary)
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
                                        .font(UITheme.Typography.caption)
                                        .foregroundColor(UITheme.Colors.secondary)
                                } maximumValueLabel: {
                                    Text("70%")
                                        .font(UITheme.Typography.caption)
                                        .foregroundColor(UITheme.Colors.secondary)
                                }
                                
                                Text("Higher values make the window more transparent. Very high transparency may affect readability.")
                                    .font(UITheme.Typography.caption)
                                    .foregroundColor(UITheme.Colors.secondary)
                            }
                        }
                    }
                    .padding(UITheme.Spacing.medium)
                }
                
                ThemedCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Important Notes")
                            .font(UITheme.Typography.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Transparency affects the entire window frame, not web content", systemImage: "info.circle")
                                .font(UITheme.Typography.body)
                                .foregroundColor(UITheme.Colors.secondary)
                            
                            Label("Web content remains fully opaque for readability", systemImage: "eye")
                                .font(UITheme.Typography.body)
                                .foregroundColor(UITheme.Colors.secondary)
                            
                            Label("Changes apply immediately to all browser windows", systemImage: "rectangle.on.rectangle")
                                .font(UITheme.Typography.body)
                                .foregroundColor(UITheme.Colors.secondary)
                        }
                    }
                    .padding(UITheme.Spacing.medium)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
