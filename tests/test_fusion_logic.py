"""
Python unit tests for Night Cathedral fusion and negotiation logic.
These mirror the GDScript tests and can be run in CI without Godot.
"""
import json
import math
import sys
import os

DEMONS_PATH = os.path.join(os.path.dirname(__file__), '..', 'data', 'demons.json')
RECIPES_PATH = os.path.join(os.path.dirname(__file__), '..', 'data', 'fusion_recipes.json')

FUSION_COST_PER_RANK = 50

ALIGNMENT_RULES = {
    "law+law": "law",
    "chaos+chaos": "chaos",
    "neutral+neutral": "neutral",
    "law+chaos": "neutral",
    "chaos+law": "neutral",
    "law+neutral": "law",
    "neutral+law": "law",
    "chaos+neutral": "chaos",
    "neutral+chaos": "chaos",
}

def load_demons():
    with open(DEMONS_PATH) as f:
        return json.load(f)["demons"]

def load_recipes():
    with open(RECIPES_PATH) as f:
        return json.load(f)

def can_fuse(a, b):
    if a.get("flags", {}).get("immutable", False):
        return False, f"{a['name']} is immutable"
    if b.get("flags", {}).get("immutable", False):
        return False, f"{b['name']} is immutable"
    if a["id"] == b["id"]:
        return False, "Cannot fuse demon with itself"
    return True, ""

def resolve_alignment(a_align, b_align):
    key = f"{a_align}+{b_align}"
    return ALIGNMENT_RULES.get(key, "neutral")

def generic_fuse(a, b):
    child = {}
    child["id"] = f"{a['id']}_{b['id']}_fus"
    child["name"] = f"{a['name']}-{b['name']} Hybrid"
    child["rank"] = max(a["rank"], b["rank"]) + 1
    child["alignment"] = resolve_alignment(a["alignment"], b["alignment"])
    stats = {}
    for stat in ["hp", "atk", "def", "spd"]:
        sa = a["base_stats"][stat]
        sb = b["base_stats"][stat]
        stats[stat] = int((sa + sb) * 0.55)
    child["base_stats"] = stats
    return child

def fusion_cost(a, b):
    return (a["rank"] + b["rank"]) * FUSION_COST_PER_RANK

def alignment_value(a):
    if a == "law": return 1.0
    if a == "chaos": return -1.0
    return 0.0

def recruit_chance(demon, charisma, player_alignment_norm):
    rules = demon["recruit_rules"]
    chance = rules["base_chance"]
    chance += charisma * 0.01
    demon_val = alignment_value(demon["alignment"])
    bias = rules["alignment_bias"]
    chance += (1.0 - abs(player_alignment_norm - demon_val)) * bias
    return max(0.0, min(1.0, chance))

# --- Tests ---

def test_load_demons():
    demons = load_demons()
    assert len(demons) == 10, f"Expected 10 demons, got {len(demons)}"
    print("PASS: load_demons: 10 demons")

def test_demon_required_fields():
    demons = load_demons()
    required = ["id", "name", "alignment", "mythology", "rank", "base_stats", "skills", "recruit_rules", "flags"]
    for d in demons:
        for field in required:
            assert field in d, f"Missing {field} in {d.get('id')}"
        assert d["alignment"] in ["law", "neutral", "chaos"], f"Bad alignment in {d['id']}"
        assert d["rank"] >= 1
        for stat in ["hp", "atk", "def", "spd"]:
            assert stat in d["base_stats"], f"Missing stat {stat} in {d['id']}"
        for flag in ["boss", "recruitable_in_run", "immutable"]:
            assert flag in d["flags"], f"Missing flag {flag} in {d['id']}"
    print("PASS: test_demon_required_fields")

def test_can_fuse_normal():
    demons = load_demons()
    ok, reason = can_fuse(demons[0], demons[1])
    assert ok, f"Normal demons should fuse: {reason}"
    print("PASS: test_can_fuse_normal")

