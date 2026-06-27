# DEV C — TASK PLAN (AI Track)

**Owner:** Dev C — AI Lead
**Branch:** `feature/ai-coaching` (đang ở `feat/ai_coaching`)
**Owned modules:** MOD-07 PromptBuilder · MOD-08 OpenAIClient · MOD-09 AIOrchestrator · MOD-10 LiveOverlay · MOD-12 PhotoEditing · MOD-13 PhotoReview
**Owned folders:** `AI/PromptBuilder/`, `AI/OpenAIClient/`, `AI/AIOrchestrator/`, `Features/LiveOverlay/`, `Features/PhotoReview/`, `Features/PhotoEditing/`
**Reference specs:** `AI_ORCHESTRATION_SPEC.md`, `09_PROMP_BUILDER.md`, `08_AI_ORCHESTRATOR.md`, `ARCHITECTURE_PICWOA.md`

---

## 0. Tình trạng hiện tại (đã scaffold xong, chạy mức cơ bản)

| Module | File | Trạng thái | Còn thiếu so với spec |
|--------|------|-----------|----------------------|
| PromptBuilder | `AI/PromptBuilder/PromptBuilder.swift` | ✅ Cơ bản OK | Scene-aware template (6 template), model không hardcode |
| OpenAIClient | `AI/OpenAIClient/OpenAIClient.swift` | ✅ HTTP OK | Load key từ Config.plist, retry 1 lần, timeout config |
| MockAIClient | `AI/OpenAIClient/MockAIClient.swift` | ✅ OK | (ổn — có 3 canned response) |
| ResponseParser | `AI/AIOrchestrator/ResponseParser.swift` | ✅ OK | `ResponseValidator.validate()` chưa có |
| AIOrchestrator | `AI/AIOrchestrator/AIOrchestrator.swift` | 🟡 Một nửa | Config, DecisionPath, metrics, cache TTL 30s, scene-aware throttle, fallback tiers, `start(ruleStream:sceneStream:)` |
| LiveOverlay | `Features/LiveOverlay/` | 🟡 Một nửa | DirectionArrow chưa wire (`direction: nil`), chưa subscribe `personDetectedStream` |
| CoreImageProcessor | `Features/PhotoEditing/Services/CoreImageProcessor.swift` | ✅ OK | Verify visible diff bằng test |
| PhotoReview | `Features/PhotoReview/` | 🟡 Một nửa | Save error handling, BeforeAfter drag-to-compare, navigate retake |

**Kết luận:** Công việc DEV C = **hoàn thiện AIOrchestrator theo spec → wire overlay đầy đủ → hardening Review/Save → integration → polish.** Pipeline xương sống đã chạy được với Mock.

---

## 1. Thứ tự thực thi (critical path)

```
T1 Config + OpenAIClient hardening ─┐
T2 PromptBuilder scene-aware        ├─► T4 AIOrchestrator (spec đầy đủ) ─► T6 Integration ─► T8 Polish
T3 ResponseValidator                ┘                                      ▲
T5 LiveOverlay (arrow + person) ──────────────────────────────────────────┤
T7 PhotoEditing verify + PhotoReview hardening ────────────────────────────┘
```

**Ưu tiên vàng (theo Tech Lead):** `MockAI → Overlay → CoreImage → Review`. KHÔNG đụng real OpenAI cho tới khi Overlay chạy với Mock trên camera thật.

---

## 2. Task chi tiết

### T1 — Config + OpenAIClient hardening  `[MOD-08]` · ~25 min · Claude Code
- [ ] Tạo `AI/OpenAIClient/AIConfig.swift`: load `Config.plist` (API_KEY, AI_MODEL_DEFAULT, USE_MOCK_AI, AI_THROTTLE_SECONDS, AI_TIMEOUT_SECONDS). Không hardcode.
- [ ] `OpenAIClient`: nhận `model` + `timeout` từ config (hiện hardcode `gpt-4o-mini` trong PromptBuilder + `2.0` trong client).
- [ ] Thêm **retry 1 lần** khi timeout/5xx (spec yêu cầu).
- [ ] Factory `makeBackend()` → trả `MockAIClient` nếu `USE_MOCK_AI == true` hoặc thiếu key, ngược lại `OpenAIClient`.
- [ ] Verify API key **không bao giờ** xuất hiện trong `print`/log.
- **DoD:** Build pass; toggle `USE_MOCK_AI` đổi backend; không leak key.

