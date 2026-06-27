# MVP_SPEC.md

# PICWOA MVP Specification (Hackathon Edition)

**Version:** 0.1

**Goal:** Build an impressive end-to-end AI Photography Coach demo within **4 hours** using **3 Developers + Codex/Claude Code**.

---

# Vision

Picwoa is an AI-powered photography assistant that provides real-time guidance to help users take better photos.

The MVP focuses on one complete user journey:

> Open Camera → Live AI Coaching → Ready-to-Capture Cue → Capture → Auto Enhance → Save

Instead of trying to build many features, the MVP should excel at the moment before the shutter is pressed: helping the subject and photographer know exactly what to adjust, then saying when to capture.

APP SỬ DỤNG 100% TIẾNG VIỆT

---

# Success Criteria

By the end of the hackathon, users should be able to:

* Open the camera.
* Stand in front of the camera.
* Receive real-time pose guidance.
* Adjust until the app says the photo is ready to capture.
* Capture a photo.
* Apply automatic color adjustments.
* Save the final image.

If this flow works smoothly, the MVP is considered successful.

---

# User Flow

```text
Launch App
      │
      ▼
Live Camera Preview
      │
      ▼
Person Detection
      │
      ▼
Pose Detection
      │
      ▼
Scene Detection
      │
      ▼
Rule Engine Analysis
      │
      ▼
AI Coaching Suggestion
      │
      ▼
Live Overlay
      │
      ▼
User Adjusts Pose
      │
      ▼
Ready-to-Capture Cue
      │
      ▼
Capture Photo
      │
      ▼
Post-Capture Result
      │
      ▼
Apply Editing Recipe
      │
      ▼
Save Photo
```

---

# MVP Features

## 1. Live Camera

### Goal

Display a real-time camera preview.

### Technology

* AVFoundation
* SwiftUI

### Deliverables

* Camera Preview
* Capture Button
* Smooth 30 FPS preview

---

## 2. Person Detection

### Goal

Detect whether a person is inside the frame.

### Technology

Vision Framework

### Output

```swift
PersonDetected = true / false
```

If no person is detected:

```
Move into frame
```

---

## 3. Pose Detection

### Goal

Estimate body landmarks.

### Technology

Vision Human Body Pose

### Required Landmarks

* Head
* Neck
* Left Shoulder
* Right Shoulder
* Hip
* Knee
* Foot

No custom ML model required.

---

## 4. Scene Detection

### MVP Scope

Only detect:

* Indoor
* Outdoor

Optional if time allows:

* Cafe
* Street
* Beach

---

## 5. Rule Engine

The Rule Engine performs deterministic analysis before calling any AI.

Examples:

| Condition           | Suggestion          |
| ------------------- | ------------------- |
| Chin Down           | Lift your chin      |
| Left Shoulder Low   | Raise left shoulder |
| Torso Facing Camera | Rotate body 15°     |
| Body Centered       | Move slightly right |

No AI required.

---

## 6. AI Coaching

Only send structured metadata.

Example payload:

```json
{
  "scene": "outdoor",
  "pose": "standing",
  "issues": [
    "left shoulder low",
    "chin down"
  ]
}
```

Expected response:

```json
{
  "main_cue":"Xoay vai nhẹ sang trái",
  "secondary_cue":"Nâng cằm lên một chút",
  "camera_instruction":"Lùi camera ra một bước",
  "readiness":"improving",
  "editing_recipe":{
      "contrast":10,
      "temperature":4
  }
}
```

Never upload the original image during MVP.

---

## 7. Live Overlay

Display only:

* Direction arrows
* One primary coaching message
* Optional secondary refinement only when it does not distract from the primary cue
* Ready-to-capture cue when the pose is good enough

Example:

```
← Xoay vai nhẹ sang trái
```

When ready:

```
✓ Hoàn hảo! Chụp ngay
```

No animation required.

---

## 8. Capture Photo

Use AVFoundation.

Output:

```
UIImage
```

---

## 9. Post-Capture Result

After capture display:

```
Đã chụp xong

Đã áp dụng tinh chỉnh ánh sáng

Lưu ảnh
```

