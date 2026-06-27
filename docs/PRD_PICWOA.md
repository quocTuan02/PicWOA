# PRD — Picwoa: AI Photography Coach

**Version:** 1.0  
**Platform:** iOS (iPhone)  
**Language:** Swift 6 / SwiftUI  
**App UI Language:** Tiếng Việt  
**Status:** MVP — Hackathon Edition  

---

## 1. Product Overview

### Product Summary

Picwoa là ứng dụng iOS giúp bất kỳ ai chụp được ảnh đẹp mà không cần kỹ năng nhiếp ảnh. Ứng dụng hoạt động như một nhiếp ảnh gia AI đứng cạnh người dùng — hướng dẫn tư thế, bố cục, và thời điểm chụp theo thời gian thực.

### Problem Statement

Hầu hết mọi người:
- Không biết tư thế cơ thể phù hợp
- Không biết đứng ở đâu, hướng nào
- Không hiểu bố cục khung hình
- Không biết khi nào nên bấm chụp

Kết quả: chụp nhiều ảnh nhưng giữ lại rất ít.

### Target Audience

**Primary:**
- Khách du lịch
- Các cặp đôi
- Gia đình
- Content creator cá nhân

**Secondary:**
- Doanh nghiệp nhỏ cần ảnh sản phẩm
- Nhiếp ảnh gia sự kiện dạng casual

### Value Proposition

Picwoa giúp người dùng cải thiện ảnh **trước khi chụp**, không phải sau. Thay vì chỉnh sửa lỗi, Picwoa ngăn lỗi xảy ra.

### Business Goals

- MVP: Demo ấn tượng tại hackathon trong 4 giờ
- V1: Sản phẩm có thể release lên App Store
- V2: Nền tảng AI Photographer đầy đủ

### Success Metrics

| Metric | Target |
|--------|--------|
| Camera startup | < 2 giây |
| AI response | < 1 giây |
| Overlay latency | < 100ms |
| Camera preview | ≥ 30 FPS |
| Crash-free sessions | > 99.5% |

---

## 2. Product Principles

1. **Coach Before Capture** — Cải thiện ảnh trước khi bấm chụp
2. **Real-time Experience** — Gợi ý xuất hiện ngay khi camera mở, không có độ trễ
3. **AI Assists, Never Overwhelms** — Chỉ hiển thị 1 gợi ý chính + 1 gợi ý phụ tùy chọn
4. **Apple Native First** — Vision, CoreML, CoreImage, AVFoundation trước; Cloud AI chỉ khi cần
5. **Privacy First** — Ảnh gốc không bao giờ rời thiết bị; chỉ metadata cấu trúc gửi lên cloud
6. **Minimal UI** — UI phục vụ camera, không cạnh tranh với nó
7. **One Primary Action** — Mỗi màn hình chỉ có một hành động chính rõ ràng

---

## 3. User Personas

### Persona A — Minh (Du khách)

- **Background:** 28 tuổi, đi du lịch thường xuyên, chụp ảnh bằng iPhone
- **Goals:** Có ảnh đẹp tại điểm du lịch, không cần nhờ người khác
- **Pain Points:** Ảnh bị nghiêng, thiếu ánh sáng, tư thế awkward
- **Motivation:** Chia sẻ ảnh đẹp lên mạng xã hội
- **Tech Experience:** Dùng smartphone thành thạo, không biết nhiếp ảnh

### Persona B — Linh (Cặp đôi)

- **Background:** 25 tuổi, chụp ảnh cùng bạn trai nhưng chất lượng không đồng đều
- **Goals:** Có ảnh đôi chuyên nghiệp mà không cần thuê photographer
- **Pain Points:** Không ai hướng dẫn tư thế, không biết khung hình đẹp
- **Motivation:** Kỷ niệm quan trọng xứng đáng có ảnh đẹp

---

## 4. User Journey

### Journey: Chụp ảnh cùng AI Coach