def test_can_fuse_immutable():
    immutable = {"id": "boss", "name": "Boss", "flags": {"immutable": True}}
    normal = {"id": "normal", "name": "Normal", "flags": {"immutable": False}}
    ok, reason = can_fuse(immutable, normal)
    assert not ok
    print("PASS: test_can_fuse_immutable")

def test_can_fuse_same():
    demons = load_demons()
    ok, reason = can_fuse(demons[0], demons[0])
    assert not ok, "Should not fuse demon with itself"
    print("PASS: test_can_fuse_same")

def test_generic_fuse_rank():
    a = {"id": "a", "name": "A", "rank": 2, "alignment": "chaos",
         "base_stats": {"hp": 100, "atk": 20, "def": 10, "spd": 10},
         "flags": {"immutable": False}}
    b = {"id": "b", "name": "B", "rank": 3, "alignment": "law",
         "base_stats": {"hp": 100, "atk": 20, "def": 10, "spd": 10},
         "flags": {"immutable": False}}
    child = generic_fuse(a, b)
    assert child["rank"] == 4, f"Expected rank 4, got {child['rank']}"
    assert child["alignment"] == "neutral", f"Expected neutral, got {child['alignment']}"
    expected_hp = int((100 + 100) * 0.55)
    assert child["base_stats"]["hp"] == expected_hp
    print("PASS: test_generic_fuse_rank")

def test_alignment_rules():
    assert resolve_alignment("law", "law") == "law"
    assert resolve_alignment("chaos", "chaos") == "chaos"
    assert resolve_alignment("law", "chaos") == "neutral"
    assert resolve_alignment("chaos", "law") == "neutral"
    assert resolve_alignment("law", "neutral") == "law"
    assert resolve_alignment("chaos", "neutral") == "chaos"
    print("PASS: test_alignment_rules")

def test_fusion_cost():
    a = {"rank": 2}
    b = {"rank": 3}
    cost = fusion_cost(a, b)
    assert cost == 250, f"Cost mismatch: {cost}"
    print("PASS: test_fusion_cost")

def test_recruit_chance_base():
    demons = load_demons()
    oni = next(d for d in demons if d["id"] == "oni_yokai")
    chance = recruit_chance(oni, 5, 0.0)
    # base 0.45 + 5*0.01 = 0.50, alignment_bias -0.25 with neutral player vs chaos demon:
    # (1 - abs(0 - (-1))) * -0.25 = 0 * -0.25 = 0
    assert 0.49 <= chance <= 0.51, f"Expected ~0.50, got {chance}"
    print("PASS: test_recruit_chance_base")

def test_recipe_fusion():
    recipes_data = load_recipes()
    demons = load_demons()
    demons_by_id = {d["id"]: d for d in demons}
    for recipe in recipes_data["recipes"]:
        pa = recipe["parent_a"]
        pb = recipe["parent_b"]
        assert pa in demons_by_id, f"Recipe parent {pa} not in demons"
        assert pb in demons_by_id, f"Recipe parent {pb} not in demons"
        result = recipe["result"]
        assert "id" in result and "name" in result and "rank" in result
    print("PASS: test_recipe_fusion")

if __name__ == "__main__":
    tests = [
        test_load_demons,
        test_demon_required_fields,
        test_can_fuse_normal,
        test_can_fuse_immutable,
        test_can_fuse_same,
        test_generic_fuse_rank,
        test_alignment_rules,
        test_fusion_cost,
        test_recruit_chance_base,
        test_recipe_fusion,
    ]
    failed = 0
    for test in tests:
        try:
            test()
        except AssertionError as e:
            print(f"FAIL: {test.__name__}: {e}")
            failed += 1
        except Exception as e:
            print(f"ERROR: {test.__name__}: {e}")
            failed += 1
    if failed:
        print(f"\n{failed} test(s) failed.")
        sys.exit(1)
    else:
        print(f"\nAll {len(tests)} tests passed.")
