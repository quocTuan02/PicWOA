# BUILD EXECUTION PLAN — Picwoa MVP

**Version:** 1.0  
**Context:** Hackathon — 4 giờ, 3 developers + AI agents  
**Goal:** Working demo: Camera → Live AI Coaching → Ready Cue → Capture → Auto Enhance → Save  

---

## 1. Overall Build Strategy

### Implementation Philosophy

Build một vertical demo flow hoàn chỉnh trước, rồi mới polish. Nếu phải chọn giữa *feature đầy đủ* và *demo chạy được* — chọn demo chạy được.

**Priority order:**
1. Camera mở được
2. Overlay hiển thị coaching cue (dù từ Rule Engine hay Mock AI)
3. Ready-to-capture cue xuất hiện đúng lúc
4. Capture + Result + Save chạy được
5. AI thật thay thế Mock AI
6. Polish UI

### Parallelization Strategy

Ba streams chạy độc lập trong 2 giờ đầu, hội tụ tại checkpoint 02:30:

```
00:00 ──────────────────────────────────── 04:00
  │
  ├─ Dev A ─[Setup+Camera]──[Capture]──[Integration]──[Polish]
  │
  ├─ Dev B ─[Vision]────────[RuleEngine]──[Integration]──[Polish]
  │
  └─ Dev C ─[OpenAI+Mock]──[Overlay+Result]──[Integration]──[Polish]
                                        ▲
                                   02:30 merge
```

### Integration Frequency

- Micro-integrations: mỗi 30 phút pull từ main để tránh drift
- Hard checkpoint: 01:30 — tất cả commit interface contracts
- Hard checkpoint: 02:30 — full integration merge
- Hard checkpoint: 03:15 — demo flow hoàn chỉnh

### Release Milestones

| Milestone | Time | Description |
|-----------|------|-------------|
| M1 — Project Live | 00:30 | Xcode build, camera permission, shared models committed |
| M2 — Camera + Vision | 01:30 | Preview 30 FPS + Pose data streaming |
| M3 — AI Pipe Ready | 02:00 | Mock AI → Overlay visible on camera screen |
| M4 — Full MVP | 02:30 | Ready Cue → Capture → Result → Save |
| M5 — Demo Ready | 03:15 | End-to-end flow không crash, UI polished |
| M6 — Rehearsal | 03:30 | Demo rehearsal + final bug fix |

---

## 2. Build Phases

### Phase 0 — Project Setup (00:00 – 00:30)

**Objective:** Tất cả devs có môi trường chạy được, shared models committed, không bị block nhau.

**Deliverables:**
- Xcode project tạo xong, build thành công
- Git repo với 3 feature branches
- `Core/DesignSystem/` tokens committed
- Shared domain models committed vào `main`: `PoseObservation.swift`, `AICoachingResponse.swift`, `EditingRecipe.swift`, `CoachingRule.swift`, `SceneContext.swift`
- `Config.plist.template` (gitignored version với API key placeholder)

**Exit Criteria:**
- `⌘B` build thành công trên cả 3 máy
- Shared models compile không error

**Risks:**
- Xcode version mismatch → chuẩn bị trước, thống nhất version
- Swift 6 concurrency warnings → enable strict concurrency từ đầu

---

### Phase 1 — Camera + Design System (00:00 – 01:00) [Dev A]

**Objective:** Camera preview 30 FPS chạy trên device.

**Deliverables:**
- `CameraEngine` với `sampleBufferStream` và `capturePhoto()`
- `CameraScreen` hiển thị full-screen preview
- `CaptureButton`, `FlashToggle` components
- Camera permission flow

**Exit Criteria:**
- Camera preview hiển thị 30 FPS trên iPhone thật
- Permission denied flow hiển thị guide screen
- Build không warning

**Risks:**
- AVCaptureSession setup phức tạp → có sẵn boilerplate trong `docs/07-1_WORKSPACE_BOOTSTRAP.md`