| Bước | Trigger | User Action | System Response | Outcome |
|------|---------|-------------|-----------------|---------|
| 1 | Mở app | Tap icon | Camera mở ngay, không splash screen | Preview hiển thị ≤ 2s |
| 2 | Vào frame | Người dùng bước vào | Vision phát hiện người | Overlay hiển thị skeleton |
| 3 | Nhận coaching | Nhìn overlay | Rule Engine phân tích tư thế | Hiển thị 1 gợi ý: "↑ Ngẩng đầu lên" |
| 4 | Điều chỉnh | Sửa tư thế | Vision cập nhật real-time | Cue thay đổi theo vấn đề quan trọng nhất |
| 5 | Sẵn sàng | Tư thế đúng | AI xác nhận: "Hoàn hảo. Chụp ngay!" | Capture button sáng lên |
| 6 | Chụp | Tap Capture | AVFoundation chụp ảnh | Chuyển sang màn kết quả |
| 7 | Xem kết quả | — | Core Image recipe được áp dụng | Hiển thị ảnh đã tinh chỉnh |
| 8 | Lưu | Tap Lưu | Ghi vào Photo Library | Thông báo thành công |

---

## 5. Functional Requirements

### Feature 1 — Camera Experience

| | |
|-|-|
| **Description** | Preview camera real-time full-screen |
| **Input** | Camera permission granted |
| **Output** | Live preview 30 FPS |
| **Business Rules** | Request permission nếu chưa có. Back camera mặc định. Hỗ trợ portrait mode |
| **Edge Cases** | Permission denied → màn hình hướng dẫn. Camera unavailable → thông báo lỗi |
| **Acceptance Criteria** | Camera mở trong ≤ 2s. Preview ổn định ≥ 30 FPS. Capture button luôn visible |
| **Priority** | MVP |

### Feature 2 — Person Detection

| | |
|-|-|
| **Description** | Phát hiện có người trong frame chưa |
| **Input** | CMSampleBuffer từ camera |
| **Output** | `Bool: personDetected` |
| **Business Rules** | Dùng VNDetectHumanBodyPoseRequest. Nếu không có người → hiển thị "Bước vào khung hình" |
| **Edge Cases** | Nhiều người → chọn người gần nhất / trung tâm nhất |
| **Acceptance Criteria** | Phát hiện người trong ≤ 100ms. Không false positive với đồ vật |
| **Priority** | MVP |

### Feature 3 — Pose Detection

| | |
|-|-|
| **Description** | Ước tính landmark cơ thể |
| **Input** | CMSampleBuffer |
| **Output** | `PoseObservation`: { head, neck, leftShoulder, rightShoulder, hip, leftKnee, rightKnee, leftFoot, rightFoot } |
| **Business Rules** | Dùng VNDetectHumanBodyPoseRequest. Min confidence: 0.5 |
| **Edge Cases** | Landmark bị che → bỏ qua rule liên quan đến landmark đó |
| **Acceptance Criteria** | Update ≥ 15 FPS. Confidence score đi kèm mỗi landmark |
| **Priority** | MVP |

### Feature 4 — Scene Detection

| | |
|-|-|
| **Description** | Phân loại cảnh quay |
| **Input** | Frame camera |
| **Output** | `Scene: indoor | outdoor` |
| **Business Rules** | MVP: chỉ indoor/outdoor. Dùng CoreML hoặc heuristic đơn giản (brightness, histogram) |
| **Edge Cases** | Không phân loại được → default `outdoor` |
| **Acceptance Criteria** | Accuracy ≥ 80% trên test cases cơ bản |
| **Priority** | MVP |

### Feature 5 — Rule Engine

| | |
|-|-|
| **Description** | Phân tích tư thế bằng logic deterministic, không cần AI |
| **Input** | PoseObservation + Scene |
| **Output** | `[CoachingRule]`: danh sách vấn đề phát hiện được |
| **Business Rules** | Xử lý các rule theo bảng dưới |
| **Edge Cases** | Không có vấn đề → emit `ReadyToCapture` signal |
| **Acceptance Criteria** | Rule evaluation < 10ms. Ưu tiên rule quan trọng nhất lên đầu |
| **Priority** | MVP |

**Rule Table:**

