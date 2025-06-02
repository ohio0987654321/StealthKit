import SwiftUI

struct WelcomeView: View {
    let onCreateNewTab: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "safari")
                    .font(.system(size: 80, weight: .ultraLight))
                    .foregroundStyle(.tint)
                
                VStack(spacing: 8) {
                    Text("SwiftBrowser")
                        .font(.system(.largeTitle, design: .rounded, weight: .light))
                        .foregroundStyle(.primary)
                    
                    Text("Fast, Private, Secure")
                        .font(.system(.title3, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            
            VStack(spacing: 20) {
                Button(action: onCreateNewTab) {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                        Text("Create New Tab")
                            .font(.system(.body, design: .rounded, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(.tint, in: RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                
                VStack(spacing: 8) {
                    Text("Or press ⌘T to create a new tab")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 16) {
                        Text("⌘W")
                            .font(.system(.caption2, design: .monospaced, weight: .medium))
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 4))
                        
                        Text("Close")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(.tertiary)
                        
                        Text("⌘R")
                            .font(.system(.caption2, design: .monospaced, weight: .medium))
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 4))
                        
                        Text("Reload")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial, in: Rectangle())
        .overlay {
            // Subtle gradient overlay for depth
            LinearGradient(
                gradient: Gradient(colors: [
                    .clear,
                    .accentColor.opacity(0.02),
                    .clear
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
