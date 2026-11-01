# Attacks on the secret-masking step

This directory implements the three attacks analyzed in the accompanying
report: two algebraic recovery attacks and a one-value candidate search for
a corrected numerical fixture of the masking rule in
Chintamani, Paul, and Sa's *Conjunctive Hierarchical Multi-Secret
Sharing Scheme using Elliptic Curves*. See the
[reference and implementation mapping](../paper/references.md).

The paper's Section 3.1 chooses keys in the prime field and publishes

\[
v_i=e(P,iQ)+K_i=z^i+K_i,\qquad z=e(P,Q),\qquad K_i\in\mathbb F_p.
\]

The equality `e(P,iQ)=z^i` follows from bilinearity. The two-value attack
recovers `z` without a compromised key. The one-key attack recovers `z`
after `K1` is compromised. The one-value demonstration recovers `K1=8`
for the corrected numerical fixture by filtering candidate keys using the
norm and mask subgroup. Other valid inputs can leave multiple candidates;
this is not a general guarantee of unique recovery from one public value.
None of the attackers needs participant shares, `Q`, coefficient
scalars, curve points, or a pairing evaluation.

## Current experiments and files

| Directory | Dealer fixture | Attacker input | Verifier |
| --- | --- | --- | --- |
| `two_values/toy_model/` | `F_(47^3)`, `Q=7P`, keys `[8,15,22,11]` | Public transcript only | None |
| `two_values/bls12_381/` | BLS12-381, random nonzero scalar times G2, four random 256-bit keys | Public transcript and public field definitions | `verify_attack.sage`, two fresh trials |
| `one_key/toy_model/` | `F_(47^3)`, `Q=7P`, keys `[8,15]` | Public transcript and compromised `K1` (fixed demonstration value `8`) | None |
| `one_key/bls12_381/` | BLS12-381, random nonzero scalar times G2, four random 256-bit keys | Public transcript, public field definitions, and compromised `K1` via prompt | `verify_attack.sage`, two fresh trials |
| `one_value/` | Corrected `F_(47^3)` paper fixture, `Q=13P`, first key `8` | Only the first public value | None |

Each experiment contains `dealer.sage`, `attacker.sage`, and a
`public_values.txt` transcript. Running the dealer replaces that transcript. Both BLS12-381 directories also contain:

- `public_parameters.py`: field and subgroup constants, extension-field
  construction, and transcript encoding/decoding.
- `curve.py`: standard G1/G2 generators, the twist-to-extension mapping,
  generator consistency checks, and the reduced Tate pairing.
- `verify_attack.sage`: comparison of attacker recovery against dealer keys.

The dealers implement the masking step, rather than the complete hierarchy
or share-distribution protocol. The BLS12-381 experiments use
`G1.tate_pairing(G2, r, 12, q=p)` over `Fp^12`; they are algebraic recovery
experiments, without performance measurements.

The report's computational examples correspond to these directories:

- two-public-value recovery: `two_values/toy_model/` and
  `two_values/bls12_381/`;
- recovery after one secret disclosure: `one_key/toy_model/` and
  `one_key/bls12_381/`;
- one-public-value candidate search: `one_value/`.

The derivations and worked one-value calculation are in the authoritative
[LaTeX report](../gen_report/pairing_mask_cryptanalysis.tex) and its
[compiled PDF](../gen_report/pairing_mask_cryptanalysis.pdf).

## Two public values: Frobenius recovery

Because `K_i^p=K_i`, define

\[
A=v_1^p-v_1=z^p-z,\qquad
B=v_2^p-v_2=z^{2p}-z^2.
\]

Substituting `z^p=z+A` gives

\[
B=(z+A)^2-z^2=2Az+A^2.
\]

For odd characteristic and `A != 0`, this determines

\[
z=\frac{B-A^2}{2A},\qquad K_i=v_i-z^i.
\]

The required public values have indices 1 and 2. Once their common mask is
known, the attacker can recover each subsequent published key. The attack
uses extension-field arithmetic; it does not solve a discrete logarithm,
guess a key, or invert the pairing. Increasing the subgroup order preserves
this relation. If the scheme's curve base field is itself an extension,
the cancellation still uses the characteristic `p`, provided the keys
remain in `F_p`.

