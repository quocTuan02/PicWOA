# AI ORCHESTRATION SPEC — Picwoa

**Version:** 1.0  
**Owner:** Dev C  
**Reference:** `AI/AIOrchestrator/AIOrchestrator.swift`  
**Principle:** AI phải vô hình — user chỉ thấy coaching tốt, không biết từ đâu.

---

## 1. Decision Summary

Mỗi frame camera đi qua decision engine theo thứ tự cố định. **Không được skip level.**

```
Frame Input
    │
    ▼
[L1] Vision Framework
     Person detected? Pose landmarks?
     Confidence ≥ 0.5?
          │
          ├─ NO → emit "Bước vào khung hình" (stop)
          │
          └─ YES
               │
               ▼
          [L2] Core ML (Scene Classifier)
               indoor / outdoor / unknown
               Cost: ~5ms on-device
               │
               ▼
          [L3] Rule Engine
               Evaluate 8 deterministic rules
               Cost: < 10ms, zero network
               │
               ├─ issues.isEmpty → emit "Hoàn hảo! Chụp ngay" (stop)
               │
               └─ issues not empty
                    │
                    ▼
               [L4] Prompt Builder
                    Build structured JSON payload
                    < 300 input tokens
                    │
                    ▼
               [L5] Cloud AI (OpenAI)
                    Throttle: 1 req / 3s
                    Timeout: 2s
                    Fallback: L3 result
```

**Rule cứng:** Level 5 chỉ được gọi khi L3 có issues VÀ throttle window cho phép VÀ network available.

---

## 2. Execution Path — Per Frame Decision

### Path A: No Person (fastest, ~5ms)
```
Vision → personDetected = false
→ emit CoachingResponse(mainCue: "Bước vào khung hình")
→ STOP. Không gọi RuleEngine. Không gọi AI.
```

### Path B: Person + No Issues (offline, ~15ms)
```
Vision → pose detected
→ RuleEngine → issues = []
→ emit CoachingResponse(mainCue: "Hoàn hảo! Chụp ngay", score: 5)
→ STOP. Không gọi AI.
```

### Path C: Person + Issues + In Throttle Window (offline, ~15ms)
```
Vision → pose detected
→ RuleEngine → issues = [chinDown, leftShoulderLow]
→ throttle check: last request < 3s ago → SKIP AI
→ emit CoachingResponse từ RuleEngine result
→ STOP. Dùng cached AI response nếu có.
```

### Path D: Person + Issues + AI Call (normal, ~1.1s)
```
Vision → pose detected
→ RuleEngine → issues not empty
→ throttle check: OK
→ Emit RuleEngine result ngay lập tức (zero latency UX)
→ Async: PromptBuilder → OpenAI → parse response
→ Emit AI response (override RuleEngine text)
→ Cache response
```

### Path E: AI Timeout / Error (fallback, ~2.1s max)
```
...Path D, nhưng OpenAI timeout hoặc error
→ dùng cached response nếu có
→ fallback về RuleEngine result
→ log failure reason
```

---

## 3. Model Selection

Model KHÔNG được hardcode. Load từ `Config.plist`.

```swift
enum AIModel: String {
    case gptNano    = "gpt-4o-mini"     // default MVP
    case gptMini    = "gpt-4o-mini"     // same for now
    case gptFull    = "gpt-4o"          // future
}
```

### Selection Logic

| Condition | Model | Lý do |
|-----------|-------|-------|
| 1 issue, scene known | `gpt-4o-mini` | Simple coaching, cheap |
| 2–3 issues, scene known | `gpt-4o-mini` | Still structured output |
| Scene unknown + complex | `gpt-4o-mini` | MVP: always nano |
| Creative pose variation (V1) | `gpt-4o` | Cần reasoning |
| Long coaching session (V2) | `claude-sonnet-4-6` | Context retention |

**MVP rule:** luôn dùng `gpt-4o-mini`. Model routing chuẩn bị cho V1.

### Config Structure (`Config.plist`)
```xml
<key>AI_MODEL_DEFAULT</key>
<string>gpt-4o-mini</string>
<key>AI_MODEL_COMPLEX</key>
<string>gpt-4o-mini</string>
<key>USE_MOCK_AI</key>
<true/>
<key>AI_THROTTLE_SECONDS</key>
<integer>3</integer>
<key>AI_TIMEOUT_SECONDS</key>
<real>2.0</real>
```