### T2 — PromptBuilder scene-aware  `[MOD-07]` · ~15 min · Codex
- [ ] Thêm `PromptTemplates.swift`: 2 template MVP (Outdoor default + Indoor) theo §4 spec, struct sẵn cho 6 template.
- [ ] `selectTemplate(scene:)` chọn template theo `SceneContext` (unknown → outdoor).
- [ ] Model lấy từ `AIConfig`, không hardcode trong `buildChatRequest`.
- [ ] Giữ payload < 300 input tokens (chỉ gửi issue IDs, không gửi coordinates).
- **DoD:** Unit test `testPromptBuilderPayload` — JSON chứa đủ field, system prompt tiếng Việt, đổi scene → đổi template.

### T3 — ResponseValidator  `[MOD-08/09]` · ~10 min · Codex
- [ ] Thêm `ResponseValidator.validate(_:)` theo §5 spec (mainCue không rỗng & ≤40 ký tự, score 1...5, exposure -1...1, contrast -100...100).
- [ ] Gọi validator **trước khi emit** AI response trong Orchestrator; fail → bỏ qua, dùng fallback.
- **DoD:** Unit test: response hợp lệ → true; mainCue 50 ký tự / score 9 → false.

### T4 — AIOrchestrator đầy đủ theo spec  `[MOD-09]` · ~30 min · Claude Code · ⭐ TRỌNG TÂM
Đối chiếu checklist §12 `AI_ORCHESTRATION_SPEC.md`:
- [ ] Load config (throttle, timeout, useMock) qua `AIConfig`.
- [ ] `DecisionPath` enum + `OrchestratorMetrics` struct (observability, debug-only log).
- [ ] **Decision paths A–E** (§2): no-person stop / clean stop / throttle-skip / AI call / timeout fallback.
- [ ] Emit RuleEngine result **ngay lập tức** (Tier 3), AI async sau (đã có — giữ).
- [ ] **Cache TTL**: `cachedResponse` + `cachedAt`, dùng cached khi < 30s (Tier 2). Hiện cache chưa có TTL.
- [ ] `shouldInvalidateCache(current:previous:)` — symmetricDifference > 1 issue (§8).
- [ ] `bestAvailableResponse(...)` fallback tree 3 tier (§6).
- [ ] `ResponseValidator.validate()` trước emit (từ T3).
- [ ] `start(ruleStream:sceneStream:)` + `stop()` — API khớp contract `MODULE_PLAN`. Hiện chỉ có `process(pose:scene:)`.
- [ ] `#if DEBUG` log decision path.
- **DoD:** Unit test `testThrottle` (1 call/3s), `testFallbackOnTimeout` (Mock ném lỗi → dùng RuleEngine). No duplicate AI calls.

### T5 — LiveOverlay hoàn chỉnh  `[MOD-10]` · ~20 min · Cursor/Codex
- [ ] Wire `DirectionArrow`: lấy `direction` từ top `CoachingRule` (hiện hardcode `direction: nil`). Cần đẩy direction vào `AICoachingResponse` hoặc giữ rule result trong VM.
- [ ] Subscribe `personDetectedStream` từ VisionEngine (MOD-03) → ẩn overlay khi không có người (contract đã có ở `OverlayViewModel.updatePersonDetected`).
- [ ] State hiển thị: "Bước vào khung hình" (no person) / cue (coaching) / "Hoàn hảo! Chụp ngay" (ready, có pulse).
- [ ] `isReadyToCapture` hiện check bằng string `.contains("Chụp ngay")` — fragile. Đổi sang field rõ ràng (readyToCapture bool) khi integrate.
- **DoD:** Checkpoint 4 — card visible, đổi theo pose, arrow đúng hướng, ẩn khi không người.

### T6 — PhotoEditing verify + PhotoReview hardening  `[MOD-12/13]` · ~25 min · Codex/Cursor
- [ ] `CoreImageProcessor`: viết test `testEditingRecipeApplied` so sánh pixel trước/sau (visible diff). Chạy background thread (đã `async`).
- [ ] `ReviewViewModel.save()`: handle `PHError` graceful (hiện `// TODO`), cần `NSPhotoLibraryAddUsageDescription` tiếng Việt trong Info.plist (nhắc Dev A).
- [ ] `ReviewScreen`: score 1–5 sao + feedback tiếng Việt + `BeforeAfterView` (drag-to-compare nếu kịp, không thì side-by-side) + nút "Lưu ảnh" / "Chụp lại".
- [ ] Loading indicator khi `process()` đang chạy; success toast sau save.
- **DoD:** Checkpoint 5 — capture → review hiện score + before/after → lưu vào Photos → retake về camera.