| Điều kiện | Gợi ý |
|-----------|-------|
| Cằm thấp hơn vai quá nhiều | "Ngẩng đầu lên" |
| Vai trái thấp hơn vai phải | "Nhấc vai trái lên" |
| Vai phải thấp hơn vai trái | "Nhấc vai phải lên" |
| Cơ thể quay thẳng vào camera | "Xoay người 15°" |
| Người lệch khỏi trung tâm frame | "Dịch sang [trái/phải] một chút" |
| Đứng quá xa camera | "Bước lại gần hơn" |
| Đứng quá gần camera | "Lùi ra xa hơn" |
| Không phát hiện được người | "Bước vào khung hình" |

### Feature 6 — AI Coaching

| | |
|-|-|
| **Description** | Gửi metadata lên OpenAI, nhận coaching + editing recipe |
| **Input** | Structured JSON: scene + pose + issues |
| **Output** | `AICoachingResponse`: main_cue, secondary_cue, camera_instruction, editing_recipe |
| **Business Rules** | KHÔNG upload ảnh. Chỉ gửi metadata. Throttle: tối đa 1 request / 3 giây. Mock mode khi không có API key |
| **Edge Cases** | API timeout → dùng Rule Engine response. API error → fallback to last valid response |
| **Acceptance Criteria** | Response < 1 giây. Fallback hoạt động khi offline |
| **Priority** | MVP |

**AI Input Schema:**
```json
{
  "scene": "outdoor",
  "pose": "standing",
  "issues": ["chin_down", "left_shoulder_low"],
  "frame_position": "center"
}
```

**AI Output Schema:**
```json
{
  "main_cue": "Xoay người 15° sang phải",
  "secondary_cue": "Ngẩng đầu lên",
  "camera_instruction": "Lùi camera ra một chút",
  "editing_recipe": {
    "exposure": 0.1,
    "contrast": 10,
    "highlights": -15,
    "shadows": 20,
    "temperature": 4,
    "vibrance": 15
  }
}
```

### Feature 7 — Live Overlay

| | |
|-|-|
| **Description** | Hiển thị coaching cue lên camera preview |
| **Input** | `AICoachingResponse` hoặc `[CoachingRule]` từ Rule Engine |
| **Output** | SwiftUI overlay: arrow + text |
| **Business Rules** | Chỉ hiển thị 1 gợi ý chính. Arrow chỉ hướng cần điều chỉnh. Update khi có input mới |
| **Edge Cases** | Không có gợi ý → ẩn overlay |
| **Acceptance Criteria** | Overlay update < 100ms. Không che capture button |
| **Priority** | MVP |

### Feature 8 — Photo Capture

| | |
|-|-|
| **Description** | Chụp ảnh full resolution |
| **Input** | User tap Capture button |
| **Output** | `UIImage` |
| **Business Rules** | Dùng AVCapturePhotoOutput. Chụp ảnh tĩnh, không video |
| **Edge Cases** | Capture thất bại → thông báo lỗi, cho thử lại |
| **Acceptance Criteria** | Capture latency < 500ms. Ảnh full resolution |
| **Priority** | MVP |

### Feature 9 — Post-Capture Result

| | |
|-|-|
| **Description** | Hiển thị ảnh vừa chụp sau khi áp dụng chỉnh màu tự động |
| **Input** | `UIImage` + `AICoachingResponse` |
| **Output** | Result screen với ảnh đã tinh chỉnh + hành động Lưu/Chụp lại |
| **Business Rules** | Không chấm điểm ảnh như workflow chính. Mọi gợi ý cải thiện phải xuất hiện trước capture trong Live Overlay |
| **Edge Cases** | Không có AI response → hiển thị ảnh gốc hoặc default editing recipe |
| **Acceptance Criteria** | Result screen xuất hiện ≤ 1 giây sau capture |
| **Priority** | MVP |

### Feature 10 — Auto Editing

