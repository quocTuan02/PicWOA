# TECH LEAD — Picwoa MVP

**Role:** Technical Lead + Engineering Manager  
**Horizon:** 4-hour hackathon  
**Team:** 3 Swift Devs + AI Agents (Claude Code, Codex, Cursor)  
**North Star:** Strongest demo, not largest feature set  

---

## 1. Team Assignment

### Dev A — Camera Lead

| | |
|-|-|
| **Owned Features** | DesignSystem, CameraEngine, CameraExperience, PhotoCapture, AppCoordinator |
| **Estimated Workload** | 110 phút code + 30 phút integration |
| **Critical Path** | Phải xong CameraEngine trước 01:00 vì Dev B và Dev C cần sampleBufferStream |
| **Dependencies** | Block: không ai block A. A block: Dev B cần buffer stream, Dev C cần UIImage contract |
| **Risk Level** | Medium — AppCoordinator là điểm hội tụ của toàn bộ app |

**Definition of Done:**
- Camera preview 30 FPS trên device
- `sampleBufferStream` emit data
- `capturePhoto()` trả về `UIImage`
- AppCoordinator wire tất cả modules, full navigation hoạt động

**Nhiệm vụ bổ sung:** Tạo và commit tất cả shared domain models (`PoseObservation`, `AICoachingResponse`, `EditingRecipe`, `CoachingRule`, `SceneContext`) vào `main` lúc **00:25** — trước khi Dev B và Dev C bắt đầu code.

---

### Dev B — Vision Lead

| | |
|-|-|
| **Owned Features** | VisionEngine, PoseCoaching, SceneAnalysis, RuleEngine |
| **Estimated Workload** | 90 phút code + 20 phút tune + 30 phút integration |
| **Critical Path** | RuleEngine phải xong trước 02:00 vì Dev C cần `RuleEngineResult` để test AIOrchestrator |
| **Dependencies** | Cần shared models từ Dev A (00:25). Cần device thật để test Vision |
| **Risk Level** | Medium — Vision không chạy trên simulator |

**Definition of Done:**
- `VisionEngine` emit `PoseObservation` real-time khi có người trong frame
- `RuleEngine` evaluate đúng 8 rules, pass unit tests
- `readyToCapture = true` khi không có issues

**Lưu ý:** Test Vision trên device thật ngay từ 00:30, không đợi đến integration.

---

### Dev C — AI Lead

| | |
|-|-|
| **Owned Features** | PromptBuilder, OpenAIClient, AIOrchestrator, LiveOverlay, PhotoEditing, PhotoReview |
| **Estimated Workload** | 125 phút code + 30 phút integration |
| **Critical Path** | MockAIClient phải xong trước 01:00 để test pipeline mà không cần real API |
| **Dependencies** | Cần shared models từ Dev A (00:25). Cần `RuleEngineResult` contract từ Dev B (không cần implementation) |
| **Risk Level** | High — nhiều modules nhất, nhiều integration points |

**Definition of Done:**
- `MockAIClient` return valid `AICoachingResponse` bằng tiếng Việt
- `CoachingCard` hiển thị trên camera screen
- `ReviewScreen` có score + before/after + save
- `CoreImageProcessor` apply visible change

**Chiến thuật:** Build theo thứ tự `MockAI → Overlay → CoreImage → Review`. Không build real OpenAI trước khi Overlay chạy được.

---

## 2. AI Agent Assignment

| Feature | Preferred AI | Lý do | Review Level |
|---------|-------------|-------|-------------|
| DesignSystem tokens | **Codex** | Boilerplate constants, không cần reasoning | Spot check naming |
| DesignSystem components | **Claude Code** | Cần consistent API design | Review props + states |
| CameraEngine | **Claude Code** | AVFoundation + Swift 6 actor + async stream — subtleties quan trọng | **Required** — device test |
| CameraExperience UI | **Cursor** | SwiftUI layout nhanh | Visual check |
| VisionEngine | **Claude Code** | Vision API có nhiều quirks, confidence thresholds, coordinate spaces | **Required** — device test |
| PoseCoaching (math) | **Codex** | Geometry computation rõ ràng, deterministic | Unit test pass |
| SceneAnalysis | **Codex** | Heuristic đơn giản | Test indoor/outdoor |
| RuleEngine | **Claude Code** | Logic phức tạp, 8 rules, edge cases, phải correct | **Required** — all rules verified |
| PromptBuilder | **Codex** | String template + struct mapping | Verify tiếng Việt |
| OpenAIClient | **Claude Code** | Network security, error handling, API key management | **Required** — no key leak |
| MockAIClient | **Codex** | Trivial implementation, return canned data | Verify schema match |
| AIOrchestrator | **Claude Code** | Throttle + cache + fallback — concurrent logic | **Required** |
| LiveOverlay UI | **Cursor** | SwiftUI animation + ZStack overlay | Visual check |
| PhotoCapture | **Codex** | Thin wrapper | Capture returns image |
| CoreImageProcessor | **Codex** | Filter chain công thức rõ ràng | Visible output diff |
| PhotoReview UI | **Cursor** | Layout + BeforeAfter component | Visual check |
| AppCoordinator | **Claude Code** | DI wiring, navigation, Swift 6 — dễ sai | **Required** — full build |

