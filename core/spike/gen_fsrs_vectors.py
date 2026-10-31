"""Regenerate core/spike/fsrs_vectors.json from the reference FSRS implementation.

Pinned reference: `fsrs == 6.3.2` (PyPI, FSRS-6). `uv` materialises it in a throwaway
environment, so no virtualenv is needed in the tree. From the repo root:

    uv run --with fsrs==6.3.2 python core/spike/gen_fsrs_vectors.py

Add `--python 3.13.5` to reproduce the committed `interpreter` field; the vectors
themselves are byte-identical on CPython 3.13.5 and 3.14.7.

Settings: desired_retention=0.9, learning_steps=(1m, 10m), relearning_steps=(10m,),
maximum_interval=36500, enable_fuzzing=False.

py-fsrs has no `enable_short_term` toggle; non-empty learning steps imply short-term
behaviour, so the spec field maps to those steps rather than to a parameter.

The installed `fsrs` version and its 21 FSRS-6 weights are checked against
FSRS_VERSION/EXPECTED_WEIGHTS, so another version fails loudly instead of writing
vectors from a different algorithm.
"""
import importlib.metadata
import json
import platform
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

from fsrs import Card, Rating, Scheduler, State

FSRS_VERSION = "6.3.2"
EXPECTED_WEIGHTS = (
    0.212, 1.2931, 2.3065, 8.2956, 6.4133, 0.8334, 3.0194, 0.001, 1.8722, 0.1666,
    0.796, 1.4835, 0.0614, 0.2629, 1.6483, 0.6014, 1.8729, 0.5425, 0.0912, 0.0658,
    0.1542,
)

T0 = datetime(2026, 10, 30, 9, 0, 0, tzinfo=timezone.utc)
MAX_INTERVAL = 36500
LEARNING = (timedelta(minutes=1), timedelta(minutes=10))
RELEARNING = (timedelta(minutes=10),)

scheduler = Scheduler(
    desired_retention=0.9,
    learning_steps=LEARNING,
    relearning_steps=RELEARNING,
    maximum_interval=MAX_INTERVAL,
    enable_fuzzing=False,
)

installed_version = importlib.metadata.version("fsrs")
if installed_version != FSRS_VERSION:
    sys.exit(f"fsrs {installed_version} installed; expected {FSRS_VERSION}")

if tuple(round(w, 10) for w in scheduler.parameters) != tuple(round(w, 10) for w in EXPECTED_WEIGHTS):
    sys.exit(f"weights changed: {list(scheduler.parameters)}; expected FSRS {FSRS_VERSION} weights")

# py-fsrs has no New state and no counters; map to the candidate's model.
STATE = {State.Learning: 1, State.Review: 2, State.Relearning: 3}
vectors = []


def steps_for(state):
    return RELEARNING if state == State.Relearning else LEARNING


def remaining_steps(card):
    if card.state == State.Review:
        return 0
    return len(steps_for(card.state)) - card.step


def iso(ts):
    return ts.strftime("%Y-%m-%dT%H:%M:%SZ")


def scenario(name, ratings, start=T0):
    reps = lapses = 0
    card = Card(due=start)
    now = start
    for rating in ratings:
        is_new = card.stability is None
        vectors.append({
            "name": f"{name}/r{rating}",
            "input": {
                "state": 0 if is_new else STATE[card.state],
                "due": iso(card.due),
                "stability": 0.0 if is_new else card.stability,
                "difficulty": 0.0 if is_new else card.difficulty,
                "reps": reps,
                "lapses": lapses,
                "remaining_steps": 0 if is_new else remaining_steps(card),
                "last_review": None if card.last_review is None else iso(card.last_review),
            },
            "now": iso(now),
            "rating": int(rating),
        })
        was_review = not is_new and card.state == State.Review
        card, _ = scheduler.review_card(card, rating, now)
        reps += 1
        if rating == Rating.Again and was_review:
            lapses += 1
        vectors[-1]["want"] = {
            "state": STATE[card.state],
            "due": iso(card.due),
            "stability": card.stability,
            "difficulty": card.difficulty,
            "reps": reps,
            "lapses": lapses,
        }
        now = card.due


# Required coverage.
scenario("new", [Rating.Again])
scenario("new", [Rating.Hard])
scenario("new", [Rating.Good])
scenario("new", [Rating.Easy])
scenario("good-good-again-good", [Rating.Good, Rating.Good, Rating.Again, Rating.Good])
scenario("lapse-from-review", [Rating.Easy, Rating.Again])
scenario("lapse-after-good-then-good", [Rating.Good, Rating.Good, Rating.Again, Rating.Good, Rating.Good])

# Extra: review five minutes before UTC midnight, then ten minutes later. Same
# 10-minute gap as a learning step, but the libraries may disagree on elapsed days.
scenario("midnight-gap", [Rating.Good, Rating.Good], start=datetime(2026, 10, 30, 23, 55, 0, tzinfo=timezone.utc))

doc = {
    "reference": {
        "library": "fsrs",
        "version": FSRS_VERSION,
        "algorithm": "FSRS-6",
        "source": "PyPI fsrs 6.3.2, Scheduler defaults",
        "interpreter": f"{platform.python_implementation()} {platform.python_version()}",
    },
    "settings": {
        "request_retention": 0.9,
        "maximum_interval": MAX_INTERVAL,
        "enable_short_term": True,
        "enable_fuzz": False,
        "learning_steps_minutes": [1, 10],
        "relearning_steps_minutes": [10],
    },
    "weights": list(scheduler.parameters),
    "mapping": {
        "state": "0=New, 1=Learning, 2=Review, 3=Relearning (candidate encoding; reference has no New state)",
        "remaining_steps": "len(steps) - reference step, 0 in Review",
        "reps": "reviews applied so far (increment on every review)",
        "lapses": "increment only when rating=Again from Review (spec §7.1)",
        "enable_short_term": "spec field name, not a py-fsrs parameter: py-fsrs has no toggle; non-empty learning steps (1m/10m) imply short-term behaviour",
    },
    "vectors": vectors,
}

out = Path(__file__).with_name("fsrs_vectors.json")
with open(out, "w") as f:
    json.dump(doc, f, indent=2, ensure_ascii=False)
    f.write("\n")

print("vectors:", len(vectors), "->", out)