| | |
|-|-|
| **Description** | Áp dụng editing recipe từ AI lên ảnh bằng Core Image |
| **Input** | `UIImage` + `editing_recipe` |
| **Output** | `UIImage` đã chỉnh sửa |
| **Business Rules** | Dùng CIFilter. Áp dụng: exposure, contrast, highlights, shadows, temperature, vibrance. Không dùng preset filter |
| **Edge Cases** | Recipe null/empty → hiển thị ảnh gốc |
| **Acceptance Criteria** | Processing < 500ms. Ảnh kết quả hiển thị rõ ràng |
| **Priority** | MVP |

### Feature 11 — Save Photo

| | |
|-|-|
| **Description** | Lưu ảnh đã edit vào Photos Library |
| **Input** | `UIImage` đã edit |
| **Output** | Ảnh trong Photos app |
| **Business Rules** | Request Photos permission nếu chưa có. Lưu ảnh đã edit, không phải ảnh gốc |
| **Edge Cases** | Permission denied → hướng dẫn vào Settings |
| **Acceptance Criteria** | Save thành công + hiển thị confirmation |
| **Priority** | MVP |

---

## 6. Non-functional Requirements

### Performance

| | |
|-|-|
| Cold launch | < 2 giây |
| Camera preview | ≥ 30 FPS |
| Pose detection | ≥ 15 FPS |
| AI response | < 1 giây |
| Overlay update | < 100ms |
| Capture latency | < 500ms |
| Photo editing | < 500ms |

### Privacy & Security

- Không upload ảnh gốc lên bất kỳ server nào
- Chỉ gửi structured metadata (text/JSON) lên OpenAI
- API key không hardcode trong source code — dùng environment variable hoặc config file excluded from git
- Không log dữ liệu nhạy cảm

### Battery & Memory

- Vision inference trên main session để tránh overhead
- Throttle AI calls: tối đa 1 request / 3 giây
- Core Image xử lý trên background thread
- Memory budget: < 200MB RAM khi chạy camera

### Reliability

- Crash-free sessions > 99.5%
- Graceful fallback khi AI unavailable
- App không block khi waiting for AI response

### Offline Behaviour

- Rule Engine hoạt động 100% offline
- Overlay hoạt động offline (dùng Rule Engine thay AI)
- AI features degrade gracefully khi mất mạng

---

## 7. MVP Scope

### Included

- Camera Preview (30 FPS)
- Person Detection
- Pose Detection (7 landmarks)
- Scene Detection (indoor/outdoor)
- Rule Engine (deterministic coaching)
- AI Coaching via OpenAI (text metadata only)
- Live Overlay (1 gợi ý chính)
- Ready-to-Capture Cue
- Photo Capture
- Post-Capture Result
- Auto Editing (Core Image)
- Save to Photos Library
- Mock Mode (khi không có API key)

### Not Included

- User Authentication
- Cloud Storage / Sync
- Photo History / Favorites
- Pose Library
- Analytics Dashboard
- Social Sharing
- Premium Subscription
- Multi-language
- SwiftData persistence
- Firebase / Supabase

### Stretch Goals (nếu còn thời gian)

- Scene sub-classification (cafe, beach, street)
- Auto Capture (chụp tự động khi tư thế đạt chuẩn)
- Haptic feedback khi coaching cue thay đổi
- Before/After Comparison
- Score animation

---

## 8. Future Roadmap

### MVP (Hackathon)

Camera + Vision + Rule Engine + AI Coaching + Overlay + Ready-to-Capture Cue + Capture + Core Image Recipe + Save

### V1

- Scene classification nâng cao (10+ categories)
- Pose templates (Portrait, Full Body, Group)
- Composition scoring real-time
- Auto Capture
- Offline CoreML model thay OpenAI

### V2

- Multi-person coaching
- Couple & Family modes
- Voice coaching (Vietnamese TTS)
- Personalized AI Coach (học từ lịch sử ảnh)
- Community Pose Library
- Fine-tuned on-device ML

---

## 9. Design Philosophy

### Design Language

- **Native iOS** — tuân thủ Apple HIG
- **Photography First** — camera là trung tâm, UI phục vụ camera
- **Dark First** — dark background tôn ảnh, giảm distraction
- **Minimal** — chỉ hiển thị những gì người dùng cần ngay lúc đó
- **Premium** — cảm giác tool nghề nghiệp, không phải toy app