**Hướng dẫn dùng AI:**
- Khi dùng Claude Code / Codex: paste interface contract từ `BUILD_EXECUTION_PLAN.md` vào prompt trước
- Không để AI tự chọn model structure — luôn cung cấp struct definitions từ shared models
- Sau khi AI generate: check imports, check thread safety, check không tự thêm dependency ngoài spec

---

## 3. Git Strategy

### Repository Structure

```
main                          ← production-ready at all times
├── feature/camera      ← Dev A: Camera + AppCoordinator
├── feature/vision      ← Dev B: Vision + RuleEngine
└── feature/ai-coaching          ← Dev C: AI + Overlay + Review
```

### Branch Rules

| Rule | Detail |
|------|--------|
| `main` | Luôn build được. Chỉ merge khi checkpoint pass |
| Feature branches | Short-lived — tối đa 90 phút trước khi merge |
| Shared models | Commit thẳng vào `main` bởi Dev A lúc 00:25 |
| Mỗi branch = 1 owner | Không 2 người cùng push vào 1 branch |
| Không rebase | Chỉ `git merge main` để sync, tránh mất code |
| Commit nhỏ, thường | Mỗi module hoàn thành = 1 commit |

### Merge Order

```
Shared Models (Dev A → main, 00:25)
        │
        ▼
DesignSystem (Dev A → main, 00:30)
        │
        ├──────────────────────────────────┐
        ▼                                  ▼
CameraEngine (Dev A, 01:00)         VisionEngine (Dev B, 01:10)
        │                                  │
        ▼                                  ▼
CameraExperience (Dev A, 01:25)     RuleEngine (Dev B, 02:00)
        │                                  │
        │    ┌─────────────────────────────┘
        │    │
        │    │   OpenAIClient+Mock (Dev C, 01:00)
        │    │          │
        │    │   AIOrchestrator (Dev C, 01:30)
        │    │          │
        │    │   LiveOverlay (Dev C, 02:00)
        │    │          │
        ▼    ▼          ▼
        INTEGRATION MERGE (02:30)
              │
              ▼
        AppCoordinator (Dev A, 03:00)
              │
              ▼
        DEMO BUILD (03:15)
```

**Tại sao thứ tự này:**
- Shared Models trước vì cả 3 devs import
- CameraEngine trước VisionEngine vì Vision subscribe buffer stream
- RuleEngine trước AIOrchestrator vì Orchestrator cần `RuleEngineResult`
- AppCoordinator cuối vì nó wire tất cả

---

## 4. Folder Ownership

| Path | Owner | Notes |
|------|-------|-------|
| `App/` | Dev A | Entry point + AppCoordinator — touch cuối cùng |
| `Features/CameraExperience/` | Dev A | Full ownership |
| `Features/PhotoCapture/` | Dev A | Full ownership |
| `Features/PoseCoaching/` | Dev B | Full ownership |
| `Features/SceneAnalysis/` | Dev B | Full ownership |
| `Features/LiveOverlay/` | Dev C | Full ownership |
| `Features/PhotoReview/` | Dev C | Full ownership |
| `Features/PhotoEditing/` | Dev C | Full ownership |
| `Core/CameraEngine/` | Dev A | Full ownership |
| `Core/VisionEngine/` | Dev B | Full ownership |
| `Core/DesignSystem/` | Dev A (lock sau 00:30) | Sau 00:30: read-only cho tất cả |
| `Core/Extensions/` | Shared | Ai cũng có thể thêm, tránh conflict bằng file riêng |
| `AI/RuleEngine/` | Dev B | Full ownership |
| `AI/PromptBuilder/` | Dev C | Full ownership |
| `AI/OpenAIClient/` | Dev C | Full ownership |
| `AI/AIOrchestrator/` | Dev C | Full ownership |
| `Resources/` | Dev A (setup) | Assets + Localizable.strings |

