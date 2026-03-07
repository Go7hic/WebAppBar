import SwiftUI

struct SiteIconPicker: View {
    @Binding var selected: String

    private let suggestions: [String] = [
        "globe", "star.fill", "heart.fill", "bookmark.fill",
        "play.circle.fill", "play.rectangle.fill", "film.fill",
        "music.note", "headphones", "gamecontroller.fill",
        "newspaper.fill", "text.bubble.fill", "message.fill",
        "at", "link", "network",
        "brain.head.profile", "lightbulb.fill", "graduationcap.fill",
        "cart.fill", "bag.fill", "creditcard.fill",
        "camera.fill", "photo.fill", "doc.fill",
        "chevron.left.forwardslash.chevron.right", "terminal.fill",
        "cpu.fill", "cloud.fill", "envelope.fill",
        "person.fill", "person.2.fill", "house.fill",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Choose icon")
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.fixed(32), spacing: 6), count: 8), spacing: 6) {
                ForEach(suggestions, id: \.self) { symbol in
                    Button(action: { selected = symbol }) {
                        Image(systemName: symbol)
                            .font(.system(size: 14))
                            .frame(width: 32, height: 32)
                            .background(selected == symbol ? Color.accentColor.opacity(0.2) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(selected == symbol ? Color.accentColor : Color.clear, lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.borderless)
                    .help(symbol)
                }
            }

            HStack(spacing: 6) {
                Text("Custom:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("SF Symbol name", text: $selected)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
                if !selected.isEmpty {
                    Image(systemName: selected)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                }
            }
        }
    }
}