### Visual Style

- Dark mode mặc định
- Background: `#000000` hoặc `#0A0A0A`
- Accent: trắng tinh `#FFFFFF` hoặc vàng ấm `#FFD60A`
- Glassmorphism nhẹ cho overlay cards
- Không dùng màu sắc loè loẹt

### Apple HIG Compliance

- Minimum touch target: 44×44pt
- Safe area insets respected
- Dynamic Type supported
- VoiceOver labels trên tất cả interactive elements

---

## 10. Design Tokens

### Colors

```swift
// Background
colorBackground     = #000000
colorSurface        = #1C1C1E
colorSurfaceElevated = #2C2C2E

// Accent
colorAccent         = #FFD60A  // vàng nhiếp ảnh
colorAccentSecondary = #FFFFFF

// Text
colorTextPrimary    = #FFFFFF
colorTextSecondary  = #EBEBF5 // opacity 60%
colorTextTertiary   = #EBEBF5 // opacity 30%

// Semantic
colorSuccess        = #30D158
colorWarning        = #FFD60A
colorError          = #FF453A
colorOverlay        = #000000 // opacity 40%
```

### Typography

```swift
fontLargeTitle   = SF Pro Display, Bold, 34pt
fontTitle        = SF Pro Display, Semibold, 28pt
fontTitle2       = SF Pro Display, Semibold, 22pt
fontHeadline     = SF Pro Text, Semibold, 17pt
fontBody         = SF Pro Text, Regular, 17pt
fontCallout      = SF Pro Text, Regular, 16pt
fontSubheadline  = SF Pro Text, Regular, 15pt
fontCaption      = SF Pro Text, Regular, 12pt
fontCoaching     = SF Pro Display, Bold, 20pt   // overlay cues
```

### Spacing

```swift
spacingXS  = 4pt
spacingS   = 8pt
spacingM   = 16pt
spacingL   = 24pt
spacingXL  = 32pt
spacingXXL = 48pt
```

### Corner Radius

```swift
radiusS  = 8pt
radiusM  = 12pt
radiusL  = 16pt
radiusXL = 24pt
radiusFull = 9999pt  // pill shape
```

### Animation

```swift
durationFast     = 0.15s
durationNormal   = 0.25s
durationSlow     = 0.4s
curveEaseOut     = .easeOut
curveSpring      = .spring(response: 0.3, dampingFraction: 0.7)
```

---

## 11. Design System — Components

### CaptureButton

- **Purpose:** Kích hoạt chụp ảnh
- **States:** Default / Pressed / Disabled / ReadyToCapture (pulse)
- **Size:** 72×72pt circle
- **Variants:** White outer ring, dark fill

### CoachingCard

- **Purpose:** Hiển thị 1 gợi ý coaching
- **Properties:** icon (arrow direction), text (coaching cue), priority
- **States:** Visible / Hidden / Success (green)
- **Style:** Glass card, bottom of screen

### SkeletonOverlay

- **Purpose:** Hiển thị body landmark detection
- **Properties:** PoseObservation data
- **States:** Detecting / Detected / Lost
- **Style:** Subtle white lines, opacity 40%

### BeforeAfterView

- **Purpose:** So sánh ảnh gốc và ảnh đã edit
- **Properties:** original: UIImage, edited: UIImage
- **Interaction:** Swipe hoặc drag để compare
- **Priority:** Stretch goal, không bắt buộc cho MVP

### PermissionView

- **Purpose:** Yêu cầu camera/photos permission
- **States:** Camera, Photos
- **Action:** CTA button → Settings

---

## 12. Screen Specifications

### Screen 1 — Camera Screen (Main)

**Purpose:** Màn hình chính, hiển thị camera + coaching real-time

**Layout (top → bottom):**
```
[Status Bar]
[Camera Preview — full screen]
  [SkeletonOverlay — trên preview]
  [CoachingCard — bottom overlay, 16pt from bottom toolbar]
[Bottom Toolbar]
  [Thumbnail] [CaptureButton] [FlashToggle]
```

