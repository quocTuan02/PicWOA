import SwiftUI

enum PermissionType {
    case camera
    case photos

    var title: String {
        switch self {
        case .camera: return "Cho phép truy cập Camera"
        case .photos: return "Cho phép truy cập Thư viện ảnh"
        }
    }

    var description: String {
        switch self {
        case .camera: return "Picwoa cần camera để huấn luyện tư thế chụp ảnh cho bạn."
        case .photos: return "Picwoa cần lưu ảnh vào thư viện của bạn."
        }
    }

    var systemImage: String {
        switch self {
        case .camera: return "camera.fill"
        case .photos: return "photo.fill"
        }
    }
}

struct PermissionView: View {
    let type: PermissionType
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: Spacing.l) {
            Image(systemName: type.systemImage)
                .font(.system(size: 64))
                .foregroundStyle(Color.picAccent)

            Text(type.title)
                .font(.picTitle2)
                .foregroundStyle(Color.picTextPrimary)
                .multilineTextAlignment(.center)

            Text(type.description)
                .font(.picBody)
                .foregroundStyle(Color.picTextSecondary)
                .multilineTextAlignment(.center)

            PrimaryButton(title: "Mở Cài đặt", action: onOpenSettings)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.picBackground)
    }
}