**Ground Rules:**
- Không chỉnh file trong folder của người khác mà không hỏi
- Nếu cần share logic → đặt vào `Core/Extensions/` với file riêng
- `Config.plist` trong `.gitignore` — mỗi dev tự tạo local

---

## 5. Minute-by-Minute Execution Plan

### 00:00 – 00:30 | SETUP (Tất cả làm song song)

| Người | Việc làm |
|-------|---------|
| **Dev A** | Tạo Xcode project (SwiftUI, iOS 17+, Swift 6) → tạo 3 feature branches → build shared domain models → commit vào `main` → tạo `Config.plist.template` |
| **Dev B** | Clone repo → checkout `feature/vision` → pull shared models → setup `Core/VisionEngine/` skeleton → đọc Vision Framework API |
| **Dev C** | Clone repo → checkout `feature/ai-coaching` → pull shared models → setup `AI/` folder skeleton → chuẩn bị prompt template |

**Checkpoint 00:30:** `⌘B` pass trên cả 3 máy, shared models có mặt.

---

### 00:30 – 01:30 | PARALLEL BUILD (3 streams độc lập)

| Người | Việc làm | Target |
|-------|---------|--------|
| **Dev A** | `CameraEngine` (AVFoundation session + buffer stream + capture) → `CameraExperience` (preview UI + capture button) | Camera chạy 30 FPS trên device |
| **Dev B** | `VisionEngine` (body pose request + stream) → `PoseCoaching` (angle calculation) → bắt đầu `RuleEngine` | PoseObservation stream có data |
| **Dev C** | `OpenAIClient` + `MockAIClient` → `PromptBuilder` → `CoreImageProcessor` | MockAI return response + CoreImage chạy |

**Sync lúc 01:00:** Nhanh 5 phút — ai xong gì, ai cần gì, có bị block không.

---

### 01:30 – 02:30 | FEATURE COMPLETION

| Người | Việc làm | Target |
|-------|---------|--------|
| **Dev A** | `PhotoCapture` wrapper → sketch `AppCoordinator` skeleton → sẵn sàng integration | Capture returns UIImage |
| **Dev B** | Hoàn thành `RuleEngine` (8 rules + unit tests) → `SceneAnalysis` → commit | RuleEngineResult pass all unit tests |
| **Dev C** | `AIOrchestrator` (throttle + fallback) → `LiveOverlay` (CoachingCard + Arrow) → `ReviewScreen` | Overlay visible với mock data |

**Sync lúc 02:00:** Review interface contracts — Dev C báo Dev B "em cần `RuleEngineResult` stream format này" → confirm không mismatch.

---

### 02:30 – 03:15 | INTEGRATION

| Người | Việc làm |
|-------|---------|
| **Dev A** | Merge `feature/vision` và `feature/ai-coaching` vào `main` → resolve conflicts (nếu có) → wire `AppCoordinator` |
| **Dev B** | Hỗ trợ Dev A resolve conflicts phần Vision → test VisionEngine với camera thật trong integrated build |
| **Dev C** | Test LiveOverlay với real camera feed → test ReviewScreen với real capture → swap MockAI → real OpenAI nếu có API key |

**Hard rule:** Nếu lúc 02:30 một module chưa xong → merge phần đã xong, dùng mock cho phần còn thiếu. Demo không được chờ.

---

### 03:15 – 03:45 | BUG FIX + POLISH

- Chạy demo flow 11 bước → log bug
- Mỗi người fix bug trong feature của mình
- UI polish: spacing, loading states, text tiếng Việt check
- Test offline mode (tắt wifi → overlay vẫn hoạt động)

---

### 03:45 – 04:00 | DEMO REHEARSAL

- Chạy demo 2 lần full
- Xác định điểm dừng nếu có bug live
- Tắt Xcode console trước demo (ẩn log)
- Chuẩn bị câu trả lời cho Q&A về tech stack

---

## 6. Merge Plan

```
1. Shared Models → main (00:25)
   └─ Lý do: Unblock tất cả devs

2. DesignSystem → main (00:30)
   └─ Lý do: Components dùng trong CameraExperience, Overlay, Review

3. CameraEngine → main (01:00)
   └─ Lý do: VisionEngine cần sampleBufferStream để test

4. VisionEngine + RuleEngine → main (02:00)
   └─ Lý do: AIOrchestrator cần RuleEngineResult protocol

5. OpenAIClient + AIOrchestrator + LiveOverlay → main (02:15)
   └─ Lý do: Cần test với camera thật trước integration cuối

6. Tất cả feature branches → main (02:30)
   └─ Lý do: Integration window

7. AppCoordinator + final wiring → main (03:00)
   └─ Lý do: Cuối cùng sau khi tất cả modules ổn định
```

