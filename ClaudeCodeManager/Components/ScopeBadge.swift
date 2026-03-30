import SwiftUI

struct ScopeBadge: View {
    let selection: SidebarSelection

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(badgeColor)
                .frame(width: 8, height: 8)
            Text(badgeLabel)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(.background.secondary)
                .strokeBorder(badgeColor.opacity(0.4), lineWidth: 1)
        )
    }

    private var badgeColor: Color {
        switch selection {
        case .global: return .yellow
        case .project: return .green
        }
    }

    private var badgeLabel: String {
        switch selection {
        case .global: return "User"
        case .project: return "Project"
        }
    }
}

// MARK: - Scope level badge for individual settings

struct ScopeLevelBadge: View {
    enum Level {
        case managed, user, project, local

        var label: String {
            switch self {
            case .managed: return "Managed"
            case .user: return "User"
            case .project: return "Project"
            case .local: return "Local"
            }
        }

        var color: Color {
            switch self {
            case .managed: return .red
            case .user: return .yellow
            case .project: return .green
            case .local: return .blue
            }
        }
    }

    let level: Level

    var body: some View {
        Text(level.label)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(level.color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(level.color.opacity(0.12))
                    .strokeBorder(level.color.opacity(0.4), lineWidth: 0.5)
            )
    }
}
