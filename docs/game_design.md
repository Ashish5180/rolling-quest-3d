# Game Design Document: Rolling Quest

## 1. Executive Summary
**Rolling Quest** is a 3D mobile arcade platformer inspired by *Going Balls*. Players navigate a physics-driven rolling sphere across suspended floating tracks filled with ramps, hazards, and collectibles.

## 2. Core Game Loop
1. **Start:** Ball begins automatically accelerating forward along the track.
2. **Navigate:** Player steers laterally via touch swipe or drag to avoid obstacles and stay on course.
3. **Traverse Ramps:** Leverage forward momentum to jump across physical platform gaps.
4. **Collect:** Pick up coins along the optimal racing line.
5. **Win / Fail Condition:**
   - **Win:** Cross the finish gate trigger.
   - **Fail:** Fall off the track or impact fatal obstacles, instantly triggering a fast restart.

## 3. Physics & Mechanics Specifications
- **Ball Mass:** 1.0 kg
- **Ball Radius:** 0.45 m (SphereShape3D)
- **Target Forward Speed:** 10.0 m/s
- **Max Lateral Speed:** 5.0 m/s
- **Friction:** Ball (0.9), Track (1.0)
- **Restitution (Bounciness):** 0.05 (prevents erratic vertical oscillation)
- **Camera Follow:** Fixed-yaw trailing rig with exponential smoothing (lerp).

## 4. Visual & Audio Direction
- **Renderer:** GL Compatibility (Mobile-optimized)
- **Aesthetic:** Clean, vibrant arcade palette with high-contrast hazard indicators and procedural skybox.
- **Lighting:** Single directional sun light with optimized directional shadow mapping.

