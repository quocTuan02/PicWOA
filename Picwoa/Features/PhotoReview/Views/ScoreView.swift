import SwiftUI

struct ScoreView: View {
    let score: Int

    var body: some View {
        VStack(spacing: Spacing.xs) {
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { index in
                    Image(systemName: index <= score ? "star.fill" : "star")
                        .foregroundStyle(index <= score ? Color.picAccent : Color.picTextTertiary)
                        .font(.title2)
                }
            }
            Text(scoreLabel)
                .font(.picSubheadline)
                .foregroundStyle(Color.picTextSecondary)
        }
    }

    private var scoreLabel: String {
        switch score {
        case 5: return "Hoàn hảo"
        case 4: return "Rất tốt"
        case 3: return "Khá tốt"
        case 2: return "Cần cải thiện"
        default: return "Thử lại"
        }
    }
}