**User Actions:**
- Tap CaptureButton → chụp ảnh
- Tap FlashToggle → bật/tắt đèn flash

**States:**
- `NoPerson` — CoachingCard: "Bước vào khung hình"
- `Detecting` — Skeleton loading
- `Coaching` — CoachingCard hiển thị gợi ý
- `ReadyToCapture` — CoachingCard: "Hoàn hảo! Chụp ngay" + CaptureButton pulse
- `Capturing` — màn hình flash trắng

**Error States:**
- Camera permission denied → PermissionView
- Camera unavailable → Error message

---

### Screen 2 — Result Screen

**Purpose:** Hiển thị kết quả sau chụp

**Layout:**
```
[Navigation Bar: "Kết quả" + Nút X đóng]
[Edited Image — top]
[Status Text — "Đã tinh chỉnh ánh sáng"]
[Nút: Lưu ảnh]   [Nút: Chụp lại]
```

**User Actions:**
- Lưu ảnh → save to Photos + dismiss
- Chụp lại → dismiss về Camera Screen

---

### Screen 3 — Permission Screen

**Purpose:** Yêu cầu permission cần thiết

**Layout:**
```
[Icon camera lớn]
[Title: "Cho phép truy cập Camera"]
[Description: lý do ngắn gọn]
[CTA Button: "Mở Cài đặt"]
```

---

## 13. Navigation Flow

```
App Launch
    │
    ▼
Permission Check
    │
    ├─ Denied ──► PermissionView
    │
    └─ Granted
        │
        ▼
    CameraScreen (main)
        │
        └─ Capture ──► ResultScreen (modal sheet)
                          │
                          ├─ Save ──► CameraScreen
                          └─ Retake ──► CameraScreen
```

- **NavigationStack** không dùng ở màn camera (full-screen experience)
- ResultScreen: `.sheet` presentation, `.large` detent
- Không có tab bar trong MVP

---

## 14. AI Responsibilities Matrix

| Feature | Deterministic | Rule Engine | Vision | CoreML | Cloud AI |
|---------|--------------|-------------|--------|--------|----------|
| Person Detection | — | — | ✓ | — | — |
| Pose Detection | — | — | ✓ | — | — |
| Scene Detection | — | — | — | ✓ | — |
| Pose Analysis | — | ✓ | — | — | — |
| Coaching Text | — | Fallback | — | — | ✓ |
| Editing Recipe | — | — | — | — | ✓ |
| Readiness Signal | ✓ | ✓ | — | — | — |
| Auto Editing | ✓ (CoreImage) | — | — | — | — |

---

## 15. AI Input/Output Spec

### Request

```json
{
  "scene": "outdoor | indoor",
  "pose": "standing | sitting | crouching",
  "issues": ["chin_down", "left_shoulder_low", "torso_facing_camera"],
  "frame_position": "center | left | right | top | bottom",
  "person_count": 1
}
```

### Response

```json
{
  "main_cue": "string (tiếng Việt, ≤ 40 ký tự)",
  "secondary_cue": "string (tiếng Việt, ≤ 40 ký tự) | null",
  "camera_instruction": "string (tiếng Việt) | null",
  "readiness": "not_ready | improving | ready",
  "editing_recipe": {
    "exposure": -1.0 to 1.0,
    "contrast": -100 to 100,
    "highlights": -100 to 100,
    "shadows": -100 to 100,
    "temperature": -100 to 100,
    "vibrance": -100 to 100
  }
}
```

### Validation Rules

- `main_cue` bắt buộc, không được null
- `editing_recipe` tất cả fields bắt buộc
- `readiness` bắt buộc; khi `ready`, `main_cue` phải là lời nhắc chụp ngay
- Tất cả text fields phải bằng tiếng Việt

### Fallback Behavior

- API timeout (>2s) → dùng Rule Engine coaching + default editing recipe
- API error → last valid response cached
- No network → offline mode với Rule Engine only

---

