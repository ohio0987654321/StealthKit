//
//  SettingsView.swift
//  SwiftBrowser
//
//  Simplified settings interface focusing on essential features and stealth extensions.
//

import SwiftUI

struct SettingsView: View {
    @State private var settings = AppSettings.shared
    @State private var selectedTab: SettingsTab = .general
    @State private var extensions = BrowserExtension.defaultExtensions
    @State private var expandedExtensions: Set<UUID> = []
    
    var body: some View {
        NavigationSplitView {
            // Settings sidebar
            List(SettingsTab.allCases, id: \.self, selection: $selectedTab) { tab in
                HStack {
                    Image(systemName: tab.icon)
                        .frame(width: 20)
                    Text(tab.title)
                }
                .tag(tab)
            }
            .navigationTitle("Settings")
            .frame(minWidth: 200)
        } detail: {
            // Settings content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    settingsContent
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(selectedTab.title)
        }
        .frame(minWidth: 600, minHeight: 400)
        .onDisappear {
            settings.saveSettings()
        }
    }
    
    @ViewBuilder
    private var settingsContent: some View {
        switch selectedTab {
        case .general:
            GeneralSettingsView(settings: settings)
        case .extensions:
            ExtensionsSettingsView(
                extensions: $extensions,
                expandedExtensions: $expandedExtensions
            )
        }
    }
}

enum SettingsTab: String, CaseIterable {
    case general = "General"
    case extensions = "Extensions"
    
    var title: String { rawValue }
    
    var icon: String {
        switch self {
        case .general: return "gear"
        case .extensions: return "puzzlepiece.extension"
        }
    }
}

// MARK: - General Settings (Simplified)

struct GeneralSettingsView: View {
    @Bindable var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("General")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Default Search Engine")
                    .fontWeight(.medium)
                Picker("Search Engine", selection: $settings.defaultSearchEngine) {
                    ForEach(SearchEngine.allCases) { engine in
                        Text(engine.name).tag(engine)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }
}

// MARK: - Extensions Settings (New Expandable Design)

struct ExtensionsSettingsView: View {
    @Binding var extensions: [BrowserExtension]
    @Binding var expandedExtensions: Set<UUID>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Extensions")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Stealth browser extensions and their configurations")
                .foregroundColor(.secondary)
                .font(.subheadline)
            
            LazyVStack(spacing: 12) {
                ForEach($extensions) { $browserExtension in
                    ExtensionRowView(
                        browserExtension: $browserExtension,
                        isExpanded: Binding(
                            get: { expandedExtensions.contains(browserExtension.id) },
                            set: { isExpanded in
                                if isExpanded {
                                    expandedExtensions.insert(browserExtension.id)
                                } else {
                                    expandedExtensions.remove(browserExtension.id)
                                }
                            }
                        )
                    )
                }
            }
        }
    }
}

struct ExtensionRowView: View {
    @Binding var browserExtension: BrowserExtension
    @Binding var isExpanded: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Extension header (always visible)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: browserExtension.icon)
                        .foregroundColor(.accentColor)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(browserExtension.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(browserExtension.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $browserExtension.isEnabled)
                        .labelsHidden()
                        .onTapGesture { }
                    
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // Extension settings panel (expandable)
            if isExpanded {
                ExtensionSettingsPanel(browserExtension: $browserExtension)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
            }
        }
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.separatorColor), lineWidth: 1)
        )
    }
}

struct ExtensionSettingsPanel: View {
    @Binding var browserExtension: BrowserExtension
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
                .padding(.horizontal, 16)
            
            if browserExtension.isEnabled {
                ForEach(Array(browserExtension.settings.enumerated()), id: \.offset) { index, setting in
                    ExtensionSettingRow(
                        setting: setting,
                        onChange: { newValue in
                            browserExtension.settings[index].value = newValue
                        }
                    )
                    .padding(.horizontal, 16)
                }
            } else {
                Text("Enable this extension to configure its settings")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 12)
    }
}

struct ExtensionSettingRow: View {
    let setting: ExtensionSetting
    let onChange: (Any) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(setting.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                settingControl
            }
            
            if let description = setting.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private var settingControl: some View {
        switch setting.type {
        case .toggle:
            Toggle("", isOn: Binding(
                get: { setting.value as? Bool ?? false },
                set: { onChange($0) }
            ))
            .labelsHidden()
            
        case .slider(let min, let max, let step):
            HStack {
                Slider(
                    value: Binding(
                        get: { setting.value as? Double ?? min },
                        set: { onChange($0) }
                    ),
                    in: min...max,
                    step: step
                )
                .frame(width: 100)
                
                Text(String(format: "%.1f", setting.value as? Double ?? min))
                    .font(.caption)
                    .monospacedDigit()
                    .frame(width: 30)
            }
            
        case .picker(let options):
            Picker("", selection: Binding(
                get: { setting.value as? String ?? options.first ?? "" },
                set: { onChange($0) }
            )) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 120)
            
        case .text:
            TextField("", text: Binding(
                get: { setting.value as? String ?? "" },
                set: { onChange($0) }
            ))
            .textFieldStyle(.roundedBorder)
            .frame(width: 120)
            
        case .hotkey:
            Text(setting.value as? String ?? "None")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }
}

// MARK: - Privacy Settings (Simplified)
