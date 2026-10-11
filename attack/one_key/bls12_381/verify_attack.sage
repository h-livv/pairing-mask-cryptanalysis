"""Check the one-key attack twice, using fresh random keys each time.

Run from the repository root: sage attack/one_key/bls12_381/verify_attack.sage

The verifier knows the dealer's original keys. Before the attacker starts,
it moves that private record out of this folder and gives the attacker only
public_values.txt plus K1 through standard input.
"""

import json
import re
import shutil
import subprocess
import tempfile
import sys
from pathlib import Path

ROOT = Path(sys.argv[0]).resolve().parent
DEALER = ROOT / "dealer.sage"
ATTACKER = ROOT / "attacker.sage"
PUBLIC_FILE = ROOT / "public_values.txt"
PRIVATE_FILE = ROOT / "dealer_truth.json"
TRIALS = 2

# Match lines printed by the attacker, e.g. "Recovered K2 = 12345".
KEY_LINE = re.compile(r"Recovered K(\d+) = (\d+)")
SAGE = str(Path(sys.executable).with_name("sage"))


def run_sage(script, input_text=None):
    """Run one Sage script and return its output, showing errors clearly."""
    result = subprocess.run(
        [SAGE, str(script)],
        cwd=ROOT,
        input=input_text,
        text=True,
        capture_output=True,
    )
    if result.returncode != 0:
        raise RuntimeError(
            "{} failed.\n\nOutput:\n{}\nError:\n{}".format(
                script.name, result.stdout, result.stderr
            )
        )
    return result.stdout


# The private record is kept outside the attacker's working directory.
with tempfile.TemporaryDirectory(prefix="one-key-check-") as temporary:
    private_dir = Path(temporary)
    previous_keys = None

    try:
        for trial in range(1, TRIALS + 1):
            # Generate a fresh public transcript and private ground truth.
            run_sage(DEALER)

            private_copy = private_dir / "dealer_truth_{}.json".format(trial)
            shutil.move(str(PRIVATE_FILE), str(private_copy))
            expected_keys = [
                int(key) for key in json.loads(private_copy.read_text())["keys"]
            ]

            if previous_keys is not None and expected_keys == previous_keys:
                raise AssertionError("The dealer repeated the same random keys.")

            # Give the attacker just the first key as the simulated leak.
            # The private ground-truth file is no longer in this folder.
            attack_output = run_sage(ATTACKER, input_text=str(expected_keys[0]) + "\n")
            recovered_keys = {
                int(index): int(key)
                for index, key in KEY_LINE.findall(attack_output)
            }
            expected = {
                index: key for index, key in enumerate(expected_keys, start=1)
            }

            if recovered_keys != expected:
                print(attack_output)
                raise AssertionError("Trial {}: recovered keys did not match.".format(trial))

            print(
                "Trial {}/{}: PASS — leaking only K1 recovered all {} keys.".format(
                    trial, TRIALS, len(expected_keys)
                )
            )
            previous_keys = expected_keys
            private_copy.unlink()

    finally:
        # Do not leave a verifier-only private record in the project folder.
        if PRIVATE_FILE.exists():
            PRIVATE_FILE.unlink()

print("\nPASS — all keys matched in both fresh trials.")
print("The final public transcript remains in public_values.txt.")