---

### Phase 2 — Vision + Rule Engine (00:30 – 01:30) [Dev B]

**Objective:** Pose detection streaming + deterministic coaching rules.

**Deliverables:**
- `VisionEngine` subscribe camera buffer, emit `PoseObservation`
- `PoseCoaching` tính toán angles
- `RuleEngine` evaluate 8 rules, emit `RuleEngineResult`
- `SceneAnalysis` (indoor/outdoor hoặc mock)

**Exit Criteria:**
- `PoseObservation` có data khi test với mock buffer
- `RuleEngine.evaluate()` pass unit tests
- Tất cả 8 rules được implement

**Risks:**
- Vision không chạy trên simulator → Dev B test trên device ngay từ đầu

---

### Phase 3 — AI Module + Overlay (00:30 – 02:00) [Dev C]

**Objective:** Mock AI pipeline + Overlay hiển thị coaching cue.

**Deliverables:**
- `OpenAIClient` + `MockAIClient`
- `PromptBuilder` build payload từ issues
- `AIOrchestrator` với throttle + fallback
- `LiveOverlay` (`CoachingCard` + `DirectionArrow`)
- `CoreImageProcessor` apply recipe
- `ResultScreen` với edited image + save/retake

**Exit Criteria:**
- `MockAIClient` return `AICoachingResponse` trong < 500ms
- `CoachingCard` hiển thị text đúng
- Overlay hiển thị "Hoàn hảo! Chụp ngay" khi `readyToCapture = true`
- `CoreImageProcessor` thay đổi visible trên ảnh test
- `ResultScreen` hiển thị ảnh kết quả + 2 buttons

**Risks:**
- Nhiều modules trong 1 stream → Dev C ưu tiên MockAI + Overlay + Ready Cue trước, Result sau

---

### Phase 4 — Integration (02:30 – 03:15)

**Objective:** Wire 3 streams thành 1 flow hoàn chỉnh.

**Deliverables:**
- `AppCoordinator` inject dependencies
- Camera → Vision → Rule → Overlay pipeline live
- Ready Cue → Capture → Result → Save pipeline live
- AI thật thay MockAI (nếu có API key)

**Exit Criteria:**
- Demo flow 11 bước chạy không crash
- Overlay update khi pose thay đổi
- Ready-to-capture cue xuất hiện khi không còn blocking issues
- Result screen xuất hiện sau capture
- Save thành công vào Photos

**Risks:**
- Interface mismatch → resolve ngay, không workaround
- AI response chậm → confirm MockAI fallback hoạt động

---

### Phase 5 — Demo Polish (03:15 – 04:00)

**Objective:** UI đẹp, smooth, không crash trong demo.

**Deliverables:**
- Loading states cho tất cả async operations
- Error states graceful
- Animation transitions mượt
- Demo script rehearsed 2 lần
- Test trên device demo chính thức

**Exit Criteria:**
- Demo Readiness Checklist pass 100%
- Không crash trong 3 lần chạy liên tiếp

---

## 3. Module Execution Plan