If `A=0`, the mask lies in the prime field. For a mask in `mu_ell`, the
intersection with `F_p^*` has order `gcd(ell,p-1)`. When that gcd is 1, the
only possible mask is `z=1`, giving `K_i=v_i-1`.

The toy attacker implements this identity-mask branch for `p=47`,
`ell=37`. The BLS12-381 dealer chooses a non-identity order-`r` mask; its
attacker rejects `A=0` as outside that experiment's expected input.
An identity-mask rejection in that script does not imply confidentiality
for that case. For other parameters with a larger subgroup intersection,
the identity conclusion requires a separate analysis.

## One compromised key: direct recovery

Given the first key and its public masked value,

\[
z=v_1-K_1,\qquad K_i=v_i-z^i.
\]

This attack does not require a Frobenius calculation. It uses the first
compromised key as an explicit input; it does not recover it from dealer
state. Both implementations check subgroup membership and that recovered
keys lie in the prime field. The BLS implementation additionally rejects an
identity mask, matching its dealer's construction.

The toy attacker uses the demonstration's known compromised `K1=8`.
That constant is a simulated leak, not a public-only recovery claim. The BLS
attacker prompts for the leaked key and never reads `dealer_truth.json`.

## Numerical scope and representation

The toy fields use `X^3+3X+42` with power basis `1,alpha,alpha^2`, and curve
`y^2=x^3+4x+15`. This polynomial corrects the paper's inconsistent suggested
encoding, as explained in [paper/references.md](../paper/references.md).
The one-key and two-value toy dealers use coefficients `a11=11`, `a21=33`,
so `Q=7P`, matching the local two-level fixture.
The paper's three-level example adds `a31=6` and uses `Q=13P`; it is distinct
from these local transcripts.

The one-value dealer instead reproduces the paper's first `Q=13P` public
value, `v1=12+28*alpha+37*alpha^2`, using the same corrected encoding.
It generates only this masking value, without the hierarchy or shares.

The BLS12-381 helpers use `Fp^12` represented by
`w^12-2*w^6+2=0`. Public parameters include the base-field prime `p`,
subgroup-order prime `r`, extension degree, and encoding convention.
Four independently generated 256-bit integers are embedded in `Fp`; the
attack uses that prime-field membership, rather than the keys' bit length.
These are larger-parameter masking examples, not a reproduction of the
paper's full hierarchical protocol.

## One public value: demonstrated recovery for the corrected numerical fixture

For each possible first key `k` in `F47`, the attacker computes the candidate
mask `w=v1-k`. A valid mask satisfies `w^37=1`, so its norm obeys
`N(w)=w^(1+47+47^2)=(w^37)^61=1`.

The attacker enumerates all 47 possible keys, retains those with norm 1,
then checks the exact subgroup condition `w^37=1`. For the displayed
fixture the norm candidates are `[8,12,29]`, and only `8` survives. This
demonstrates recovery for this corrected numerical fixture, as calculated in
[the LaTeX report](../gen_report/pairing_mask_cryptanalysis.tex).

The norm condition alone is insufficient. Even after subgroup filtering,
some other valid transcripts have two consistent keys. The attacker reports
all survivors and distinguishes unique from ambiguous recovery; it rejects
inputs with no valid key-mask pair. It reads no expected secret, dealer
state, curve point, or pairing output separately from the masked public value.

## Run from the repository root

Install SageMath and run the commands below from the repository root.
Every Sage script runs as `sage <path>.sage`, with no command-line flags,
prior Sage session, or `load(...)`. Transcripts and helper imports resolve
beside the script. Dealers overwrite only their own experiment's transcript.

Two-value toy:

```bash
sage attack/two_values/toy_model/dealer.sage
sage attack/two_values/toy_model/attacker.sage
```

Two-value BLS12-381:

```bash
sage attack/two_values/bls12_381/dealer.sage
sage attack/two_values/bls12_381/attacker.sage
sage attack/two_values/bls12_381/verify_attack.sage
```

