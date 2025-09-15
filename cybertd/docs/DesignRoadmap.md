# CyberTD — Design Roadmap (Sept 15, 2025)

This document captures the current design direction and next steps for CyberTD. It’s a working plan we’ll evolve as we build.

## New Towers (High-Fun Concepts)

1. Tesla Chain Tower
- Chains lightning to 3–5 targets; damage falloff per jump (100% → 70% → 40%).
- Upgrades: more jumps, chance to stun, longer chain range, arc visual polish.

2. Time Warp Tower
- Area bubble slows enemies to 25%; active pulse can push enemies back along path for ~2s.
- Upgrades: bigger radius, stronger slow, shorter cooldown on pulse.

3. Drone Hive
- Spawns autonomous drones (3–5) that hunt targets.
- Upgrades: more drones, faster return/refuel, focus-fire command.

4. Black Hole Generator
- Charges, then pulls enemies inward; detonates for heavy AoE damage.
- Upgrades: stronger pull, shorter charge, residual DoT field.

5. Laser Wall Tower
- Links with another Laser Wall to form a damaging beam wall.
- Upgrades: longer link range, higher DPS, multi-link.

6. Support Beacon
- Non-damage tower that buffs nearby towers (modes: Fire Rate, Damage, Range).
- Upgrades: stronger buffs, larger aura, mode automation.

## Enemy Roster

- Grunt: baseline.
- Scout: 2x speed, 0.5x HP.
- Heavy: 3x HP, 0.5x speed, armor mitigates flat damage.
- Shielder: projects temporary shield to allies.
- Cloaker: 2s visible / 1s invisible cycles; untargetable while cloaked.
- Regenerator: heals 5% HP/s out of combat.
- Splitter: spawns 3 small units on death.
- EMP Unit: on death disables towers nearby for 2s.
- Teleporter: blinks 2 tiles forward every 3s.
- Boss: Titan—huge HP, phases, summons minions.

## Visual Upgrades

- Shader FX: glow/bloom, chromatic aberration bursts, distortion (black hole), heat haze.
- Particles: muzzle flash, impact sparks, enemy death debris, electric arcs, smoke.
- Lighting: short-lived light pulses on shots/explosions, neon accents.
- Juice: screen shake on big events, slow-mo on boss kill, hit-stop frames, damage numbers.

## 10 Map Concepts

1. Training Grounds — simple S-curve; 15 build spots; tutorial beats.
2. Crossroads — X-shaped dual entry merging to one exit; contested center.
3. The Spiral — spiral into center; limited inner spots.
4. Twin Paths — two parallel lanes to defend simultaneously.
5. Boss Arena — short path, many spots; first boss showcase.
6. Maze Runner — labyrinth; enemies choose shortest path dynamically.
7. Island Defense — core center; four entry points.
8. The Gauntlet — long narrowing path; endurance.
9. Teleport Chaos — telepads reroute paths unpredictably.
10. Final Stand — evolving map with phase changes; multi-boss finale.

## Step-by-Step Plan

Phase 1: Audio & Juice
1) SFX wiring (shots, hits, deaths, UI). 2) Screen shake manager. 3) Damage numbers. 4) Basic particles.

Phase 2: Enemy Variety
5) Enemy base refactor. 6) Implement 5 archetypes. 7) Wave data editor. 8) Balance pass.

Phase 3: New Towers
9) Tesla Chain. 10) Time Warp. 11) Drone Hive. 12) Support Beacon. 13) Balance and combos.

Phase 4: Visual Revolution
14) Shaders and lighting. 15) Particle passes. 16) UI motion polish.

Phase 5: Level Design
17) Level loader. 18) Build Maps 1–3. 19) Maps 4–6 + boss. 20) Maps 7–9. 21) Map 10 finale.

Phase 6: Meta & Polish
22) Save/Load. 23) Persistent upgrades. 24) Achievements. 25) Leaderboards. 26) Final balance/bugs.

## Quick Wins (Today)
- Damage numbers with pooling.
- Impact/muzzle particles.
- Speed control (1x/2x/3x).

