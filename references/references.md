# Publications used by the report and experiments

The report's bibliography contains the three publications actually used. The first two establish prior pairing based multi-secret sharing context; the third is the target construction and supplies the masking equation and toy numerical example analyzed here.

1. V. P. Binu and A. Sreekumar, “Threshold multi secret sharing using elliptic curve and pairing,” *International Journal of Information Processing* 9(4), 100–112 (2015). Cited in the report's introduction as an example of pairing based threshold multi-secret sharing.
2. M. Bahramian and K. Eslami, “A new verifiable multi-secret sharing scheme based on elliptic curves and pairings,” *Italian Journal of Pure and Applied Mathematics* 41, 456–468 (2019). Cited in the report's introduction as related pairing based multi-secret sharing work.
3. M. Chintamani, P. Paul, and L. Sa, “Conjunctive hierarchical multi-secret sharing scheme using elliptic curves,” *Indian Journal of Pure and Applied Mathematics* 55, 1456–1464 (2024), [doi:10.1007/s13226-023-00450-x](https://doi.org/10.1007/s13226-023-00450-x). Sections 2, 3.1, 3.2, and 5 inform the pairing/masking notation, prime-field secret restriction, target public-value formula, and toy fixture. The attacks themselves are deductions from these equations; they are not attributed to the source authors.

## Implementation and input provenance

The three attack implementations are under [`attack/`](../attack/README.md). The public input to each attacker is the transcript of masked values $v_i$, stored as `public_values.txt`, plus the public field/subgroup encoding parameters. The toy and BLS12-381 dealer scripts generate demonstration transcripts; they are experimental input producers, not the source of a real deployment's data. In an application of the attack, the adversary would obtain the same $v_i$ values from the scheme's public bulletin or publication channel. The attacker does not need curve public keys, participant shares, $Q$, dealer state, or a pairing computation.

For the one-secret-disclosure attack, the attacker additionally receives the explicitly disclosed $K_1$ (typed by the user in a standalone BLS12-381 run and passed through standard input by its verifier). The one-public-value search reads only $v_1$ and public field/subgroup parameters. The two-public-value attack reads at least $v_1,v_2$ and then uses any remaining published $v_i$ values to recover their corresponding secrets after recovering $z$.

## Numerical and scope notes

The source paper suggests $X^3+X+4$ while retaining point coordinates that do not satisfy the printed curve equation under that field representation. The local toy code instead uses $X^3+3X+42$, which makes the printed point coordinates consistent. This is a corrected encoding, not a literal reproduction of the suggested polynomial and coordinates together.

The one-value demonstration uses the corrected encoding and the paper's first public masked value for $Q=13P$, $K_1=8$. The one-key and two-value toy transcripts use the local $Q=7P$ fixture. The BLS12-381 experiments instantiate the same masking relation with standard $G_1/G_2$ generators and a reduced Tate pairing; these are local masking-layer experiments, not parameters or a full protocol implementation from publication 3.

The accompanying paper, *Cryptanalysis of Pairing-Based Additive Masking with Prime-Field Secrets*, is maintained separately from this code repository and contains the derivations and computational analysis. See the [attack guide](../attack/README.md) for commands, transcript formats, and verifier limits.
