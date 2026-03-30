import SwiftUI

/// An editor that shows a list of string tags with add/remove functionality.
struct TagEditor: View {
    @Binding var items: [String]
    var placeholder: String = "追加..."
    var presets: [String] = []

    @State private var newItemText = ""
    @State private var isEditing = false
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Existing tags
            if !items.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(items, id: \.self) { item in
                        TagChip(text: item) {
                            items.removeAll(where: { $0 == item })
                        }
                    }
                }
            }

            // Add new
            HStack(spacing: 6) {
                TextField(placeholder, text: $newItemText)
                    .textFieldStyle(.roundedBorder)
                    .focused($inputFocused)
                    .onSubmit { commitNew() }
                    .frame(maxWidth: 300)

                Button {
                    commitNew()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
                .disabled(newItemText.trimmingCharacters(in: .whitespaces).isEmpty)

                // Preset picker
                if !presets.isEmpty {
                    Menu {
                        ForEach(presets, id: \.self) { preset in
                            Button(preset) {
                                if !items.contains(preset) {
                                    items.append(preset)
                                }
                            }
                        }
                    } label: {
                        Label("プリセット", systemImage: "chevron.down")
                            .font(.caption)
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                }
            }
        }
    }

    private func commitNew() {
        let trimmed = newItemText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !items.contains(trimmed) else { return }
        items.append(trimmed)
        newItemText = ""
    }
}

// MARK: - Tag Chip

struct TagChip: View {
    let text: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.system(size: 12))
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: 260)
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.accentColor.opacity(0.1))
                .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 0.5)
        )
    }
}

// MARK: - Flow Layout (wrapping HStack)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > containerWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return CGSize(width: maxX, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
    }
}

// MARK: - Key-Value Editor (for env vars)

struct KeyValueEditor: View {
    @Binding var pairs: [String: String]
    var keyPlaceholder: String = "KEY"
    var valuePlaceholder: String = "VALUE"

    @State private var newKey = ""
    @State private var newValue = ""

    var sortedKeys: [String] { pairs.keys.sorted() }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Existing pairs
            ForEach(sortedKeys, id: \.self) { key in
                HStack(spacing: 8) {
                    Text(key)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .frame(minWidth: 60, maxWidth: 150, alignment: .leading)

                    Text("=")
                        .foregroundStyle(.secondary)

                    TextField(valuePlaceholder, text: Binding(
                        get: { pairs[key] ?? "" },
                        set: { pairs[key] = $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(maxWidth: .infinity)

                    Button {
                        pairs.removeValue(forKey: key)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 4)

                if key != sortedKeys.last {
                    Divider()
                }
            }

            // Add new pair
            Divider().padding(.vertical, 4)

            HStack(spacing: 8) {
                TextField(keyPlaceholder, text: $newKey)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(minWidth: 60, maxWidth: 150)
                    .onSubmit { commitNew() }

                Text("=")
                    .foregroundStyle(.secondary)

                TextField(valuePlaceholder, text: $newValue)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))
                    .onSubmit { commitNew() }

                Button {
                    commitNew()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
                .disabled(newKey.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func commitNew() {
        let k = newKey.trimmingCharacters(in: .whitespaces)
        guard !k.isEmpty else { return }
        pairs[k] = newValue
        newKey = ""
        newValue = ""
    }
}