---

## 7. Integration Checklist

Chạy checklist này trước mỗi merge vào `main`:

- [ ] `⌘B` build thành công, không có error
- [ ] Không có compiler warning mới (đặc biệt Swift 6 concurrency)
- [ ] Không có model struct nào bị duplicate với version trong `main`
- [ ] Không có protocol nào bị rename mà chưa update callers
- [ ] Navigation flow không bị broken (test manually)
- [ ] Không import framework ngoài spec (không dùng Combine, không dùng RxSwift)
- [ ] `Config.plist` không có trong commit (kiểm tra `git status`)
- [ ] Không có `print()` debug statement nào hardcode sensitive data

---

## 8. Definition of Done

| Feature | Code Complete | Build OK | Tests Pass | Integrated | Demo Ready |
|---------|--------------|----------|------------|------------|------------|
| DesignSystem | Tokens + 3 components | ✓ | Visual check | Imported in features | Looks right on device |
| CameraEngine | Session + stream + capture | ✓ | Device test | VisionEngine subscribed | 30 FPS stable |
| CameraExperience | Screen + toolbar + button | ✓ | Visual | Navigation works | Full-screen, no clutter |
| VisionEngine | Pose + person detection | ✓ | Mock buffer test | Camera subscribed | Real-time on device |
| PoseCoaching | Angles + positions | ✓ | Unit tests | RuleEngine consumes | Data accurate |
| SceneAnalysis | indoor/outdoor | ✓ | Basic test | AIOrchestrator receives | Returns context |
| RuleEngine | 8 rules + priority | ✓ | **All unit tests** | Orchestrator subscribed | Rules fire correctly |
| PromptBuilder | JSON payload | ✓ | Schema test | Orchestrator uses | tiếng Việt output |
| OpenAIClient | HTTP + mock | ✓ | Mock returns data | Orchestrator uses | Response in <1s |
| AIOrchestrator | Throttle + fallback | ✓ | Throttle test | Overlay subscribed | No duplicate calls |
| LiveOverlay | Card + arrow | ✓ | Visual | On CameraScreen | Updates real-time |
| PhotoCapture | UIImage returned | ✓ | Capture test | Review receives | No lag |
| PhotoEditing | CIFilter chain | ✓ | Pixel diff test | Review uses | Visible change |
| PhotoReview | Score + B/A + save | ✓ | Visual | Navigation back | Photo in Photos |
| AppCoordinator | DI + navigation | ✓ | Full flow test | All features wired | End-to-end clean |

---

## 9. Risk Register

| Risk | Impact | Likelihood | Mitigation | Fallback |
|------|--------|------------|------------|---------|
| Vision chỉ chạy trên device | High | Certain | Dev B có device riêng, test sớm | Mock PoseObservation static data |
| OpenAI rate limit / key unavailable | High | Medium | MockAIClient luôn sẵn sàng | Demo với Mock hoàn toàn — không ai biết |
| Dev C overload (6 modules) | High | Medium | Ưu tiên: Mock → Overlay → Review. Skip real AI nếu cần | Overlay từ RuleEngine đủ để demo |
| Interface mismatch lúc 02:30 | High | Medium | Contracts locked 00:30, sync call lúc 02:00 | 30 phút buffer để fix |
| Merge conflict lớn | Medium | Medium | Micro-integration mỗi 30 phút, folder ownership strict | Dev A resolve, 15 phút buffer |
| Camera permission bị deny | Medium | Low | Handle gracefully với guide screen | Relaunch app, re-request |
| Swift 6 concurrency error | Medium | Medium | Enable từ đầu, dùng `@MainActor` và actor đúng chỗ | Tạm thời `nonisolated(unsafe)` để unblock |
| Demo device khác test device | Low | Low | Test trên đúng device demo sớm | Adaptive layout |

---

## 10. Communication Plan

### Sync Calls (tại chỗ hoặc Slack)

| Time | Duration | Format | Agenda |
|------|----------|--------|--------|
| 00:00 | 10 min | Standup | Phân chia task, confirm contracts, setup |
| 01:00 | 5 min | Quick check | Ai xong gì, ai bị block, confirm không mismatch |
| 02:00 | 10 min | Interface sync | Dev C confirm RuleEngineResult format với Dev B |
| 02:30 | 15 min | Integration kickoff | Merge, assign conflict resolver, test plan |
| 03:15 | 5 min | Demo dry-run 1 | Chạy flow, log bugs |
| 03:45 | 15 min | Demo rehearsal | 2 lần full, xác định script |

