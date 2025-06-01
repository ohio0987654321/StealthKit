//
//  WelcomeView.swift
//  SwiftBrowser
//
//  Native SwiftUI welcome screen shown when no tabs are open.
//

import SwiftUI

struct WelcomeView: View {
    let onCreateNewTab: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "safari")
                    .font(.system(size: 64, weight: .light))
                    .foregroundColor(.accentColor)
                
                Text("SwiftBrowser")
                    .font(.largeTitle)
                    .fontWeight(.light)
                    .foregroundColor(.primary)
                
                Text("A modern, privacy-focused browser")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 16) {
                Button(action: onCreateNewTab) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                        Text("Create New Tab")
                    }
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                Text("Or press ⌘T to create a new tab")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.controlBackgroundColor).opacity(0.5))
    }
}