| Module | Owner | Type | Effort | Priority | Status | DoD |
|--------|-------|------|--------|----------|--------|-----|
| MOD-00 DesignSystem | Dev A | Human | 20 min | Must Have | not_started | Tokens compile, components render |
| MOD-01 CameraEngine | Dev A | Human+AI | 30 min | Must Have | not_started | 30 FPS on device, capture returns UIImage |
| MOD-02 CameraExperience | Dev A | Human+AI | 25 min | Must Have | not_started | Full-screen preview, capture button visible |
| MOD-03 VisionEngine | Dev B | Human+AI | 30 min | Must Have | not_started | PoseObservation stream with data |
| MOD-04 PoseCoaching | Dev B | AI | 20 min | Must Have | not_started | PoseAnalysisResult computed correctly |
| MOD-05 SceneAnalysis | Dev B | AI | 15 min | Must Have | not_started | Returns indoor/outdoor |
| MOD-06 RuleEngine | Dev B | Human+AI | 25 min | Must Have | not_started | 8 rules pass unit tests |
| MOD-07 PromptBuilder | Dev C | AI | 15 min | Must Have | not_started | Build valid JSON payload |
| MOD-08 OpenAIClient | Dev C | Human+AI | 25 min | Must Have | not_started | MockAIClient returns response, real client sends HTTP |
| MOD-09 AIOrchestrator | Dev C | Human+AI | 20 min | Must Have | not_started | Throttle works, fallback works |
| MOD-10 LiveOverlay | Dev C | AI | 20 min | Must Have | not_started | CoachingCard visible on camera screen |
| MOD-11 PhotoCapture | Dev A | AI | 15 min | Must Have | not_started | UIImage returned on tap |
| MOD-12 PhotoEditing | Dev C | AI | 20 min | Must Have | not_started | Visible change applied to test image |
| MOD-13 PostCaptureResult | Dev C | Human+AI | 20 min | Must Have | not_started | Edited image + save/retake buttons |
| MOD-14 AppCoordinator | Dev A | Human | 20 min | Must Have | not_started | All modules wired, navigation works |

---

## 4. Parallel Workstreams

### Workstream A — Camera Track (Dev A)

**Modules:** MOD-00 → MOD-01 → MOD-02 → MOD-11 → MOD-14

**Tại sao độc lập:**
- CameraEngine chỉ depend vào AVFoundation (Apple framework)
- Không cần Vision hay AI để build và test
- Dev A có thể test bằng cách nhìn vào preview và tap capture

**Sequence:**
```
MOD-00 (20min) → MOD-01 (30min) → MOD-02 (25min) → MOD-11 (15min) → MOD-14 (20min)
```

---

### Workstream B — Vision Track (Dev B)

**Modules:** MOD-03 → MOD-04 → MOD-06 → MOD-05

**Tại sao độc lập:**
- VisionEngine chỉ cần CMSampleBuffer — có thể mock bằng static buffer từ ảnh test
- RuleEngine là pure logic, không có dependency framework
- Dev B có thể unit test RuleEngine hoàn toàn offline

**Sequence:**
```
MOD-03 (30min) → MOD-04 (20min) → MOD-06 (25min)
                                         ↑
                              MOD-05 (15min) — parallel với MOD-06
```

---

### Workstream C — AI Track (Dev C)

**Modules:** MOD-08 → MOD-07 → MOD-12 → MOD-09 → MOD-10 → MOD-13

**Tại sao độc lập:**
- OpenAIClient chỉ cần URLSession — test với real API hoặc mock
- CoreImageProcessor chỉ cần UIImage + struct — test với bất kỳ ảnh nào
- ResultScreen mock data đủ để build UI

**Sequence:**
```
MOD-08 (25min) ──► MOD-09 (20min) ──► MOD-10 (20min)
      │
MOD-07 (15min) ──► (feeds MOD-09)
      │
MOD-12 (20min) ──► MOD-13 (25min)
```

---

## 5. AI Coding Agent Assignment

