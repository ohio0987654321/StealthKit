//
//  Extension.swift
//  SwiftBrowser
//
//  Data model representing browser extensions with stealth capabilities.
//

import Foundation

@Observable
class BrowserExtension: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    var isEnabled: Bool
    var settings: [ExtensionSetting]
    
    init(name: String, description: String, icon: String, isEnabled: Bool = true, settings: [ExtensionSetting] = []) {
        self.name = name
        self.description = description
        self.icon = icon
        self.isEnabled = isEnabled
        self.settings = settings
    }
}

struct ExtensionSetting {
    let id = UUID()
    let name: String
    let type: SettingType
    var value: Any
    let description: String?
    
    enum SettingType {
        case toggle
        case slider(min: Double, max: Double, step: Double)
        case picker(options: [String])
        case text
        case hotkey
    }
}

// Default stealth extensions
extension BrowserExtension {
    static let defaultExtensions: [BrowserExtension] = [
        BrowserExtension(
            name: "Stealth Mode",
            description: "Core stealth browsing functionality",
            icon: "eye.slash.fill",
            settings: [
                ExtensionSetting(
                    name: "Enable Stealth Mode",
                    type: .toggle,
                    value: false,
                    description: "Activate stealth browsing features"
                ),
                ExtensionSetting(
                    name: "Stealth Level",
                    type: .picker(options: ["Basic", "Advanced", "Maximum"]),
                    value: "Basic",
                    description: "Level of stealth protection"
                ),
                ExtensionSetting(
                    name: "Auto-activate on startup",
                    type: .toggle,
                    value: false,
                    description: "Automatically enable stealth mode when app starts"
                )
            ]
        )
    ]
}