### Escalation

```
Bug trong feature của mình → tự fix
Bug ở ranh giới 2 features → 2 owners ngồi lại, 10 phút max
Merge conflict → Dev A quyết định
Architecture question → Tech Lead quyết định ngay, không debate
```

### Decision-Making

| Quyết định | Ai quyết | Thời gian tối đa |
|-----------|---------|-----------------|
| UI style nhỏ | Owner của feature | 2 phút |
| Interface contract thay đổi | Phải hỏi team | 5 phút |
| Feature bị cắt khỏi demo | Tech Lead | Ngay lập tức |
| Switch Mock → Real AI | Tech Lead | Tại 03:00 sau integration |

**Rule của Tech Lead:** Nếu debating > 3 phút → chọn option đơn giản hơn, làm tiếp. Không có quyết định nào quan trọng hơn việc demo chạy được.

---

## 11. Demo Readiness Checklist

### Camera & Vision
- [ ] App launch: camera preview trong ≤ 2 giây
- [ ] "Bước vào khung hình" khi không có người
- [ ] Skeleton / overlay xuất hiện khi bước vào
- [ ] Coaching cue bằng tiếng Việt, đúng với tư thế
- [ ] Cue thay đổi khi thay đổi tư thế
- [ ] "Hoàn hảo! Chụp ngay" khi tư thế chuẩn

### Capture & Review
- [ ] Capture button tap → không lag
- [ ] Review screen xuất hiện ≤ 1 giây
- [ ] Score hiển thị (★★★★☆)
- [ ] Feedback text tiếng Việt
- [ ] Before/After visible và khác nhau
- [ ] "Lưu ảnh" → ảnh trong Photos app
- [ ] "Chụp lại" → về camera, không crash

### Resilience
- [ ] Tắt wifi → overlay vẫn chạy (RuleEngine fallback)
- [ ] Không có loading spinner nào bị treo
- [ ] Không crash trong 3 lần chạy full flow

### Visual
- [ ] Dark theme nhất quán
- [ ] Không có text bị clip
- [ ] Không có button nào bị che
- [ ] Không có Xcode console logs xuất hiện khi demo

---

## 12. Future Scaling Strategy

### Hackathon MVP → Production MVP

**Không cần refactor lớn** vì feature-first architecture đã chuẩn bị sẵn:

| Việc cần làm | Effort | Lý do đơn giản |
|-------------|--------|----------------|
| Replace MockAIClient bằng real OpenAI | 1 ngày | Chỉ swap 1 implementation của `AIBackendProtocol` |
| Add SwiftData persistence | 2 ngày | `PhotoSaver` extend để lưu metadata, không đụng Features |
| Add Analytics | 1 ngày | Inject `AnalyticsService` vào ViewModels qua DI |
| Improve error handling + logging | 1 ngày | Infrastructure layer, không đụng business logic |
| App Store submission | 3 ngày | Privacy manifest, screenshots, review |

### Production MVP → V1

| Feature | Plug-in Point |
|---------|--------------|
| Better scene classification (10+ categories) | Replace `SceneClassifierService` implementation — protocol unchanged |
| Composition scoring | Add `Features/CompositionGuide/` — zero conflict với existing features |
| Auto Capture | Extend `AIOrchestrator` — emit `autoCaptureTrigger` event |
| Personalized coaching | Extend `PromptBuilder` với user history context |
| Offline CoreML model | Add `OnDeviceCoreMLBackend: AIBackendProtocol` — swap trong `AIOrchestrator` |

### V1 → V2

| Feature | Plug-in Point |
|---------|--------------|
| Group/couple coaching | Extend `VisionEngine` multi-person detection, new `GroupCoaching` feature |
| Voice coaching | Add `VoiceCoachingService` in `LiveOverlay` feature |
| Community pose library | New `Features/PoseLibrary/` — standalone |
| Fine-tuned on-device model | Replace `AIBackendProtocol` implementation |

**Invariants — không bao giờ thay đổi:**
- Feature-first folder structure
- Protocol-based AI backend (dễ swap)
- Domain models tách khỏi framework
- Privacy rule: không upload raw image

---

*Tech Lead document này là operational guide cho hackathon. Không design lại architecture. Focus: deliver.*
