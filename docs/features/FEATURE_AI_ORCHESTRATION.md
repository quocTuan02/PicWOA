# FEATURE — AI Orchestration (Dev C)

**Feature group:** MOD-07 PromptBuilder · MOD-08 OpenAIClient · MOD-09 AIOrchestrator
**Owner:** Dev C
**Allowed dirs:** `AI/PromptBuilder/`, `AI/OpenAIClient/`, `AI/AIOrchestrator/`
**Spec:** `AI_ORCHESTRATION_SPEC.md` (contract), `09_PROMP_BUILDER.md`, `08_AI_ORCHESTRATOR.md`
**Principle:** AI phải vô hình — user chỉ thấy coaching tốt, không bao giờ chờ blank screen, không bao giờ crash vì AI.

---

## 1. Module Summary

Lõi điều phối AI: nhận `RuleEngineResult` → quyết định có gọi Cloud AI hay không → build prompt → gọi OpenAI (hoặc Mock) → validate → emit `AICoachingResponse` qua `coachingStream`. Luôn emit RuleEngine fallback **ngay lập tức** (zero-latency UX), AI đến sau override.

**Responsibilities:**
- Decision engine theo 5 path (no-issues / throttle / AI / timeout / error) — `AI_ORCHESTRATION_SPEC §2`.
- Throttle 1 req / N giây (config), cache TTL 30s, fallback 3 tier.
- Validate AI response trước khi emit.
- Observability nội bộ (`DecisionPath`, `OrchestratorMetrics`) — debug log only.
- Config-driven: model, API key, throttle, timeout, `USE_MOCK_AI` load từ `Config.plist`.

---

## 2. Interface Contracts (KHÔNG đổi)

```swift
// Input (từ Dev B — RuleEngine)
struct RuleEngineResult { let issues: [CoachingRule]; let readyToCapture: Bool }   // ⚠ code thực tế KHÔNG có framePosition
func evaluate(pose: PoseObservation, scene: SceneContext) -> RuleEngineResult

// Output
protocol AICoachingProvider { var coachingStream: AsyncStream<AICoachingResponse> { get } }
protocol AIBackendProtocol  { func send(_ request: OpenAIRequest) async throws -> AICoachingResponse }
```

> Lưu ý divergence: `MODULE_PLAN` nói `RuleEngineResult` có `framePosition`, nhưng **code thực tế chưa có**. Tới khi Dev B thêm, `OpenAIRequest` default `framePosition = "center"`. Không tự thêm field vào SharedKernel (cần đồng thuận 3 dev).

---

## 3. Files

| File | Action | Nội dung |
|------|--------|---------|
| `AI/OpenAIClient/AIConfig.swift` | **new** | Load Config.plist; factory `makeBackend()` |
| `AI/OpenAIClient/OpenAIClient.swift` | edit | Model/timeout từ config, retry 1 lần |
| `AI/OpenAIClient/MockAIClient.swift` | keep | (đã ổn) |
| `AI/OpenAIClient/OpenAIRequest.swift` | keep | |
| `AI/PromptBuilder/PromptBuilder.swift` | edit | Scene-aware, model param |
| `AI/PromptBuilder/PromptTemplates.swift` | **new** | Template Outdoor/Indoor + selectTemplate |
| `AI/AIOrchestrator/ResponseValidator.swift` | **new** | validate() theo §5 |
| `AI/AIOrchestrator/OrchestratorMetrics.swift` | **new** | DecisionPath + metrics |
| `AI/AIOrchestrator/AIOrchestrator.swift` | rewrite | Decision engine đầy đủ |
| `AI/AIOrchestrator/ResponseParser.swift` | keep | |
| `PicwoaTests/PromptBuilderTests.swift` | **new** | payload schema |
| `PicwoaTests/ResponseValidatorTests.swift` | **new** | range validation |
| `PicwoaTests/AIOrchestratorTests.swift` | **new** | throttle + fallback |

---

## 4. Decision Engine (per RuleEngineResult)

```
emit Tier-3 fallback NGAY (zero latency)
│
├─ readyToCapture            → DecisionPath.ruleEngineClean → STOP
├─ trong throttle window      → emit cached nếu < 30s → ruleEngineThrottle → STOP
└─ throttle OK + có issues
       → backend.send()
          ├─ valid       → cache + emit → aiSuccess
          ├─ invalid     → bestAvailable → aiError
          ├─ timeout     → bestAvailable → aiTimeout
          └─ error       → bestAvailable → aiError
```

`bestAvailable = AI(valid) ?? cached(<30s) ?? RuleEngine fallback` (§6 spec, 3 tier).

---

## 5. Definition of Done

- [ ] Build pass (strict concurrency complete).
- [ ] `USE_MOCK_AI` toggle đổi backend; thiếu key → Mock.
- [ ] API key không xuất hiện trong log.
- [ ] `testPromptBuilderPayload`, `testResponseValidator`, `testThrottle`, `testFallbackOnTimeout` pass.
- [ ] `coachingStream` emit tiếng Việt qua Mock < 0.5s.

---

## 6. Integration Notes

- `AIOrchestrator` mặc định tự chọn backend qua `AIConfig.makeBackend()`. AppCoordinator (Dev A) chỉ cần `AIOrchestrator()` rồi `start(ruleStream:sceneStream:)` hoặc gọi `process(pose:scene:)`.
- **Config.plist bundling:** code resilient — nếu Config.plist không có trong bundle → default `USE_MOCK_AI = true`. Để dùng real key, Dev A thêm `Picwoa/Resources/Config.plist` vào `resources:` trong `project.yml`. Không bắt buộc cho demo.
- LiveOverlay/Review subscribe `coachingStream` — không đổi.
