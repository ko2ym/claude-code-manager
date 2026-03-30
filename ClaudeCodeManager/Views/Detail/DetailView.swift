import SwiftUI

struct DetailView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        VStack(spacing: 0) {
            // Tab bar
            TabBarView(selectedTab: $appState.selectedTab, scopeSelection: appState.sidebarSelection)

            Divider()

            // Content
            Group {
                switch appState.selectedTab {
                case .settings:
                    SettingsView()
                case .mcp:
                    MCPView()
                case .mdFiles:
                    MDFilesView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Tab Bar

struct TabBarView: View {
    @Binding var selectedTab: AppTab
    let scopeSelection: SidebarSelection

    var body: some View {
        HStack(spacing: 2) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                TabBarButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    action: { selectedTab = tab }
                )
            }

            Spacer()

            ScopeBadge(selection: scopeSelection)
                .padding(.trailing, 16)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct TabBarButton: View {
    let tab: AppTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: tab.icon)
                    .font(.system(size: 13))
                Text(tab.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
            }
            .foregroundStyle(isSelected ? .primary : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color(NSColor.selectedContentBackgroundColor).opacity(0.15) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}
