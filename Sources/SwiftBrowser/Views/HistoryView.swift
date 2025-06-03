import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct HistoryView: View {
    @State private var historyManager = HistoryManager.shared
    @State private var searchText = ""
    @State private var selectedTimeRange: TimeRange = .all
    @State private var selectedItems: Set<UUID> = []
    @State private var showingClearAlert = false
    @State private var showingExportDialog = false
    @State private var sortOption: SortOption = .newest
    
    enum TimeRange: String, CaseIterable {
        case today = "Today"
        case yesterday = "Yesterday"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case all = "All Time"
    }
    
    enum SortOption: String, CaseIterable {
        case newest = "Newest First"
        case oldest = "Oldest First"
        case alphabetical = "A-Z"
        case mostVisited = "Most Visited"
    }
    
    var filteredHistory: [HistoryItem] {
        let searchResults = historyManager.searchHistory(query: searchText)
        let timeFiltered = filterByTimeRange(searchResults)
        return sortHistory(timeFiltered)
    }
    
    var groupedHistory: [(String, [HistoryItem])] {
        let grouped = Dictionary(grouping: filteredHistory) { item in
            formatDateGroup(item.visitDate)
        }
        return grouped.sorted { (first: (key: String, value: [HistoryItem]), second: (key: String, value: [HistoryItem])) in
            let date1 = parseDateGroup(first.0)
            let date2 = parseDateGroup(second.0)
            return date1 > date2
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 16) {
                Text("Browsing History")
                    .font(UITheme.Typography.title)
                
                Text("View, search, and manage your browsing history")
                    .font(UITheme.Typography.body)
                    .foregroundColor(UITheme.Colors.secondary)
                
                // Controls
                HStack {
                    // Search
                    TextField("Search history...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 300)
                    
                    Spacer()
                    
                    // Time Range Filter
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)
                    
                    // Sort Options
                    Picker("Sort", selection: $sortOption) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 140)
                }
                
                // Action Buttons
                HStack {
                    if !selectedItems.isEmpty {
                        Button("Delete Selected (\(selectedItems.count))") {
                            deleteSelectedItems()
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                        
                        Button("Clear Selection") {
                            selectedItems.removeAll()
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                    
                    Button("Export History") {
                        showingExportDialog = true
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Clear All History") {
                        showingClearAlert = true
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
            }
            .padding()
            
            Divider()
            
            // History List
            if filteredHistory.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "clock")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No browsing history found")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    if !searchText.isEmpty {
                        Text("Try adjusting your search terms or time range")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.controlBackgroundColor))
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(groupedHistory, id: \.0) { dateGroup, items in
                            HistoryDateSection(
                                dateTitle: dateGroup,
                                items: items,
                                selectedItems: $selectedItems
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .alert("Clear All History", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                historyManager.clearHistory()
                selectedItems.removeAll()
            }
        } message: {
            Text("This will permanently delete all browsing history. This action cannot be undone.")
        }
        .fileExporter(
            isPresented: $showingExportDialog,
            document: HistoryExportDocument(history: filteredHistory),
            contentType: .json,
            defaultFilename: "browsing_history_\(Date().timeIntervalSince1970)"
        ) { result in
            // Handle export result if needed
        }
    }
    
    private func filterByTimeRange(_ items: [HistoryItem]) -> [HistoryItem] {
        let now = Date()
        let calendar = Calendar.current
        
        switch selectedTimeRange {
        case .today:
            return items.filter { calendar.isDateInToday($0.visitDate) }
        case .yesterday:
            return items.filter { calendar.isDateInYesterday($0.visitDate) }
        case .thisWeek:
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            return items.filter { $0.visitDate >= weekStart }
        case .thisMonth:
            let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
            return items.filter { $0.visitDate >= monthStart }
        case .all:
            return items
        }
    }
    
    private func sortHistory(_ items: [HistoryItem]) -> [HistoryItem] {
        switch sortOption {
        case .newest:
            return items.sorted { $0.visitDate > $1.visitDate }
        case .oldest:
            return items.sorted { $0.visitDate < $1.visitDate }
        case .alphabetical:
            return items.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .mostVisited:
            return items.sorted { $0.visitCount > $1.visitCount }
        }
    }
    
    private func formatDateGroup(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            return "This Week"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
    
    private func parseDateGroup(_ dateString: String) -> Date {
        if dateString == "Today" {
            return Date()
        } else if dateString == "Yesterday" {
            return Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        } else if dateString == "This Week" {
            return Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.date(from: dateString) ?? Date.distantPast
        }
    }
    
    private func deleteSelectedItems() {
        for itemId in selectedItems {
            HistoryManager.shared.removeHistoryItem(withId: itemId)
        }
        selectedItems.removeAll()
    }
}

struct HistoryDateSection: View {
    let dateTitle: String
    let items: [HistoryItem]
    @Binding var selectedItems: Set<UUID>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Date Header
            HStack {
                Text(dateTitle)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(items.count) \(items.count == 1 ? "item" : "items")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 4)
            
            // History Items
            ForEach(items, id: \.id) { item in
                HistoryItemRow(
                    item: item,
                    isSelected: selectedItems.contains(item.id),
                    onToggleSelection: {
                        if selectedItems.contains(item.id) {
                            selectedItems.remove(item.id)
                        } else {
                            selectedItems.insert(item.id)
                        }
                    }
                )
            }
        }
        .padding(.bottom, 16)
    }
}

struct HistoryItemRow: View {
    let item: HistoryItem
    let isSelected: Bool
    let onToggleSelection: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: onToggleSelection) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Favicon
            FaviconView(faviconData: item.faviconData, url: item.url)
                .frame(width: 16, height: 16)
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(item.url.absoluteString)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Visit info
            VStack(alignment: .trailing, spacing: 2) {
                Text(item.visitDate, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if item.visitCount > 1 {
                    Text("\(item.visitCount) visits")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.blue.opacity(0.1) : (isHovered ? Color(.controlBackgroundColor) : Color.clear))
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .contextMenu {
            Button("Copy URL") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(item.url.absoluteString, forType: .string)
            }
            
            Divider()
            
            Button("Delete", role: .destructive) {
                HistoryManager.shared.removeHistoryItem(withId: item.id)
            }
        }
    }
}

struct HistoryExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    let history: [HistoryItem]
    
    init(history: [HistoryItem]) {
        self.history = history
    }
    
    init(configuration: ReadConfiguration) throws {
        self.history = []
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let exportData = history.map { item in
            [
                "title": item.title,
                "url": item.url.absoluteString,
                "visitDate": ISO8601DateFormatter().string(from: item.visitDate),
                "visitCount": item.visitCount
            ]
        }
        
        let data = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
        return FileWrapper(regularFileWithContents: data)
    }
}