The post-capture screen confirms the result and lets the user save or retake. It should not become the main coaching surface. Any improvement cue must come from the live coaching step before capture.

---

## 10. Auto Editing

Use Core Image.

Apply values returned by AI:

* Exposure
* Contrast
* Highlights
* Shadows
* Temperature
* Vibrance

No predefined filters.

---

# MVP Architecture

```text
Camera
    │
    ▼
Vision
    │
    ▼
Rule Engine
    │
    ▼
AI Orchestrator
    │
    ▼
Prompt Engine
    │
    ▼
OpenAI API (or Mock)
    │
    ▼
Response Engine
    │
    ▼
Overlay
```

---

# Module Breakdown

## Camera Module

Responsibilities

* Camera Preview
* Capture
* Image Output

---

## Vision Module

Responsibilities

* Person Detection
* Pose Detection

---

## Rule Engine

Responsibilities

* Detect pose issues
* Generate deterministic coaching

---

## AI Module

Responsibilities

* Prompt Engine
* AI Orchestrator
* OpenAI Service
* Response Parser

---

## Overlay Module

Responsibilities

* Draw arrows
* Display coaching text

---

## Review Module

Responsibilities

* Show captured result
* Show edited image
* Apply Core Image recipe
* Save final image

---

# Team Assignment

## Developer A

### Camera Team

Responsible for:

* Camera Preview
* Capture
* Camera Permissions
* Image Output

---

## Developer B

### Vision Team

Responsible for:

* Person Detection
* Pose Detection
* Rule Engine

---

## Developer C

### AI Team

Responsible for:

* Prompt Engine
* OpenAI Integration
* Overlay
* Post-Capture Result
* Core Image

---

# Hackathon Timeline (4 Hours)

## 00:00 – 00:30

* Repository Bootstrap
* Xcode Setup
* Camera Running
* Git Branches Created

---

## 00:30 – 01:30

Parallel Development

Developer A

* Camera

Developer B

* Vision

Developer C

* AI Module

---

## 01:30 – 02:30

Feature Completion

* Overlay
* Prompt
* Capture
* Result Screen

---

## 02:30 – 03:15

Integration

* Merge
* Resolve Interfaces
* Build Verification

---

## 03:15 – 04:00

Demo Preparation

* UI Polish
* Bug Fix
* Test on Physical Device
* Demo Rehearsal

---

# Out of Scope (Not for MVP)

The following features are intentionally excluded:

* User Authentication
* Firebase
* Supabase
* SwiftData
* Cloud Sync
* Favorites
* History
* Pose Library
* Scene Classification (20+ categories)
* AI Score Dashboard
* Analytics
* Social Sharing
* Premium Subscription
* Multi-language
* Offline ML Training
* Community Features

---

# Demo Script

1. Launch the app.
2. Camera opens immediately.
3. User stands in front of the camera.
4. Vision detects the person and body pose.
5. Overlay displays one real-time coaching cue.
6. User adjusts their pose.
7. Overlay displays **"Hoàn hảo! Chụp ngay"** when ready.
8. Tap **Capture**.
9. Core Image automatically applies the recommended editing recipe.
10. Display the captured/edited result.
11. Save the final photo.

---

# Demo Success Checklist

* Camera launches successfully.
* Person detection works.
* Pose detection updates in real time.
* Rule Engine generates meaningful coaching.
* AI (or mock API) returns a coaching response.
* Overlay updates correctly.
* Ready-to-capture cue appears when there are no blocking pose issues.
* Capture succeeds.
* Post-capture result screen appears.
* Core Image editing recipe is applied.
* Save photo works.
* No crashes during the demo.

---

# Future Roadmap

## MVP

* Camera
* Pose Detection
* Rule Engine
* AI Coaching
* Overlay
* Ready-to-Capture Cue
* Capture
* Core Image Recipe
* Save

## V1

* Better Scene Detection
* Multiple Pose Templates
* Pose History
* Favorites
* AI Scoring
* Offline Coaching

## V2

* Multi-person Coaching
* Couple & Family Modes
* Video Guidance
* Voice Coaching
* Personalized AI Coach
* Community Pose Library
* Fine-tuned On-device ML Models
* Full Apple Intelligence Integration
