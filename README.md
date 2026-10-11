# Elliptic Curve Multi-Secret Sharing

SageMath implementation and security experiments for Chintamani, Paul, and Sa's *Conjunctive Hierarchical Multi-Secret Sharing Scheme using Elliptic Curves*.

## Scope

[`chmss_two_level_demo.sage`](chmss_two_level_demo.sage) demonstrates the scheme through Levels 1 and 2 with one secret. It constructs scalar and elliptic-curve point shares, reconstructs the coefficient points and \(Q\), and recovers \(K_1=8\) using the modified Tate pairing. The example uses toy parameters and the corrected extension-field configuration documented in [`paper/references.md`](paper/references.md).

The repository also implements two algebraic attacks and a fixture-specific recovery demonstration for the scheme's secret-masking construction:

- **One-key recovery:** Recover the remaining secrets after one secret is compromised.
- **Two-value recovery:** Recover the mask and secrets from two public masked values, without a prior secret compromise.
- **One-value recovery demonstration:** Recover \(K_1=8\) from a single public masked value in the corrected numerical fixture. Other valid inputs can leave multiple candidates.

The one-key and two-value attacks include both toy-field and BLS12-381 experiments. The BLS12-381 experiments include verification scripts that compare the recovered secrets against freshly generated dealer secrets.

The report presents the three recovery arguments step by step:
- [Read the report (PDF)](attack/report/three_recovery_attacks.pdf)
- [View the LaTeX source](attack/report/three_recovery_attacks.tex)

These attacks exploit algebraic relationships in the published values; they do not break the elliptic-curve discrete logarithm problem (ECDLP).

The scheme demonstration currently covers two levels and one secret. The attack experiments focus on the secret-masking step rather than implementing the complete hierarchical scheme or benchmarking its performance. One-value recovery is demonstrated for the specified numerical example; it is not claimed to uniquely recover the secret in every configuration.

For the attack mathematics, experiment structure, setup, and run instructions, see [`attack/README.md`](attack/README.md). The source-paper citation and implementation mapping are provided in [`paper/references.md`](paper/references.md).