| Module | Preferred Agent | Lý do | Human Review |
|--------|----------------|-------|--------------|
| MOD-00 DesignSystem | **Claude Code** | Cần hiểu design token system, consistent naming | Required — check visual |
| MOD-01 CameraEngine | **Claude Code** | AVFoundation phức tạp, cần Swift 6 actor safety | Required — test trên device |
| MOD-02 CameraExperience | **Codex / Cursor** | SwiftUI layout đơn giản, MVVM boilerplate | Review UI |
| MOD-03 VisionEngine | **Claude Code** | Vision Framework API subtleties, async stream | Required — device test |
| MOD-04 PoseCoaching | **Codex** | Pure math/geometry, deterministic | Unit test pass |
| MOD-05 SceneAnalysis | **Codex** | Simple heuristic hoặc CoreML wrapper | Unit test pass |
| MOD-06 RuleEngine | **Claude Code** | Logic cần correct, nhiều edge cases | Required — 8 rules verified |
| MOD-07 PromptBuilder | **Codex** | String building + struct mapping | Verify prompt tiếng Việt |
| MOD-08 OpenAIClient | **Claude Code** | Network layer, error handling, timeout, security | Required — API key handling |
| MOD-09 AIOrchestrator | **Claude Code** | Throttle + cache + fallback logic phức tạp | Required |
| MOD-10 LiveOverlay | **Codex / Cursor** | SwiftUI overlay, animation | Review visual |
| MOD-11 PhotoCapture | **Codex** | Thin wrapper, ít logic | Test capture returns image |
| MOD-12 PhotoEditing | **Codex** | CoreImage filter chain, công thức rõ ràng | Verify visual output |
| MOD-13 PostCaptureResult | **Codex / Cursor** | SwiftUI layout, presentation | Result UI |
| MOD-14 AppCoordinator | **Claude Code** | DI wiring, navigation graph, Swift 6 | Required — full build test |

---

## 6. Git Strategy

### Branch Structure

```
main
├── feature/dev-a-camera       ← Dev A
├── feature/dev-b-vision       ← Dev B
└── feature/dev-c-ai           ← Dev C
```

### Merge Rules

| Rule | Detail |
|------|--------|
| Shared models | Commit vào `main` trực tiếp lúc 00:30 — một người làm, hai người pull |
| Feature branches | Merge vào `main` tại checkpoint 02:30 |
| Không rebase trong hackathon | Chỉ `git merge` để tránh mất code |
| Build phải pass trước merge | `⌘B` không có error là điều kiện duy nhất |
| Commit thường xuyên | Mỗi module hoàn thành = 1 commit rõ ràng |

### Commit Message Convention

```
feat(camera): add CameraEngine with sampleBufferStream
feat(vision): implement VisionEngine pose detection
feat(ai): add OpenAIClient with MockAIClient fallback
feat(overlay): render CoachingCard on camera screen
fix(capture): handle AVCapturePhoto delegate correctly
chore(models): add shared domain models
```

### Tag Strategy

```
v0.1-m1   ← sau 00:30 (project setup)
v0.1-m2   ← sau 01:30 (camera + vision)
v0.1-m3   ← sau 02:30 (full integration)
v0.1-demo ← sau 03:15 (demo ready)
```

---

## 7. Integration Checkpoints

### Checkpoint 1 — Project Live (00:30)

**Criteria:**
- [ ] Xcode project build thành công (`⌘B`)
- [ ] Git branches tạo xong, mỗi dev trên branch riêng
- [ ] Shared domain models compile: `PoseObservation`, `AICoachingResponse`, `EditingRecipe`, `CoachingRule`
- [ ] DesignSystem tokens available: `Colors.accent`, `Typography.coaching`
- [ ] `Config.plist` với API key placeholder

---

### Checkpoint 2 — Camera + Vision Live (01:30)

**Criteria:**
- [ ] Camera preview hiển thị full-screen 30 FPS trên iPhone thật
- [ ] Camera permission request hoạt động
- [ ] `VisionEngine` emit `PoseObservation` khi có người trong frame
- [ ] `personDetected = true` khi đứng trước camera
- [ ] `RuleEngine` trả về ít nhất 1 `CoachingRule` với mock pose data

---

### Checkpoint 3 — AI Pipeline Ready (02:00)

**Criteria:**
- [ ] `MockAIClient` return `AICoachingResponse` với valid `main_cue` (tiếng Việt)
- [ ] `AIOrchestrator` emit response qua `coachingStream`
- [ ] `PromptBuilder` build payload JSON đúng schema
- [ ] `CoreImageProcessor` apply recipe, thấy được sự thay đổi trên ảnh test

---

### Checkpoint 4 — Overlay Live (02:15)

