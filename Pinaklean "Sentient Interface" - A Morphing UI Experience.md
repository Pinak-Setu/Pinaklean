### **Project Brief: Pinaklean "Sentient Interface" - A Morphing UI Experience**

**Vision:** The Pinaklean UI will no longer be a collection of static views. It will be a single, cohesive, and intelligent entity that transforms to guide the user. Our north star is **"Informative Motion"**—every animation must be beautiful, fluid, and, most importantly, communicate the status and flow of the cleaning process. We will use a "morphing" paradigm, where key UI elements transform from one state to another, creating a seamless journey with a strong sense of object permanence.

**Inspirations:** Framer Motion (for physics-based web animations), Rive (for complex stateful animations), and the principles of Google's Material Design 3 (for motion).

**Core Technologies & Concepts:**
*   **SwiftUI:** `matchedGeometryEffect` is paramount for the core morphing transitions.
*   **Animation Physics:** All animations must use `interpolatingSpring` for a natural, responsive feel. Avoid linear or simple ease-in-out curves.
*   **Haptic Feedback:** Synchronize key animations with `CoreHaptics` to make interactions tangible (e.g., a sharp tap on button press, a gentle hum during a process, a satisfying thud on completion).
*   **Rive:** For complex, non-trivial animations like the final cleaning confirmation.

---

### **Aesthetic: "Liquid Glass & Aurora"**

This builds on the existing "FrostCard" design but makes it dynamic.

*   **Color Palette:**
    *   **Primary Action Gradient:** A dynamic, 45-degree animated gradient from **Deep Indigo (`#4F46E5`)** to **Vibrant Cyan (`#22D3EE`)**. This is for all primary interactive elements.
    *   **Success Gradient:** An energetic gradient from **Lime Green (`#84CC16`)** to **Emerald (`#10B981`)**.
    *   **Background Aurora:** The `LiquidGlass` background is now a living element. The blurred, gradient blobs will slowly and subtly drift in a lava-lamp-like motion. During active processes (like a scan), their movement speed and brightness will increase, making the app feel like it's "thinking."

*   **Gradient Borders:** All primary buttons and interactive cards will feature a 1px border that uses a constantly, slowly rotating rainbow gradient (`conicGradient`). On hover or interaction, the rotation speed increases, creating a stunning "chromatic" effect.

---

### **The Animated User Journey: A Scene-by-Scene Breakdown**

#### **Scene 1: The Idle State & The "Heartbeat"**

*   **View:** `ScanView` (Initial State).
*   **The Morphing Element:** The `ActionButton` labeled **"Start Scan."**
*   **Animation Details:**
    1.  **The Heartbeat:** The button is not static. Its background `Primary Action Gradient` has a subtle, slow-pulsing glow animation, like a calm heartbeat. The `conicGradient` on its border rotates slowly.
    2.  **Hover Interaction:** On mouse hover, the heartbeat quickens. The button scales up by 1.05x using a spring animation. The gradient border rotation accelerates. A soft haptic feedback is triggered.

#### **Scene 2: The Metamorphosis (Scan Initiation)**

*   **User Action:** The user clicks the "Start Scan" button.
*   **The Morphing Element:** The `ActionButton`.
*   **Animation Details:**
    1.  **Haptic & Initial Reaction:** On click, a sharp, crisp haptic is fired. The button scales down to 0.95x for a split second before beginning its transformation, giving the click a tangible feel.
    2.  **The Morph:** This is the core animation.
        *   Using `matchedGeometryEffect`, the `ActionButton`'s frame seamlessly expands into the frame of a large `FrostCard` that will dominate the view. The button's corner radius animates from its pill shape to the card's larger radius.
        *   As the frame expands, the "Start Scan" text and icon fade out.
    3.  **Content Transition:** Inside the newly formed card, the `ScanProgressIndicator` and "Scanning..." text fade in with a subtle upward drift. A background visualization appears within the card: a stream of tiny, blurred file-type icons (docs, photos, etc.) flowing from right to left, indicating the scan.
    4.  **System-Wide State Change:** The `Background Aurora` becomes more active, and the `[🔍 Scan]` node of our conceptual pipeline (even if not visible, the state is active) would be triggered.

#### **Scene 3: The Revelation (Scan Completion)**

*   **Process:** The scan progress hits 100%.
*   **The Morphing Element:** The `ScanProgressIndicator` card.
*   **Animation Details:**
    1.  **Completion Flash:** The progress bar animates to full, then flashes brightly with the `Success Gradient`. A multi-tap "success" haptic is fired.
    2.  **Content Morph:**
        *   The progress bar and the stream of file icons fade out.
        *   The "Scanning..." text transforms into "Scan Complete."
        *   The key statistics (`Items Found`, `Total Size`) appear below the title. The numbers don't just fade in; they animate with a "slot machine" effect, quickly rolling up to their final values.
    3.  **The Card Settles:** The card now serves as the `ScanResultsSummary`. A new `ActionButton` ("Review & Clean") fades in at the bottom of the card, already pulsing with the `Primary Action Gradient`.

#### **Scene 4: The Deep Dive (Presenting Results)**

*   **User Action:** User clicks the "Review & Clean" button on the summary card.
*   **The Morphing Element:** The `ScanResultsSummary` card.
*   **Animation Details:**
    1.  **Card to Header:** The summary card animates smoothly to the top of the screen, shrinking and morphing into the permanent `HeaderView` for the results list. The stats it contained might animate to their new positions in the header.
    2.  **Staggered List Animation:** The `ScanItemRow` components for the results list do not appear all at once. They animate in sequentially from the top, each with a slight delay, using a combined fade-in and slide-up-from-bottom effect. This creates a beautiful "cascade" or "waterfall" effect.
    3.  **Row Interaction:** On hover, each `ScanItemRow` lifts slightly (z-axis), gains a soft `Primary Action Gradient` glow, and its `EnhancedSafetyBadge` performs a small, satisfying spin-and-scale animation.

#### **Scene 5: The Finale (The Cleaning Act)**

*   **User Action:** User selects files and clicks the final "Clean Files" `ActionButton`.
*   **Animation Details:**
    1.  **Trigger Rive:** Instead of a simple progress bar, this action triggers a full-screen modal overlay with a dark, blurred version of the main UI in the background.
    2.  **The Vortex (Rive Animation):** In the center of the screen, a beautifully designed Rive animation plays:
        *   The selected file icons are pulled from the background list into a shimmering, energetic vortex.
        *   The vortex spins faster and faster, then implodes.
        *   From the implosion point, a large `Success Gradient` checkmark is drawn dynamically on screen, accompanied by a burst of confetti-like particles.
    3.  **The Aftermath:** The Rive overlay fades out, revealing the `AnalyticsDashboard`. The "Total Cleaned" and "Space Saved" cards are in focus, and their numbers perform the "slot machine" animation to update to their new values. The entire UI then returns to the calm "Heartbeat" state, ready for the next interaction.
