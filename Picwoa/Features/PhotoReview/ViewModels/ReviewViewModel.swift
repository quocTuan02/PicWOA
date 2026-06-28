import SwiftUI
import Photos

@MainActor
@Observable
final class ReviewViewModel {

    let originalImage: UIImage
    let coaching: AICoachingResponse

    var editedImage: UIImage?
    var showSaveSuccess: Bool = false
    var saveError: String?

    private let processor = CoreImageProcessor()

    init(image: UIImage, coaching: AICoachingResponse) {
        self.originalImage = image
        self.coaching = coaching
    }

    func process() async {
        editedImage = await processor.apply(recipe: coaching.editingRecipe, to: originalImage)
    }

    func save() async {
        let imageToSave = editedImage ?? originalImage
        do {
            try await PHPhotoLibrary.shared().performChanges { @Sendable in
                PHAssetChangeRequest.creationRequestForAsset(from: imageToSave)
            }
            showSaveSuccess = true
        } catch {
            // Surface the failure (e.g. Photos permission denied) instead of silently dropping it.
            saveError = "Không thể lưu ảnh. Hãy kiểm tra quyền truy cập Ảnh trong Cài đặt."
        }
    }
}