**Criteria:**
- [ ] `CoachingCard` visible trên camera screen
- [ ] Text thay đổi khi pose thay đổi
- [ ] `DirectionArrow` chỉ đúng hướng
- [ ] Hiển thị "Bước vào khung hình" khi không có người
- [ ] Hiển thị "Hoàn hảo! Chụp ngay" khi `readyToCapture = true`

---

### Checkpoint 5 — Full MVP Flow (02:30)

**Criteria:**
- [ ] Capture button tap → `UIImage` returned
- [ ] `ResultScreen` xuất hiện sau capture
- [ ] Edited image hiển thị rõ
- [ ] "Lưu ảnh" button hoạt động
- [ ] "Chụp lại" navigate về Camera

---

### Checkpoint 6 — Demo Ready (03:15)

**Criteria:**
- [ ] Full 11-step demo flow chạy không crash
- [ ] AI thật hoặc Mock AI đều cho kết quả tốt
- [ ] Không có loading state bị treo
- [ ] Error states handled gracefully
- [ ] UI nhìn đẹp trên iPhone demo device
- [ ] Test 3 lần liên tiếp không crash

---

## 8. Interface Contracts

Đây là contracts bất biến. Các devs KHÔNG được thay đổi sau 00:30 mà không thông báo team.

### Shared Domain Models

```
// PoseObservation.swift
struct PoseObservation {
    let head: CGPoint?
    let neck: CGPoint?
    let leftShoulder: CGPoint?
    let rightShoulder: CGPoint?
    let hip: CGPoint?
    let leftKnee: CGPoint?
    let rightKnee: CGPoint?
    let leftFoot: CGPoint?
    let rightFoot: CGPoint?
    let confidence: Float
    let timestamp: TimeInterval
}

// CoachingRule.swift
struct CoachingRule {
    let id: String
    let message: String           // tiếng Việt
    let direction: Direction?     // up/down/left/right/none
    let priority: Int             // 1=highest
}
enum Direction { case up, down, left, right, rotateLeft, rotateRight, forward, backward }

// SceneContext.swift
enum SceneContext { case indoor, outdoor, unknown }

// AICoachingResponse.swift
struct AICoachingResponse {
    let mainCue: String           // tiếng Việt, ≤ 40 ký tự
    let secondaryCue: String?
    let cameraInstruction: String?
    let score: Int                // 1–5
    let feedback: String          // tiếng Việt, 1–2 câu
    let editingRecipe: EditingRecipe
}

// EditingRecipe.swift
struct EditingRecipe {
    let exposure: Float           // -1.0 to 1.0
    let contrast: Float           // -100 to 100
    let highlights: Float         // -100 to 100
    let shadows: Float            // -100 to 100
    let temperature: Float        // -100 to 100
    let vibrance: Float           // -100 to 100
    
    static let neutral = EditingRecipe(exposure: 0, contrast: 0, highlights: 0, shadows: 0, temperature: 0, vibrance: 0)
}
```

### Protocol Contracts

```
// CameraEngine → VisionEngine
protocol CameraBufferProvider {
    var sampleBufferStream: AsyncStream<CMSampleBuffer> { get }
}

// VisionEngine → PoseCoaching + RuleEngine
protocol PoseProvider {
    var poseStream: AsyncStream<PoseObservation?> { get }
    var personDetectedStream: AsyncStream<Bool> { get }
}

// RuleEngine → AIOrchestrator + LiveOverlay
protocol RuleEngineProtocol {
    func evaluate(pose: PoseObservation, scene: SceneContext) -> RuleEngineResult
}
struct RuleEngineResult {
    let issues: [CoachingRule]
    let readyToCapture: Bool
}

// OpenAIClient — swappable với MockAIClient
protocol AIBackendProtocol {
    func send(_ request: OpenAIRequest) async throws -> AICoachingResponse
}

// AIOrchestrator → Overlay + Review
protocol AICoachingProvider {
    var coachingStream: AsyncStream<AICoachingResponse> { get }
}

// CoreImageProcessor — standalone
protocol ImageProcessor {
    func apply(recipe: EditingRecipe, to image: UIImage) async -> UIImage
}
```