## 16. Performance Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| Cold Launch → Camera Ready | < 2s | Instruments |
| Camera FPS | ≥ 30 FPS | AVFoundation metrics |
| Pose Detection FPS | ≥ 15 FPS | Vision profiling |
| Rule Engine evaluation | < 10ms | XCTest |
| AI API response | < 1s | URLSession timing |
| Overlay update | < 100ms | Frame timing |
| Photo capture latency | < 500ms | Instruments |
| Core Image processing | < 500ms | Instruments |
| RAM usage | < 200MB | Instruments |

---

## 17. Accessibility

| | |
|-|-|
| Dynamic Type | Coaching text scale theo font size setting |
| VoiceOver | Tất cả buttons có accessibilityLabel tiếng Việt |
| Color Contrast | WCAG AA minimum (4.5:1) cho text trên overlay |
| Touch Target | Minimum 44×44pt |
| Reduce Motion | Tắt pulse animation khi Reduce Motion enabled |
| Haptic Feedback | UIImpactFeedbackGenerator khi coaching cue thay đổi |

---

## 18. Analytics Events (V1 — không làm trong MVP)

| Event | Trigger | Parameters |
|-------|---------|------------|
| `session_started` | App launch | device_model, os_version |
| `person_detected` | First detection | confidence |
| `coaching_shown` | Overlay update | cue_type, rule_triggered |
| `capture_tapped` | Capture button tap | — |
| `photo_saved` | Save success | editing_applied |
| `ai_request_sent` | AI call | — |
| `ai_response_received` | AI response | latency_ms |

---

## 19. Acceptance Criteria

### Camera

```
Given: App installed, camera permission granted
When: User opens app
Then: Camera preview starts ≤ 2s, ≥ 30 FPS, no crash
```

### Person Detection

```
Given: Camera running
When: User enters frame
Then: System detects person ≤ 100ms, overlay appears
```

### Coaching Flow

```
Given: Person detected in frame
When: Pose has issues (e.g. chin down)
Then: Overlay shows correct Vietnamese coaching cue ≤ 100ms
```

### AI Coaching

```
Given: Rule Engine detects issues
When: AI call triggered
Then: Response received ≤ 1s, cue updated, editing_recipe non-null
```

### Capture + Edit

```
Given: User taps Capture
When: Capture succeeds
Then: Result screen shows in ≤ 1s, Core Image recipe applied, edited image visible
```

### Save

```
Given: User on Result screen
When: User taps "Lưu ảnh"
Then: Edited photo saved to Photos Library, confirmation shown
```

---

## 20. Risks

### Technical Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Vision accuracy thấp trên thiết bị cũ | High | Test trên iPhone 11+, set min confidence threshold |
| AI API latency > 1s | Medium | Fallback to Rule Engine, response caching |
| CoreImage processing chậm | Low | Background thread, progressive loading |
| Camera permission UX | Medium | Clear permission screen, Settings deeplink |

### UX Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Coaching cue quá nhiều → overwhelm | High | Strict 1 cue max rule |
| Overlay che camera view | Medium | Transparent glass, bottom-only placement |
| User bỏ qua cue và chụp quá sớm | Medium | Ready state rõ ràng, capture button pulse khi đạt chuẩn |

### AI Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Coaching text không tự nhiên | Medium | Prompt engineering rõ ràng, test nhiều cases |
| Editing recipe không phù hợp cảnh | Low | Clamp values, allow retake/save original fallback |

### Project Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| 4 giờ không đủ | High | Mock mode sẵn, pipeline rõ ràng |
| Integration conflict giữa 3 devs | Medium | Interface contracts rõ ràng trước khi code |

---

## 21. KPIs

| KPI | Target | Ghi chú |
|-----|--------|---------|
| Demo chạy không crash | 100% | 12 steps trong demo script |
| Camera startup | < 2s | Đo trên iPhone thật |
| AI response | < 1s | Bao gồm network |
| Coaching cue accuracy | Subjective | Review bởi team |
| Overlay latency | < 100ms | Visual check |
| Ready-to-capture cue | Visible | Manual QA |

---

*PRD này là single source of truth. Mọi quyết định architecture, module, và implementation phải align với document này.*