---

## 4. Prompt Templates

6 templates theo scene. `PromptBuilder` chọn template dựa trên `SceneContext`.

### Template 1 — Outdoor (default)

```
System:
Bạn là nhiếp ảnh gia AI chuyên nghiệp. Hướng dẫn người dùng chụp ảnh ngoài trời đẹp hơn.
Luôn trả lời bằng tiếng Việt. Ngắn gọn, thân thiện.
Gợi ý tối đa 40 ký tự cho main_cue.
Trả về JSON theo schema chuẩn.

Context: Cảnh ngoài trời, ánh sáng tự nhiên.
Ưu tiên: góc nghiêng người, shadow natural, composition.
```

### Template 2 — Indoor

```
System:
...
Context: Cảnh trong nhà, ánh sáng nhân tạo.
Ưu tiên: tránh backlight, warm tone, distance to subject.
```

### Template 3 — Portrait Focus (V1)

```
System:
...
Context: Chân dung cận cảnh.
Ưu tiên: eye contact, chin angle, shoulder turn, bokeh distance.
```

### Template 4 — Group / Couple (V2)

```
System:
...
Context: Nhiều người trong frame.
Ưu tiên: spacing, height alignment, body language.
```

### Template 5 — Travel / Landmark (V1)

```
System:
...
Context: Du lịch, có background đặc trưng.
Ưu tiên: subject vs landmark balance, rule of thirds, avoid mergers.
```

### Template 6 — Low Light (V1)

```
System:
...
Context: Ánh sáng yếu, ban đêm, trong nhà tối.
Ưu tiên: minimize motion blur, stability cues, exposure recipe.
```

### Template Selection Logic

```swift
func selectTemplate(scene: SceneContext) -> String {
    switch scene {
    case .outdoor: return Template.outdoor
    case .indoor:  return Template.indoor
    case .unknown: return Template.outdoor  // safe default
    }
}
```

---

## 5. Optimized Payload

**Target:** < 300 input tokens, < 120 output tokens.

### Input Payload (User Message)

```json
{
  "scene": "outdoor",
  "pose": "standing",
  "issues": ["chin_down", "left_shoulder_low"],
  "frame_position": "center",
  "person_count": 1
}
```

**Token estimate:** ~60 tokens (input + system prompt ~240 tokens total).

### Token Optimization Rules

| Rule | Lý do |
|------|-------|
| Chỉ gửi `issues` array (IDs, không phải messages) | Tiết kiệm ~30 tokens/request |
| Không gửi confidence scores | Không cần cho coaching |
| Không gửi raw landmark coordinates | Privacy + không cần |
| Dùng issue IDs ngắn (`chin_down` thay vì `chin is lower than shoulders`) | ~5 tokens vs ~15 tokens |
| Scene chỉ `outdoor/indoor/unknown` | 1 token thay vì mô tả dài |
| Không gửi timestamp, device info | Redundant |

### Issue ID → Token Map

| ID | Tokens |
|----|--------|
| `chin_down` | 2 |
| `left_shoulder_low` | 3 |
| `right_shoulder_low` | 3 |
| `torso_facing` | 2 |
| `off_center_right` | 3 |
| `too_far` | 2 |
| `too_close` | 2 |

Worst case: 5 issues = ~15 tokens. Excellent.

### Output Schema

```json
{
  "main_cue": "Ngẩng đầu lên",
  "secondary_cue": "Nhấc vai trái lên",
  "camera_instruction": null,
  "score": 3,
  "feedback": "Tư thế khá ổn, cần điều chỉnh góc cằm.",
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

**Token estimate output:** ~120 tokens. Fits trong một GPT response.

### Validation Rules

```swift
struct ResponseValidator {
    static func validate(_ response: AICoachingResponse) -> Bool {
        guard !response.mainCue.isEmpty else { return false }
        guard response.mainCue.count <= 40 else { return false }
        guard (1...5).contains(response.score) else { return false }
        guard (-1.0...1.0).contains(response.editingRecipe.exposure) else { return false }
        guard (-100...100).contains(response.editingRecipe.contrast) else { return false }
        return true
    }
}
```

---

## 6. Fallback Strategy

3 tiers. App không bao giờ crash hay freeze vì AI.

```
Tier 1 — AI Response (bình thường)
    OpenAI trả về trong < 2s
    → Validate → emit
    → Cache response