### Navigation Contract

```
// AppCoordinator events
enum AppNavigationEvent {
    case captureCompleted(image: UIImage, coaching: AICoachingResponse)
    case reviewDismissed
    case reviewRetake
}
```

---

## 9. Progress Tracking Dashboard

| Module | Progress | Owner | Blocked? | Waiting For | Est. Done |
|--------|----------|-------|----------|-------------|-----------|
| MOD-00 DesignSystem | 0% | Dev A | No | — | 00:25 |
| MOD-01 CameraEngine | 0% | Dev A | No | MOD-00 | 00:55 |
| MOD-02 CameraExperience | 0% | Dev A | No | MOD-01 | 01:20 |
| MOD-03 VisionEngine | 0% | Dev B | No | Shared models | 01:10 |
| MOD-04 PoseCoaching | 0% | Dev B | No | MOD-03 | 01:30 |
| MOD-05 SceneAnalysis | 0% | Dev B | No | MOD-01 | 01:45 |
| MOD-06 RuleEngine | 0% | Dev B | No | MOD-04, MOD-05 | 02:00 |
| MOD-07 PromptBuilder | 0% | Dev C | No | Shared models | 00:45 |
| MOD-08 OpenAIClient | 0% | Dev C | No | Shared models | 01:00 |
| MOD-09 AIOrchestrator | 0% | Dev C | No | MOD-06, MOD-07, MOD-08 | 01:30 |
| MOD-10 LiveOverlay | 0% | Dev C | No | MOD-09 | 02:00 |
| MOD-11 PhotoCapture | 0% | Dev A | No | MOD-01 | 01:35 |
| MOD-12 PhotoEditing | 0% | Dev C | No | Shared models | 01:20 |
| MOD-13 PostCaptureResult | 0% | Dev C | No | MOD-12, MOD-09 | 02:15 |
| MOD-14 AppCoordinator | 0% | Dev A | No | All modules | 03:00 |

---

## 10. Testing Strategy

### Unit Tests (Dev B priority — RuleEngine)

| Test | Module | What to test |
|------|--------|-------------|
| `testChinDownRule` | RuleEngine | Chin Y < shoulder Y - threshold → rule triggered |
| `testShoulderImbalanceRule` | RuleEngine | leftShoulder.y - rightShoulder.y > 0.05 → rule triggered |
| `testReadyToCaptureWhenNoIssues` | RuleEngine | Empty issues → `readyToCapture = true` |
| `testEditingRecipeApplied` | CoreImageProcessor | output image pixel values differ from input |
| `testMockAIClientResponse` | OpenAIClient | MockAIClient returns valid `AICoachingResponse` |
| `testPromptBuilderPayload` | PromptBuilder | JSON payload contains all required fields |
| `testThrottle` | AIOrchestrator | Only 1 AI call per 3 seconds |
| `testFallbackOnTimeout` | AIOrchestrator | RuleEngine result used when AI times out |

### Manual Tests (trên device)

| Test | Pass Criteria |
|------|--------------|
| Camera opens | Preview trong ≤ 2 giây |
| Person detected | Skeleton overlay xuất hiện |
| Coaching cue | Text tiếng Việt đúng với pose |
| Capture | Ảnh rõ nét, không blur |
| Result screen | Edited image visible |
| Save | Ảnh xuất hiện trong Photos app |
| Offline mode | Overlay vẫn hoạt động khi tắt wifi |
| Permission denied | Guide screen hiển thị, không crash |

### Performance Tests (Instruments — nếu còn thời gian)

| Metric | Tool | Target |
|--------|------|--------|
| Camera FPS | Instruments > Core Animation | ≥ 30 FPS |
| RAM usage | Instruments > Allocations | < 200 MB |
| AI response time | Print log timing | < 1000ms |

