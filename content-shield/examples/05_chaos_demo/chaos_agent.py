"""Agent that randomly mutates content to introduce quality issues."""

import random


_TOXIC_INSERTS = [
    " This is stupid. ",
    " What an idiot move. ",
    " Absolutely worthless. ",
]

_BANNED_INSERTS = [
    " Get it cheap today! ",
    " Free trial available! ",
    " Best deal ever! ",
]


def mutate(text: str, chaos_level: float = 0.5) -> str:
    """Return a mutated copy of *text*.

    Args:
        text: Original content.
        chaos_level: Probability (0-1) that each mutation type is applied.
    """
    result = text

    if random.random() < chaos_level:
        insert = random.choice(_TOXIC_INSERTS)
        pos = random.randint(0, len(result))
        result = result[:pos] + insert + result[pos:]

    if random.random() < chaos_level:
        insert = random.choice(_BANNED_INSERTS)
        result += insert

    return result