Tier 2 — Cached Response (AI chậm / throttle)
    Last valid AI response ≤ 30s tuổi
    → emit cached (stale nhưng acceptable)
    → vẫn gọi AI async, update khi có

Tier 3 — Rule Engine (offline / AI fail)
    RuleEngine result luôn available
    → mainCue = topIssue.message
    → editingRecipe = .neutral (hoặc last cached recipe)
    → score = max(1, 5 - issues.count)

Tier 4 — Default Coaching (Vision fail)
    Không có PoseObservation
    → emit hardcoded "Bước vào khung hình"
    → không hiển thị score
```

### Fallback Decision Tree

```swift
func bestAvailableResponse(
    aiResponse: AICoachingResponse?,
    cachedResponse: AICoachingResponse?,
    ruleResult: RuleEngineResult
) -> AICoachingResponse {
    if let ai = aiResponse, ResponseValidator.validate(ai) {
        return ai                                    // Tier 1
    }
    if let cached = cachedResponse,
       Date().timeIntervalSince(cachedAt) < 30 {
        return cached                               // Tier 2
    }
    return makeFallbackResponse(from: ruleResult)  // Tier 3
}
```

---

## 7. Latency Budget

**Total target: < 1.2 giây** từ khi user điều chỉnh pose đến khi thấy coaching mới.

| Step | Budget | Implementation |
|------|--------|---------------|
| Vision detection | < 100ms | Background actor, Vision Framework |
| Scene classification | < 20ms | CoreML on-device, 1 frame / 5s |
| Rule Engine eval | < 10ms | Pure Swift, no I/O |
| UI update (RuleEngine) | < 16ms (1 frame) | `@MainActor`, no animation delay |
| Prompt build | < 5ms | String interpolation |
| Network RTT | ~400ms | Best case LTE |
| OpenAI inference | ~400ms | gpt-4o-mini fast |
| JSON parse | < 5ms | Codable |
| UI update (AI) | < 16ms | `@MainActor` |
| **Total (Path D)** | **~960ms** | **Under 1.2s target** |

### UX Strategy cho latency

- **Emit RuleEngine result ngay** (< 10ms) → user thấy cue ngay lập tức
- AI response đến sau (~1s) → update cue mượt mà, không flash
- User không bao giờ chờ blank screen

```swift
// Pattern đúng — UX tốt
func process(pose: PoseObservation, scene: SceneContext) async {
    let ruleResult = ruleEngine.evaluate(pose: pose, scene: scene)
    emit(makeFallbackResponse(from: ruleResult))   // NGAY LẬP TỨC

    guard shouldCallAI(ruleResult) else { return }
    let aiResponse = try? await backend.send(request)  // async, không block UI
    if let response = aiResponse { emit(response) }
}
```

---

## 8. Cache Strategy

### Cái gì cache

| Resource | TTL | Storage | Lý do |
|----------|-----|---------|-------|
| AICoachingResponse | 30 giây | In-memory | Tránh duplicate calls cùng pose |
| EditingRecipe | Session | In-memory | Dùng cho fallback |
| SceneContext | 5 giây | In-memory | Scene không đổi nhanh |
| Prompt Templates | App lifetime | Constants | Không thay đổi |
| MockAI responses | N/A | Hardcoded | Dev only |

### Cache Invalidation

```swift
// Cache invalidation conditions:
// 1. Issues thay đổi đáng kể (> 1 issue khác)
// 2. Scene thay đổi
// 3. TTL hết hạn
// 4. User capture (reset session cache)

func shouldInvalidateCache(
    current: RuleEngineResult,
    previous: RuleEngineResult
) -> Bool {
    let currentIDs = Set(current.issues.map(\.id))
    let previousIDs = Set(previous.issues.map(\.id))
    return currentIDs.symmetricDifference(previousIDs).count > 1
}
```

### Throttle vs Cache — quan hệ

```
Throttle: kiểm soát TẦN SUẤT gọi AI (1 req / 3s)
Cache:    lưu trữ KẾT QUẢ AI để dùng khi throttle active