### T7 — Integration (02:30–03:15) · cùng Dev A + Dev B
- [ ] Sync 02:00 với Dev B: chốt format `RuleEngineResult` stream (issues + readyToCapture + framePosition).
- [ ] Wire `AIOrchestrator.start()` vào real RuleEngine stream của Dev B (thay vì gọi `process` trực tiếp).
- [ ] Test LiveOverlay với real camera feed (Dev A).
- [ ] Test ReviewScreen với real capture (UIImage thật + AICoachingResponse).
- [ ] Swap MockAI → real OpenAI **chỉ khi** có API key và overlay đã chạy ổn (quyết định của Tech Lead lúc 03:00).
- **DoD:** Demo flow end-to-end chạy với Mock không crash.

### T8 — Polish (03:15–04:00)
- [ ] Loading states cho mọi async (review processing, save).
- [ ] Error states graceful (AI fail → fallback im lặng, save fail → toast).
- [ ] Animation cue transition mượt, không flash.
- [ ] Test offline (tắt wifi → overlay vẫn chạy bằng RuleEngine fallback).
- [ ] Tắt console log nhạy cảm trước demo.

---

## 3. Interface contracts DEV C phụ thuộc (KHÔNG tự đổi)

```swift
// Từ Dev B (input cho Orchestrator)
struct RuleEngineResult { let issues: [CoachingRule]; let readyToCapture: Bool; let framePosition: String }
protocol RuleEngineProtocol { func evaluate(pose: PoseAnalysisResult, scene: SceneContext) -> RuleEngineResult }

// Từ Dev B (input cho Overlay)
var personDetectedStream: AsyncStream<Bool>   // PoseProvider

// DEV C cung cấp ngược lại (output)
protocol AICoachingProvider { var coachingStream: AsyncStream<AICoachingResponse> { get } }
protocol AIBackendProtocol  { func send(_ request: OpenAIRequest) async throws -> AICoachingResponse }
protocol ImageProcessor     { func apply(recipe: EditingRecipe, to image: UIImage) async -> UIImage }

// Từ Dev A (capture → review)
enum AppNavigationEvent { case captureCompleted(image: UIImage, coaching: AICoachingResponse); case reviewDismissed; case reviewRetake }
```

> ⚠️ `AICoachingResponse` trong code hiện **không có field `score`/`feedback` rời** — kiểm tra: `Shared/Models/AICoachingResponse.swift` đã có `score` + `feedback` (BUILD_EXECUTION_PLAN §8 yêu cầu). Đã khớp.

---

## 4. Checkpoints của DEV C

| Time | Checkpoint | Tiêu chí |
|------|-----------|---------|
| 01:00 | MockAI ready | `MockAIClient` trả `AICoachingResponse` < 0.5s, CoreImage áp recipe được |
| 02:00 | AI Pipeline (CP3) | Orchestrator emit qua `coachingStream`, PromptBuilder JSON đúng schema |
| 02:15 | Overlay live (CP4) | CoachingCard visible, đổi theo pose, arrow đúng hướng |
| 02:30 | Full MVP (CP5) | Capture → Review → score + before/after → Save |
| 03:15 | Demo ready (CP6) | 11 bước không crash, offline mode OK |

---

## 5. Rủi ro riêng của DEV C

| Risk | Mitigation |
|------|-----------|
| Quá tải 6 module | Theo ưu tiên Mock→Overlay→CoreImage→Review; bỏ real OpenAI nếu thiếu giờ — overlay từ RuleEngine đủ demo |
| OpenAI key thiếu / rate limit | `USE_MOCK_AI = true`, demo hoàn toàn bằng Mock — không ai biết |
| `RuleEngineResult` mismatch với Dev B | Sync 02:00, contract đã lock trong SharedKernel |
| AI text sai tiếng Việt | System prompt enforce tiếng Việt + canned Mock fallback |
| Save photo crash | Handle `PHError`, cần `NSPhotoLibraryAddUsageDescription` |

---

## 6. Unit tests DEV C cần pass

| Test | Module |
|------|--------|
| `testMockAIClientResponse` | OpenAIClient (✅ đã có file `MockAIClientTests`) |
| `testPromptBuilderPayload` | PromptBuilder |
| `testThrottle` | AIOrchestrator |
| `testFallbackOnTimeout` | AIOrchestrator |
| `testEditingRecipeApplied` | CoreImageProcessor |
| `testResponseValidator` | ResponseValidator |

---

*Plan này bám theo `BUILD_EXECUTION_PLAN.md` + `AI_ORCHESTRATION_SPEC.md`. Không redesign — chỉ hoàn thiện gap giữa scaffolding và spec, rồi integrate.*
