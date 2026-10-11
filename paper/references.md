# Reference paper and implementation mapping

Mohan Chintamani, Prabal Paul, and Laba Sa. *Conjunctive Hierarchical
Multi-Secret Sharing Scheme using Elliptic Curves*. Indian Journal of Pure
and Applied Mathematics **55** (2024), 1456–1464. Published online 21 July 2023.

DOI: [10.1007/s13226-023-00450-x](https://doi.org/10.1007/s13226-023-00450-x).

## Sections used by the current code

| Paper location | Role in this repository |
| --- | --- |
| Section 2, p. 1458 | Pairing properties and target subgroup underlying the masking equations |
| Section 3.1, p. 1459 | Scalar and point-share construction, reuse of earlier shares, prime-field secrets, and publication of `v_i=e(P,iQ)+K_i` |
| Section 3.2, p. 1460 | Reconstruction of coefficient points and `Q`, followed by secret recovery |
| Section 5, pp. 1462–1463 | Toy field, curve, point, share matrices, and demonstration keys |

The scheme demonstration is
[chmss_two_level_demo.sage](../chmss_two_level_demo.sage). It implements
Levels 1 and 2 with one secret, `K1=8`, and constructs `Q=7P`. It does not
implement the full three-level example, whose additional coefficient
`a31=6` gives `Q=13P`, or the submitted-share verification of Section 3.3.

## Encoding and experiment scope

The toy code uses the extension polynomial `X^3+3X+42`. The paper suggests
`X^3+X+4`, under which its printed point coordinates do not satisfy the
printed curve equation. The chosen polynomial makes those coordinates
consistent. This is a corrected encoding, rather than literal use of the
paper's suggested polynomial.

The [attack experiments](../attack/README.md) use the paper's masking rule
and its restriction that keys lie in the prime field. The two-value attack
cancels those keys with Frobenius; the one-key attack subtracts a compromised
`K1` to recover the common mask. The one-value demonstration recovers `K1=8`
for the corrected numerical fixture by filtering possible first keys by the
norm and the order-37 mask constraint; other valid inputs can leave multiple
candidates. These are deductions
from the stated masking equations, not attack procedures attributed to the paper.

The one-key and two-value toy dealers use the local two-level `Q=7P`
fixture. The two-value dealer
publishes four masked keys `[8,15,22,11]`; the one-key dealer publishes two,
`[8,15]`. Their transcripts are not the paper's full `Q=13P` transcript.

The [one-value dealer](../attack/one_value/dealer.sage) instead uses `Q=13P`
and `K1=8` to reproduce only the first public value of the paper's numerical
example under the corrected encoding. It does not implement Level 3 or
the full share construction. Its [attacker](../attack/one_value/attacker.sage)
reads only that public value and reports all keys consistent with the mask
constraints. The displayed fixture uniquely identifies `8`; uniqueness
does not hold for every valid toy transcript.

The BLS12-381 experiments instantiate the same masking relation using
standard G1/G2 generators, a reduced Tate pairing, and four random 256-bit
keys embedded in `Fp`. Those parameters extend the local experiment; they
are not numerical parameters taken from this paper. They do not implement
the hierarchical share matrices at BLS12-381 parameters.

Only the BLS12-381 directories currently include `verify_attack.sage`.
The two-value verifier executes dealer and attacker code in separate
namespaces within one process. The one-key verifier uses subprocesses and
supplies the compromised first key through standard input. Each compares
all four recovered keys against ground truth in two fresh dealer trials.

## Report and execution

[The LaTeX report](../attack/report/three_recovery_attacks.tex) and its
[compiled PDF](../attack/report/three_recovery_attacks.pdf) derive the
one-key and two-value attacks and demonstrate one-value recovery for the
corrected numerical fixture. The one-value calculation uses
only the paper's first published value under the corrected encoding;
its subgroup-filtered candidate is `K1=8`.

The one-value implementation enumerates all 47 possible first keys and
applies the norm and subgroup tests. It reports ambiguous candidate sets
when present, rather than assuming every transcript permits unique recovery.

All experiment scripts run directly with `sage <path>.sage` and require no
command-line flags. Public transcripts are stored beside their scripts.
The toy one-key attacker uses the fixed simulated leak `LEAKED_K1=8`; the
BLS one-key attacker receives the compromised key at a prompt. See the
[attack guide](../attack/README.md#run-from-the-repository-root) for commands,
transcript formats, and generated-file behavior.
