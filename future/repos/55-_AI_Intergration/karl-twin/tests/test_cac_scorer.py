"""CAC scorer tests. Anchors the spec invariant: tier 0/1 = mandatory approval."""

from karl_twin.cac.scorer import score_action, requires_human_approval


def test_file_write_default_is_tier1():
    s = score_action("file.write", {"path": "data/outputs/hello.txt", "content": "hi"})
    assert 0 <= s.tier <= 4
    assert s.tier == 1
    assert requires_human_approval(s) is True


def test_code_execute_is_low_tier():
    s = score_action("code.execute", {"code": "print('hi')"})
    assert s.tier <= 1
    assert requires_human_approval(s) is True


def test_code_execute_with_network_pushes_ec_up():
    base = score_action("code.execute", {"code": "print('hi')"})
    net  = score_action("code.execute", {"code": "import requests; requests.get('http://x')"})
    assert net.EC > base.EC
    assert net.HI <= base.HI  # network use should never raise HI


def test_file_write_outside_sandbox_is_more_dangerous():
    inside  = score_action("file.write", {"path": "data/outputs/a.txt", "content": "x"})
    outside = score_action("file.write", {"path": "C:/Windows/x.txt", "content": "x"})
    assert outside.HI < inside.HI
    assert outside.EC >= inside.EC


def test_unknown_action_type_is_conservative():
    s = score_action("totally.new.thing", {})
    assert s.tier <= 1
