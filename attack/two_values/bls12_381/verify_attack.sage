"""Check the public-only attack on two fresh dealer runs.

Run from the repository root:
    sage attack/two_values/bls12_381/verify_attack.sage

The dealer's real keys stay in this verifier's private namespace.
The attacker runs separately and receives only public_values.txt.
"""

import io
import re
import sys
from contextlib import redirect_stdout
from pathlib import Path

# Resolve sibling scripts independently of the working directory.
ROOT = Path(sys.argv[0]).resolve().parent

DEALER_SCRIPT = ROOT / "dealer.sage"
ATTACKER_SCRIPT = ROOT / "attacker.sage"
TRIALS = 2

def run_script_in_its_own_namespace(path):
    """Run one Python-compatible Sage script in a separate namespace."""
    namespace = {"__name__": "__main__", "__file__": str(path)}
    output = io.StringIO()

    previous_argv = sys.argv
    try:
        sys.argv = [str(path)]
        with redirect_stdout(output):
            source = path.read_text()
            exec(compile(source, str(path), "exec"), namespace)
    except Exception as error:
        raise RuntimeError(
            "Failed while running {}. Output so far:\n{}".format(
                path.name, output.getvalue()
            )
        ) from error
    finally:
        sys.argv = previous_argv

    return namespace, output.getvalue()


def recovered_keys_from(output):
    """Extract lines of the form 'Recovered K1 = 123' from attacker output."""
    matches = re.findall(r"Recovered K(\d+) = (\d+)", output)
    return {int(index): int(value) for index, value in matches}


previous_dealer_keys = None

for trial in range(1, TRIALS + 1):
    # Make fresh secrets and publish a new transcript.
    dealer, _ = run_script_in_its_own_namespace(DEALER_SCRIPT)
    if "keys" not in dealer:
        raise RuntimeError(
            "dealer.sage must keep its generated secret list in a variable named `keys`."
        )
    expected_keys = [int(key) for key in dealer["keys"]]

    # Ensure trial 2 actually uses a different set of secrets.
    if previous_dealer_keys is not None and expected_keys == previous_dealer_keys:
        raise RuntimeError("The dealer repeated the previous key set; run the test again.")

    # The attacker is executed separately. It reads only the public transcript.
    _, attack_output = run_script_in_its_own_namespace(ATTACKER_SCRIPT)
    recovered = recovered_keys_from(attack_output)
    expected = {i: key for i, key in enumerate(expected_keys, start=1)}

    if recovered != expected:
        print("\nATTACK OUTPUT:\n" + attack_output)
        missing = sorted(set(expected) - set(recovered))
        wrong = sorted(
            i for i in set(expected) & set(recovered)
            if expected[i] != recovered[i]
        )
        raise AssertionError(
            "Trial {} failed. Missing keys: {}; incorrect keys: {}".format(
                trial, missing, wrong
            )
        )

    print("Trial {}/{}: PASS — all {} recovered keys match the dealer.".format(
        trial, TRIALS, len(expected_keys)
    ))
    previous_dealer_keys = expected_keys

print("\nPASS — the attack recovered every key in both fresh runs.")
print("The final public transcript remains in public_values.txt.")