One-key toy:

```bash
sage attack/one_key/toy_model/dealer.sage
sage attack/one_key/toy_model/attacker.sage
```

The toy one-key attacker runs without command-line flags. Its simulated
compromised key is the constant `LEAKED_K1=8` in the script, and it reads
`public_values.txt` beside itself. Edit that constant when using a transcript
with a different compromised first key.

One-key BLS12-381:

```bash
sage attack/one_key/bls12_381/dealer.sage
sage attack/one_key/bls12_381/attacker.sage
sage attack/one_key/bls12_381/verify_attack.sage
```

Enter the compromised `K1` printed by the dealer at the attacker's prompt.
The verifier supplies that input automatically. Its invocation needs no
command-line flags or manual input.

Attackers can run individually against the supplied public transcripts.
For the BLS one-key experiment, a matching compromised key is also needed;
run the dealer to obtain one for a fresh transcript. Attackers never run
or import dealer code automatically.

One-value recovery demonstration for the corrected numerical fixture:

```bash
sage attack/one_value/dealer.sage
sage attack/one_value/attacker.sage
```

Both use `attack/one_value/public_values.txt`, independent of the working
directory. The attacker needs no flags or leaked key. Public transcripts are currently
allowed by `.gitignore` and present beside the scripts. Run the matching
dealer to regenerate a missing transcript or replace it with a fresh one.

Both BLS12-381 `curve.py` helpers also support direct execution from the
repository root:

```bash
sage attack/one_key/bls12_381/curve.py
sage attack/two_values/bls12_381/curve.py
```

They define the curve and pairing functions; direct execution does not run
a recovery experiment. `public_parameters.py` defines the field and encoding
helpers. Both helper modules import `sage.all` and use Sage's Python environment.

## Transcript formats and generated files

| Experiment | `public_values.txt` format |
| --- | --- |
| One-key and two-value toy models | One field element per line, with comma-separated coefficients in ascending powers of `alpha`; line `i` represents `v_i` |
| One-value toy model | Exactly three space-separated coefficients in `[0,46]`, representing the constant, `alpha`, and `alpha^2` terms of `v1` |
| Two-value BLS12-381 | JSON list of field elements, each encoded as 12 decimal-string coefficients; list order starts at `v1` |
| One-key BLS12-381 | JSON document containing public field parameters and consecutively indexed values, each with 12 decimal-string coefficients |

Public transcripts contain no keys, private scalar, `Q`, or mask. Field
parameters for the two-value experiments are defined in their code; the
one-key BLS transcript additionally includes them as metadata.

The BLS one-key dealer also creates `dealer_truth.json`, containing private
keys for the verifier. It prints the first key to model a compromise.
That private record is separate from the public transcript. Running the
standalone dealer leaves it beside the script; the verifier removes it
during cleanup.

## What the current verifiers establish

Only the BLS12-381 directories currently contain verifiers. Each checks
that all four recovered keys equal the dealer's keys in two fresh trials,
and rejects a repeated complete key set between trials.

The two-value verifier executes Python-compatible dealer and attacker
source in separate namespaces within one process, temporarily setting each
script's `sys.argv[0]`. Ground truth stays in the dealer namespace; the
attacker reads its public transcript. This is namespace separation, without
subprocess isolation or an operating-system sandbox.

The one-key verifier runs dealer and attacker in separate Sage subprocesses.
It moves `dealer_truth.json` to a temporary directory before starting the
attacker, supplies only the first key through standard input, and compares
all recovered keys with its private ground truth. It deletes the private
record during cleanup and leaves the final public transcript in place.
The shared account's filesystem permissions do not constitute an adversarial
sandbox.

The current toy directories have no independent verifier. Their attacker
checks enforce subgroup and prime-field consistency; those checks alone do
not establish equality to independently held ground truth. These experiments
establish recovery for their stated masking models, rather than a complete
security analysis of every scheme component.
The one-value script's exhaustive candidate search determines the set of
keys consistent with its single public input; only a singleton set permits
unique recovery.
