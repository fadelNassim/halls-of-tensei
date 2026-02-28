# Night Cathedral — Gameplay Design Document

## Overview

**Night Cathedral** is a 2D isometric roguelite with SMT-inspired demon negotiation and fusion mechanics. Each run takes place in a procedurally varied cathedral dungeon where the player combats, negotiates with, and recruits demons. Between runs, the player fuses demons in a hub to build a permanent roster.

---

## Core Pillars

1. **Negotiation over annihilation** — Weakened demons can be talked into joining; killing every enemy is suboptimal.
2. **Alignment duality** — Player's Law/Chaos alignment affects recruitment odds, fusion results, and unlock conditions.
3. **Fusion permanence** — Fused demons persist across runs, creating a meta-progression loop.
4. **Roguelite tension** — Each run is finite and lethal. Death resets the current run but not the roster or fusion points.

---

## Systems

### 1. Alignment System (`scripts/systems/alignment.gd`)

The player maintains a scalar alignment value ranging from **−100 (full Chaos)** to **+100 (full Law)**.

| Range        | Label   |
|--------------|---------|
| ≥ 45         | Law     |
| −45 to 44    | Neutral |
| ≤ −45        | Chaos   |

**Shifts:** Recruiting a Law demon shifts alignment positive; recruiting a Chaos demon shifts negative. The magnitude is `alignment_bias × 10`.

**Effect on recruitment:** The alignment modifier formula:
```
modifier = (1 - |player_norm - demon_val|) × alignment_bias
```
where `player_norm = alignment_value / 100` and `demon_val` is −1, 0, or +1.

---

### 2. Negotiation System (`scripts/systems/negotiation.gd`)

When a demon's HP falls to ≤ 25% of max, it enters the **Negotiateable** state. The player presses `F` (interact) within 80 pixels to open the negotiation dialog.

**Base recruit chance** = `demon.recruit_rules.base_chance + charisma × 0.01 + alignment_modifier`

**Player actions:**

| Action       | Formula                              | Notes                              |
|--------------|--------------------------------------|------------------------------------|
| Appeal       | `+charisma × 0.02`                   | Always positive                    |
| Threaten     | `+(strength − demon.atk) × 0.015`   | Can be negative vs. strong demons  |
| Offer Item   | `+item_value` (fixed 0.15 default)   | Consumes item from inventory       |

After one action, the system **resolves**: a random float [0, 1] is compared against the final chance.

- **Success:** demon joins roster; player gains `rank × 10` fusion points; alignment shifts.
- **Failure:** demon **enrages** — its ATK is multiplied ×1.5 and it resumes attacking.

---

### 3. Fusion System (`scripts/systems/fusion.gd`)

Fusion occurs in the **Hub** between runs. Two demons combine into one stronger child.

**Priority:** Named recipes take precedence over generic fusion.

**Generic fusion rules:**
- `child.rank = max(rank_a, rank_b) + 1`
- `child.stats[s] = int((a.stats[s] + b.stats[s]) × 0.55)` for each stat
- `child.alignment` resolved by alignment rules table
- Skills: last skill of each parent is inherited

**Alignment resolution table:**

| Combination      | Result  |
|------------------|---------|
| law + law        | law     |
| chaos + chaos    | chaos   |
| neutral + neutral| neutral |
| law + chaos      | neutral |
| law + neutral    | law     |
| chaos + neutral  | chaos   |

**Fusion cost:** `(rank_a + rank_b) × 50` fusion points.

**Constraints:**
- Immutable demons cannot be fused (boss/unique demons).
- A demon cannot fuse with itself.

---

### 4. Spawn Manager (`scripts/systems/spawn_manager.gd`)

Runs consist of **5 waves** by default. Wave `n` spawns `3 + n × 2` enemies at random spawn points.

After all enemies in a wave die, a 1.5-second pause precedes the next wave. Completion of all waves ends the run with success.

---

### 5. Player (`scripts/characters/player.gd`)

**Stats:**
- `max_hp`: 100 (base)
- `attack_damage`: 15 (base)
- `charisma`: 8 (affects negotiation)
- `strength`: 10 (affects threaten)

**Movement:** WASD/Arrow keys with isometric Y-axis scaling (×0.5).

**Combat:** Left-click attacks the nearest enemy within 100 px.

**Skill slots:** Two active skill slots filled from recruited demons. Keys `1` and `2` activate them.

---

### 6. Demon AI (`scripts/characters/demon_ai.gd`)

State machine: IDLE → PATROL → ATTACK → FLEE / NEGOTIATEABLE

| State          | Trigger                            | Behavior                        |
|----------------|------------------------------------|---------------------------------|
| PATROL         | Player out of detect range (200px) | Wanders randomly                |
| ATTACK         | Player within detect range         | Chases and attacks at 40px      |
| NEGOTIATEABLE  | HP ≤ 25%                           | Stops; signals availability     |
| FLEE           | (reserved for future)              | Runs from player                |

---

### 7. Game State & Persistence (`scripts/systems/game_state.gd`)

Saved to `user://night_cathedral_save.json`. Preserves:
- Player stats and HP
- Demon roster
- Fusion points
- Alignment value
- Run count
- Telemetry log (per-run stats)

**Telemetry fields:** `run_id`, `run_time`, `waves_cleared`, `recruited_count`, `fusions_made`, `player_alignment`, `deaths`.

---

## Scene Architecture

```
scenes/
  run_arena.tscn      ← Main gameplay scene (instantiates Player, SpawnManager)
  hub.tscn            ← Between-run hub (Roster + Fusion Chamber)
  player.tscn         ← Player prefab
  demon_follower.tscn ← Enemy demon prefab
  ui/
    negotiation_dialog.tscn ← In-run negotiation popup
```

---

## Input Map

| Key / Button | Action        |
|--------------|---------------|
| W / Up       | move_up       |
| S / Down     | move_down     |
| A / Left     | move_left     |
| D / Right    | move_right    |
| Left Click   | attack        |
| F            | interact      |
| 1            | use_skill_1   |
| 2            | use_skill_2   |
| H            | go_to_hub     |

---

## Progression Loop

```
Hub (fusion, roster review)
  │
  └─► Start Run
        │
        ├─► Wave 1..5: fight demons, negotiate, recruit
        │
        ├─► Run Success → return to Hub with fusion points
        │
        └─► Run Failure → return to Hub (roster preserved)
```

---

## Future Work

- Procedural dungeon generation (tile-based rooms)
- Item system (offerings, consumables, equipment)
- Boss demons (immutable, unique negotiation trees)
- Compendium (registry of all encountered demons)
- Alignment-locked areas and story branches
- Multiplayer Co-op mode
