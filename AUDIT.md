# Security Audit — `credit`

**Revision:** working tree @ 2026-08-23 (the `misonetwork` workspace is not a
git repository — `git rev-parse` fails; no commit hash exists). No
dependencies. **Date:** 2026-08-23 · **Toolchain:** sui 1.77.2-51d177ad7d65

Audit of `credit` (67 LOC, `sources/credit.move`), the `Credit<Role>`
value type consumed by the three credits extensions (`recording_credits`,
`release_credits`, `composition_credits`). Verdict: **safe to publish — no
findings.**

## What it does

`Credit<Role: copy + drop + store>` (`credit.move:31`) pairs a `display_name:
String` with `roles: vector<Role>` — pure attribution data with `copy, drop,
store`. The only constructor, `new` (`credit.move:38`), enforces:

- non-empty display name, ≤ 200 bytes (`credit.move:42-43`);
- 1–50 roles (`credit.move:44-45`, `MIN_ROLES`/`MAX_ROLES` at
  `credit.move:23-27`);
- no duplicate roles, via an O(n²) pairwise check (`credit.move:46-55`).

Getters `display_name`/`roles` (`credit.move:61,65`) return read-only borrows.
Fields are private; there are no mutators, so every `Credit` value that exists
satisfies the constructor invariants for its whole life — the credits
extensions rely on exactly this (e.g. `recording_credits` checks only its own
upper role bound and relies on `credit::new` for non-emptiness, `credit.move:44`).

## Threat model

This package is a value type, not a system: it has no state, no capabilities,
no dynamic fields, and touches no objects. The only money-adjacent question is
whether credits data can redirect royalties — **it cannot**: attribution is
never read by the economics. Verified by grepping all Move sources in the
workspace: only the three credits extensions and their tests import
`credit`, and `royalty-pool` contains no reference to any credits module.
Royalties flow through share ownership and royalty pools, never through
credits.

Residual threats and why they fail:

- **Unbounded duplicate check DoS:** the O(n²) loop is capped by
  `MAX_ROLES = 50` (`credit.move:27`), so ≤ 1,225 comparisons of small enum
  values — trivial gas, and the caller pays it.
- **Invariant bypass:** impossible outside this module — private fields, single
  constructor, no `public`/`public(package)` mutators.
- **Phantom/generic confusion:** `Role` is constrained `copy + drop + store`;
  the extensions instantiate it with their own closed role enums. Two credits
  with different `Role` types are distinct types and can never alias.

## Findings

None.

## Edge cases verified

- Empty name, >200-byte name, zero roles, >50 roles, duplicate roles — each
  aborts with its dedicated code; all covered by tests.
- Duplicate check catches non-adjacent duplicates (pairwise over all `i < j`,
  `credit.move:48-55`).
- The 50-role ceiling bounds worst-case storage of a credit embedded in a
  credits-extension dynamic field (extensions impose tighter per-use caps:
  10 roles/recording credit, 5/composition, exactly 1/release).

## Verification

- **9/9 unit tests pass** (`sui move test`), covering every abort
  gate and multi-role happy paths.
