import SwiftUI

struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(Spacing.m)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Radius.l))
    }
}
