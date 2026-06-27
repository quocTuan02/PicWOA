import SwiftUI

/// Top-left pose-suggestion card: a reference figure + the dáng to copy.
/// Collapsed = thumbnail + name; tap to expand for the full description and the AI's reason.
struct PoseSuggestionCard: View {
    let viewModel: PoseSuggestionViewModel

    var body: some View {
        if let suggestion = viewModel.currentSuggestion {
            content(for: suggestion)
                .frame(maxWidth: viewModel.isExpanded ? 260 : 132, alignment: .leading)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: Radius.l))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.l)
                        .strokeBorder(Color.picTextTertiary, lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.25), radius: 8, y: 2)
                .onTapGesture { withAnimation(Anim.normal) { viewModel.toggleExpanded() } }
                .animation(Anim.normal, value: viewModel.currentSuggestion)
        }
    }

    @ViewBuilder
    private func content(for suggestion: PoseSuggestion) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(alignment: .top, spacing: Spacing.s) {
                PoseReferenceImage(imageName: suggestion.imageName)
                    .frame(width: viewModel.isExpanded ? 80 : 52,
                           height: viewModel.isExpanded ? 116 : 76)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.m))

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Gợi ý dáng")
                        .font(.picCaption)
                        .foregroundStyle(Color.picTextSecondary)
                    Text(suggestion.displayName)
                        .font(.picHeadline)
                        .foregroundStyle(Color.picTextPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    if !viewModel.isExpanded {
                        Label("Xem", systemImage: "chevron.down")
                            .font(.picCaption)
                            .foregroundStyle(Color.picAccent)
                    }
                }
            }

            if viewModel.isExpanded {
                Text(suggestion.description)
                    .font(.picSubheadline)
                    .foregroundStyle(Color.picTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if let reason = viewModel.selectionReason {
                    Label(reason, systemImage: "sparkles")
                        .font(.picCaption)
                        .foregroundStyle(Color.picAccent)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(Spacing.s)
    }
}

/// Renders the reference asset; falls back to an SF Symbol figure when the asset is missing,
/// so the card stays meaningful even before the real images are added to the catalog.
private struct PoseReferenceImage: View {
    let imageName: String

    var body: some View {
        if UIImage(named: imageName) != nil {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            ZStack {
                Color.picSurfaceElevated
                Image(systemName: "figure.arms.open")
                    .font(.system(size: 30, weight: .regular))
                    .foregroundStyle(Color.picTextSecondary)
            }
        }
    }
}
