import SwiftUI

struct ReviewScreen: View {
    let originalImage: UIImage
    let coaching: AICoachingResponse

    @State private var viewModel: ReviewViewModel
    @Environment(\.dismiss) private var dismiss

    init(originalImage: UIImage, coaching: AICoachingResponse) {
        self.originalImage = originalImage
        self.coaching = coaching
        _viewModel = State(initialValue: ReviewViewModel(image: originalImage, coaching: coaching))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.l) {
                    BeforeAfterView(
                        original: originalImage,
                        edited: viewModel.editedImage ?? originalImage
                    )
                    .frame(height: 320)

                    ScoreView(score: coaching.score)

                    VStack(alignment: .leading, spacing: Spacing.s) {
                        Text(coaching.feedback)
                            .font(.picBody)
                            .foregroundStyle(Color.picTextPrimary)

                        if let tip = coaching.secondaryCue {
                            Text("Lần sau: \(tip)")
                                .font(.picSubheadline)
                                .foregroundStyle(Color.picTextSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Spacing.m)

                    VStack(spacing: Spacing.s) {
                        PrimaryButton(title: "Lưu ảnh") {
                            Task { await viewModel.save() }
                        }
                        Button("Chụp lại") { dismiss() }
                            .font(.picBody)
                            .foregroundStyle(Color.picTextSecondary)
                    }
                    .padding(.horizontal, Spacing.m)
                }
                .padding(.vertical, Spacing.l)
            }
            .navigationTitle("Kết quả")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") { dismiss() }
                }
            }
            .background(Color.picBackground)
            .alert("Đã lưu ảnh!", isPresented: $viewModel.showSaveSuccess) {
                Button("OK") { dismiss() }
            }
        }
        .task { await viewModel.process() }
    }
}
