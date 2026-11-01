# Pairing-mask cryptanalysis

This repository contains SageMath demonstrations for the three attacks analyzed in Harliv Singh's *Cryptanalysis of Pairing-Based Additive Masking with Prime-Field Secrets*. The paper is maintained separately from this code repository; the scripts and example transcripts reproduce its computational examples. The attacks target the masking rule

$$v_i = K_i + z^i,\qquad K_i\in\mathbb F_p,\quad z\in\mu_\ell.$$

The attacks exploit the field-valued masking relation. They do not solve the elliptic-curve discrete logarithm problem, invert a pairing, or establish that pairing-based secret sharing in general is insecure.

## Attacks and computational scope

| Attack | Attacker input | Included demonstration | What it establishes |
| --- | --- | --- | --- |
| Two-public-value recovery | `v1`, `v2`, public field parameters | Toy model and BLS12-381 masking-layer examples | Recovers `z`, then all keys in the published transcript, under the report's stated conditions. |
| Recovery after one secret disclosure | Public transcript and a suitable disclosed `K_t` | Toy model and BLS12-381 masking-layer examples | Recovers `z` when `gcd(t, ell)=1`, then recovers the transcript's keys. |
| One-public-value candidate search | `v1` and public field/subgroup parameters | Corrected `p=47`, `ell=37` numerical fixture | Enumerates all prime-field keys consistent with the mask constraint; the fixture has one candidate, but uniqueness is not general. |

The attacker input is the public transcript of masked values, `public_values.txt`, and public field/subgroup parameters. The dealer scripts create reproducible example transcripts; in the scheme, an attacker would read the corresponding published values. The one-key attack additionally needs the disclosed `K1`. The BLS12-381 examples instantiate the masking layer and are not implementations of the full hierarchical protocol. The one-value example uses the corrected extension-field representation described in [the publication map](references/references.md). The toy one-key example has two public values; the BLS12-381 one-key example has four. Its verifiers compare recovered keys with dealer-generated ground truth in two fresh runs. These checks support those demonstrations, not arbitrary inputs or a general security proof.

## Reproduce

The report identifies SageMath 10.9. Run commands from the repository root. Dealers overwrite only their own public transcript.

```sh
# Public-only attack: two masked values
sage attack/two_values/toy_model/dealer.sage
sage attack/two_values/toy_model/attacker.sage
sage attack/two_values/bls12_381/verify_attack.sage

# Attack after disclosure of K1
sage attack/one_key/toy_model/dealer.sage
sage attack/one_key/toy_model/attacker.sage
sage attack/one_key/bls12_381/verify_attack.sage

# Candidate search from a single public value
sage attack/one_value/dealer.sage
sage attack/one_value/attacker.sage
```

For a fresh BLS12-381 transcript, run the matching dealer and attacker directly. The one-key attacker prompts for the leaked `K1`; its verifier supplies that input automatically. The one-value attacker reports every consistent candidate, including ambiguous cases. Full experiment details, transcript formats, and validation boundaries are in [`attack/README.md`](attack/README.md).

## Repository map

- [`attack/two_values/`](attack/two_values/): public-only recovery using Frobenius identities.
- [`attack/one_key/`](attack/one_key/): recovery following disclosure of one secret.
- [`attack/one_value/`](attack/one_value/): candidate search for the corrected numerical fixture.
- [`CITATION.cff`](CITATION.cff): citation metadata for the software repository.
- [`references/references.md`](references/references.md): publications used, input provenance, fixtures, and numerical-encoding caveats.

## Citation and scope

The code is released under the MIT License. If using it, cite the report and publications listed in [`references/references.md`](references/references.md). The attacks apply to the specified common-base, prime-field-secret masking pattern. The computations illustrate the algebra under named finite-field fixtures; they do not claim hardware performance, a complete audit of the hierarchical protocol, or general cryptographic insecurity of pairings.
