import SwiftUI
import WebKit

struct CookieManagementView: View {
    @State private var cookieManager = CookieManager.shared
    @State private var selectedDomain: String? = nil
    @State private var searchText = ""
    @State private var showingClearAlert = false
    @State private var showingDomainClearAlert = false
    @State private var sortOption: SortOption = .alphabetical
    
    enum SortOption: String, CaseIterable {
        case alphabetical = "A-Z"
        case mostCookies = "Most Cookies"
        case latest = "Latest"
    }
    
    var filteredDomains: [String] {
        let domains = Array(cookieManager.cookiesByDomain.keys)
        let filtered = searchText.isEmpty ? domains : domains.filter { domain in
            domain.localizedCaseInsensitiveContains(searchText)
        }
        
        return sortDomains(filtered)
    }
    
    var selectedDomainCookies: [CookieItem] {
        guard let domain = selectedDomain else { return [] }
        return cookieManager.cookiesByDomain[domain] ?? []
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Domains sidebar
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 16) {
                    Text("Cookie Management")
                        .font(UITheme.Typography.title)
                    
                    Text("View and manage cookies by domain")
                        .font(UITheme.Typography.body)
                        .foregroundColor(UITheme.Colors.secondary)
                    
                    // Search and controls
                    HStack {
                        TextField("Search domains...", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                        
                        Picker("Sort", selection: $sortOption) {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 120)
                    }
                    
                    // Action buttons
                    HStack {
                        Button("Refresh Cookies") {
                            cookieManager.refreshCookies()
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                        
                        Button("Clear All Cookies") {
                            showingClearAlert = true
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                    }
                }
                .padding()
                
                Divider()
                
                // Domains list
                if filteredDomains.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No cookies found")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        if !searchText.isEmpty {
                            Text("Try adjusting your search terms")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.controlBackgroundColor))
                } else {
                    List(filteredDomains, id: \.self, selection: $selectedDomain) { domain in
                        DomainRowView(
                            domain: domain,
                            cookieCount: cookieManager.cookiesByDomain[domain]?.count ?? 0,
                            isSelected: selectedDomain == domain,
                            onDelete: { deleteDomainCookies(domain) }
                        )
                        .tag(domain)
                    }
                    .listStyle(.sidebar)
                }
            }
            .frame(maxWidth: 300)
            
            Divider()
            
            // Cookie details
            VStack(alignment: .leading, spacing: 0) {
                if let domain = selectedDomain {
                    // Header
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(domain)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Text("\(selectedDomainCookies.count) \(selectedDomainCookies.count == 1 ? "cookie" : "cookies")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Clear Domain Cookies") {
                                showingDomainClearAlert = true
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.red)
                        }
                    }
                    .padding()
                    
                    Divider()
                    
                    // Cookies list
                    if selectedDomainCookies.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "list.bullet.rectangle")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            
                            Text("No cookies for this domain")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.controlBackgroundColor))
                    } else {
                        List(selectedDomainCookies, id: \.id) { cookie in
                            CookieRowView(cookie: cookie)
                        }
                        .listStyle(.plain)
                    }
                } else {
                    // No domain selected
                    VStack(spacing: 16) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("Select a domain to view cookies")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("Choose a domain from the sidebar to see its cookies")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.controlBackgroundColor))
                }
            }
        }
        .alert("Clear All Cookies", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                cookieManager.deleteAllCookies()
                selectedDomain = nil
            }
        } message: {
            Text("This will permanently delete all cookies from all domains. This action cannot be undone.")
        }
        .alert("Clear Domain Cookies", isPresented: $showingDomainClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                if let domain = selectedDomain {
                    cookieManager.deleteCookies(for: domain)
                    if cookieManager.cookiesByDomain[domain]?.isEmpty == true || cookieManager.cookiesByDomain[domain] == nil {
                        selectedDomain = nil
                    }
                }
            }
        } message: {
            Text("This will permanently delete all cookies for \(selectedDomain ?? "this domain"). This action cannot be undone.")
        }
        .onAppear {
            cookieManager.refreshCookies()
        }
    }
    
    private func sortDomains(_ domains: [String]) -> [String] {
        switch sortOption {
        case .alphabetical:
            return domains.sorted()
        case .mostCookies:
            return domains.sorted { domain1, domain2 in
                let count1 = cookieManager.cookiesByDomain[domain1]?.count ?? 0
                let count2 = cookieManager.cookiesByDomain[domain2]?.count ?? 0
                return count1 > count2
            }
        case .latest:
            return domains.sorted { domain1, domain2 in
                let latestDate1 = cookieManager.cookiesByDomain[domain1]?.compactMap { $0.expiresDate }.max() ?? Date.distantPast
                let latestDate2 = cookieManager.cookiesByDomain[domain2]?.compactMap { $0.expiresDate }.max() ?? Date.distantPast
                return latestDate1 > latestDate2
            }
        }
    }
    
    private func deleteDomainCookies(_ domain: String) {
        cookieManager.deleteCookies(for: domain)
        if selectedDomain == domain {
            selectedDomain = nil
        }
    }
}

struct DomainRowView: View {
    let domain: String
    let cookieCount: Int
    let isSelected: Bool
    let onDelete: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(domain)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("\(cookieCount) \(cookieCount == 1 ? "cookie" : "cookies")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isHovered {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .contextMenu {
            Button("Clear Cookies", role: .destructive) {
                onDelete()
            }
        }
    }
}

struct CookieRowView: View {
    let cookie: CookieItem
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(cookie.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(cookie.domain + cookie.path)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    LabelValueRow(label: "Value", value: cookie.value.isEmpty ? "(empty)" : cookie.value)
                    LabelValueRow(label: "Domain", value: cookie.domain)
                    LabelValueRow(label: "Path", value: cookie.path)
                    
                    if let expiresDate = cookie.expiresDate {
                        LabelValueRow(label: "Expires", value: DateFormatter.localizedString(from: expiresDate, dateStyle: .medium, timeStyle: .short))
                    } else {
                        LabelValueRow(label: "Expires", value: "Session cookie")
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
        .contextMenu {
            Button("Copy Name") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(cookie.name, forType: .string)
            }
            
            Button("Copy Value") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(cookie.value, forType: .string)
            }
        }
    }
}

struct LabelValueRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
                .textSelection(.enabled)
            
            Spacer()
        }
    }
}
