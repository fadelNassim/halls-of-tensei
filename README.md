# Night Cathedral

A 2D isometric roguelite built in **Godot 4.3** featuring SMT-inspired demon negotiation and fusion mechanics.

## Concept

Descend into the Night Cathedral — a procedurally varied dungeon haunted by demons from across world mythologies. Fight, negotiate, and recruit demons to build your roster. Between runs, fuse demons in the Hub to create more powerful allies that persist across playthroughs.

## Key Features

- **Negotiation system** — Weaken demons in combat, then talk them into joining your cause using appeal, threats, or item offerings.
- **Alignment (Law/Chaos/Neutral)** — Your recruitment choices shift your alignment, affecting future negotiations and unlocking exclusive fusion recipes.
- **SMT-style fusion** — Combine two demons in the Hub to produce a stronger child. Named recipes and generic rule-based fusion both supported.
- **Roguelite meta-progression** — Demon roster and fusion points persist; each run challenges you with escalating waves.
- **Isometric 2D** — Top-down isometric view with Godot's TileMapLayer.

## Project Structure

```
halls-of-tensei/
├── project.godot
├── icon.svg
├── data/
│   ├── demons.json           # 10 recruitable demons with varied alignments/mythologies
│   └── fusion_recipes.json   # Named fusion recipes + alignment rules
├── scripts/
│   ├── characters/
│   │   ├── player.gd         # Player controller (movement, combat, skill slots)
│   │   └── demon_ai.gd       # Enemy AI state machine (patrol/attack/negotiate)
│   ├── data/
│   │   └── demon_data.gd     # Resource loader for demons.json
│   ├── systems/
│   │   ├── alignment.gd      # Law/Chaos scalar tracker
│   │   ├── negotiation.gd    # Recruit chance calculator + resolver
│   │   ├── fusion.gd         # Demon fusion (recipe + generic)
│   │   ├── spawn_manager.gd  # Wave-based enemy spawning
│   │   └── game_state.gd     # Save/load + run telemetry
│   ├── ui/
│   │   └── negotiation_dialog_ui.gd  # In-run negotiation popup
│   ├── run_arena.gd          # Main gameplay scene controller
│   └── hub.gd                # Between-run hub controller
├── scenes/
│   ├── run_arena.tscn        # Main gameplay scene
│   ├── hub.tscn              # Hub scene
│   ├── player.tscn           # Player prefab
│   ├── demon_follower.tscn   # Enemy demon prefab
│   └── ui/
│       └── negotiation_dialog.tscn
├── tests/
│   ├── test_fusion.gd        # GDScript fusion unit tests
│   ├── test_negotiation.gd   # GDScript negotiation unit tests
│   ├── test_data_load.gd     # GDScript data loading tests
│   ├── test_fusion_logic.py  # Python tests (runs in CI without Godot)
│   └── run_tests.gd          # GDScript test runner (SceneTree)
├── design/
│   ├── gameplay_doc.md       # Full system design document
│   └── balancing.csv         # Balancing spreadsheet
└── .github/
    └── workflows/
        └── ci.yml            # GitHub Actions CI pipeline
```

## Controls

| Key / Button | Action            |
|--------------|-------------------|
| WASD / Arrows| Move              |
| Left Click   | Attack            |
| F            | Interact/Negotiate|
| 1            | Use Skill 1       |
| 2            | Use Skill 2       |
| H            | Return to Hub     |

## Getting Started

1. Install [Godot 4.3](https://godotengine.org/download).
2. Open the project: `File → Open Project` → select `project.godot`.
3. Press **F5** to run.

## Running Tests

**Python tests (no Godot required):**
```bash
python3 tests/test_fusion_logic.py
```

**GDScript tests (requires Godot headless):**
```bash
godot --headless --script tests/run_tests.gd
```

## CI

GitHub Actions runs on every push and pull request:
- Validates `demons.json` and `fusion_recipes.json` schema
- Checks all GDScript files exist
- Validates required project structure
- Runs Python fusion/negotiation logic tests

## Design

See [`design/gameplay_doc.md`](design/gameplay_doc.md) for the full system design document and [`design/balancing.csv`](design/balancing.csv) for balance targets.

## License

MIT