### Integration Test — Demo Flow

```
1. Launch app → camera mở trong ≤ 2s
2. Đứng trước camera → CoachingCard hiển thị
3. Thay đổi tư thế → cue thay đổi
4. Tư thế đúng → "Hoàn hảo! Chụp ngay" xuất hiện
5. Tap Capture → flash + chuyển màn
6. Result screen → edited image visible
7. Tap "Lưu ảnh" → confirmation + về camera
8. Mở Photos app → ảnh tồn tại
```

---

## 11. Risk Register

| ID | Risk | Impact | Likelihood | Mitigation | Fallback |
|----|------|--------|------------|------------|---------|
| R-01 | Vision không chạy trên simulator | High | Certain | Test trên device từ đầu | Mock PoseObservation stream |
| R-02 | OpenAI API key không có / rate limit | High | Medium | MockAIClient sẵn sàng | Demo với Mock hoàn toàn |
| R-03 | Shared model conflict giữa 3 devs | High | Medium | Dev A commit models lúc 00:30, lock | Hotfix ngay khi phát hiện |
| R-04 | Interface mismatch lúc integration | High | Medium | Contracts locked sau 00:30 | 30 min buffer tại Phase 4 |
| R-05 | Vision accuracy thấp (tư thế sai detect) | Medium | Low | Tune confidence threshold | Lower threshold, show anyway |
| R-06 | CoreImage processing lag | Medium | Low | Background thread | Skip edit, show original |
| R-07 | AI coaching text sai tiếng Việt | Medium | Medium | System prompt enforce tiếng Việt | Hardcode canned Vietnamese text |
| R-08 | Save photo permission crash | Medium | Low | Handle PHError gracefully | Show manual screenshot guide |
| R-09 | Device khác màn hình demo | Low | Low | Test trên đúng device demo | Adaptive layout |
| R-10 | Merge conflict lúc 02:30 | Medium | Medium | Micro-integrations mỗi 30 phút | Manual conflict resolution 15 min |

---

## 12. Demo Readiness Checklist

Chạy checklist này trước khi lên demo. Tất cả phải pass.

### Core Flow

- [ ] App launch: camera mở ≤ 2 giây, không black screen
- [ ] Person detection: bước vào frame → skeleton/overlay xuất hiện
- [ ] Coaching cue: text tiếng Việt hiển thị đúng với tư thế
- [ ] Cue thay đổi khi điều chỉnh tư thế
- [ ] "Hoàn hảo! Chụp ngay" xuất hiện khi tư thế đúng
- [ ] Capture: tap button → ảnh được chụp, không lag
- [ ] Result screen: xuất hiện sau capture, có ảnh kết quả
- [ ] Core Image: ảnh sau chỉnh sửa có sự khác biệt nhìn thấy được
- [ ] Save: tap "Lưu ảnh" → ảnh trong Photos app
- [ ] Retake: navigate về camera, không crash

### Edge Cases

- [ ] Tắt wifi → overlay vẫn hoạt động (Rule Engine fallback)
- [ ] Không có người trong frame → "Bước vào khung hình"
- [ ] Nhiều người trong frame → không crash
- [ ] Xoay device (landscape) → không crash (có thể lock portrait)

### UI / UX

- [ ] Không có loading state nào bị treo mãi
- [ ] Không có màn hình trắng / đen bất ngờ
- [ ] Text không bị clip hoặc overflow
- [ ] Buttons có touch feedback
- [ ] Dark mode nhìn đẹp

### Technical

- [ ] Không có crash trong 3 lần demo đầy đủ liên tiếp
- [ ] RAM < 200 MB (check trong Xcode debug bar)
- [ ] Không có memory leak rõ ràng
- [ ] API key không xuất hiện trong log console

---

*Đây là plan thực thi. Mọi quyết định implementation phải theo document này. Không redesign architecture trong quá trình build.*
