import SwiftUI

struct BeforeAfterView: View {
    let original: UIImage
    let edited: UIImage

    @State private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // After (edited)
                Image(uiImage: edited)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()

                // Before (original) clipped to left side
                Image(uiImage: original)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .mask(
                        Rectangle()
                            .frame(width: splitX(in: geo), height: geo.size.height)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    )

                // Divider line
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2, height: geo.size.height)
                    .offset(x: splitX(in: geo) - 1)

                // Labels
                HStack {
                    Text("Trước").font(.picCaption).foregroundStyle(.white)
                        .padding(Spacing.xs)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Capsule())
                    Spacer()
                    Text("Sau").font(.picCaption).foregroundStyle(.white)
                        .padding(Spacing.xs)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Capsule())
                }
                .padding(Spacing.s)
            }
            .clipShape(RoundedRectangle(cornerRadius: Radius.l))
            .gesture(
                DragGesture()
                    .onChanged { value in dragOffset = value.translation.width }
                    .onEnded { _ in
                        withAnimation(Anim.spring) { dragOffset = 0 }
                    }
            )
        }
    }

    private func splitX(in geo: GeometryProxy) -> CGFloat {
        (geo.size.width / 2 + dragOffset).clamped(to: 20...(geo.size.width - 20))
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
