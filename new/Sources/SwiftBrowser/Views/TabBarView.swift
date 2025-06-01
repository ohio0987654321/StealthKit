//
//  TabBarView.swift
//  SwiftBrowser
//
//  Tab bar interface for managing multiple browser tabs.
//  Replaces the Objective-C TabBarView implementation.
//

import SwiftUI

struct TabBarView: View {
    let tabs: [Tab]
    let currentTabIndex: Int
    let onTabSelected: (Int) -> Void
    let onTabClosed: (Int) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(tabs.enumerated()), id: \.element.id) { index, tab in
                    TabItemView(
                        tab: tab,
                        isSelected: index == currentTabIndex,
                        onSelected: { onTabSelected(index) },
                        onClosed: { onTabClosed(index) }
                    )
                }
            }
        }
        .frame(height: 36)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct TabItemView: View {
    let tab: Tab
    let isSelected: Bool
    let onSelected: () -> Void
    let onClosed: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tab.title)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: 150)
            
            if isHovering || isSelected {
                Button(action: onClosed) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10))
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isSelected ? Color(NSColor.selectedControlColor) : Color.clear)
        .onTapGesture {
            onSelected()
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