Không phải thay thế nhau — cả hai cùng hoạt động.
```

---

## 9. Observability

Track các metrics này internally. Không expose ra UI. Log trong debug mode only.

```swift
struct OrchestratorMetrics {
    var decisionPath: DecisionPath    // which tier was used
    var executionTimeMs: Double
    var modelUsed: String?
    var cacheHit: Bool
    var retryCount: Int
    var failureReason: String?
    var tokenEstimate: Int?
    var ruleEngineIssueCount: Int
}

enum DecisionPath: String {
    case noPerson           // L1 stop
    case ruleEngineClean    // L3 stop - no issues
    case ruleEngineThrottle // L3 + throttle active
    case aiSuccess          // L5 success
    case aiTimeout          // L5 timeout → L3 fallback
    case aiError            // L5 error → cache or L3
    case offlineMode        // no network → L3
}
```

### Debug Logging (debug builds only)

```swift
#if DEBUG
func logDecision(_ metrics: OrchestratorMetrics) {
    print("[AI] path=\(metrics.decisionPath.rawValue) time=\(metrics.executionTimeMs)ms cache=\(metrics.cacheHit)")
}
#endif
```

---

## 10. Privacy Rules — Enforcement

| Rule | Implementation |
|------|---------------|
| Không gửi ảnh gốc | Payload chỉ có JSON text |
| Không gửi coordinates | PoseObservation → issue IDs chỉ |
| API key không log | Tách riêng khỏi request body |
| Metadata tối thiểu | 5 fields thay vì full context |
| On-device trước | L1 → L2 → L3 đều local |

---

## 11. Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| OpenAI latency > 2s | Medium | Medium | Timeout 2s + Tier 3 fallback |
| OpenAI down | Low | Low | Tier 2/3 fallback — app vẫn hoạt động |
| Rate limit hit | Medium | Medium | Throttle 3s + MockAIClient backup |
| Parse error (bad JSON) | Low | Low | ResponseValidator + fallback |
| Token limit exceeded | Very Low | Low | Payload < 300 tokens — safe margin |
| Cache stale > 30s | Medium | Low | Invalidate + refresh, UX ok |
| Vision low confidence | Medium | Low | Threshold 0.5, skip uncertain landmarks |
| Model deprecated | Low | High | Model name from Config.plist, not hardcoded |

### Token Cost Estimate (MVP)

```
Assumptions:
- 1 demo session = ~10 phút
- AI call mỗi 3s → 200 calls max
- Thực tế throttle + cache hit rate ~60% → ~80 actual AI calls
- Input: ~240 tokens / call
- Output: ~120 tokens / call
- Total: 80 × (240 + 120) = 28,800 tokens

gpt-4o-mini pricing: $0.15/1M input, $0.60/1M output
Input cost:  80 × 240 × $0.15/1M = $0.003
Output cost: 80 × 120 × $0.60/1M = $0.006
Total demo cost: ~$0.01 (1 xu)
```

---

## 12. Implementation Checklist (Dev C)

Những gì cần update trong `AI/AIOrchestrator/AIOrchestrator.swift`:

- [ ] Load config từ `Config.plist` (API key, model name, throttle interval, useMock)
- [ ] `DecisionPath` enum để track execution path
- [ ] `OrchestratorMetrics` struct cho observability
- [ ] `shouldInvalidateCache()` logic
- [ ] `ResponseValidator.validate()` trước khi emit AI response
- [ ] Scene-aware throttle: throttle ngắn hơn khi scene thay đổi
- [ ] Emit RuleEngine result ngay (Tier 3), AI async sau
- [ ] Cache TTL: 30s cho AICoachingResponse, 5s cho SceneContext
- [ ] Debug logging (debug builds only)
- [ ] `USE_MOCK_AI` flag → inject `MockAIClient` hoặc `OpenAIClient`

---

*Spec này là contract cho AIOrchestrator implementation. Mọi thay đổi phải update document này.*
