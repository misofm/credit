# Security Audit — `credit`

Audited at `a5ad1f65e0ef905d204857b519aaa7964abd5d0f` (2026-10-21). Scope: package `credit`, module `credit::credit` (`sources/credit.move`); depends only on the Sui framework.

## What it does

A validated value type, `Credit<Role>`: a display name plus one or more distinct roles. The credits extensions in `music-protocol-extensions` (`recording_credits`, `release_credits`, `composition_credits`) store it. See [README](./README.md).

## Trust model

- No state, objects, capabilities, events or dynamic fields.
- **Anyone** may build a `Credit<Role>` for any `Role: copy + drop + store` through `new` (`credit.move:33-52`).
- **Nobody** can build or modify a `Credit` outside `new`. Its fields are private and there are no mutators, so every value satisfies the constructor's invariants for its whole life (`credit.move:26-29`).
- Which party may attach a credit to a work is decided entirely by the consuming extension.

## Findings

**C-1 · Info · Accepted — the display name's content is unrestricted.** Only emptiness and byte length are checked (`credit.move:37-38`). Whitespace-only names, control characters and bidi overrides such as U+202E are accepted (verified by probe). Rendering and normalization are client concerns.

**C-2 · Info · Accepted — the size of `Role` is chosen by the consumer.** The 50-role cap bounds the count but not the size of each role, so a `Role` with a payload (such as `vector<u8>`) makes a credit's size, and the cost of the pairwise check, unbounded by this package (probe with two 10 kB roles passed). All current consumers use small fieldless enums.

**C-3 · Info · Accepted — error codes do not follow check order.** `EEmptyString` (1) is checked before `EMaxDisplayNameLengthExceeded` (0) (`credit.move:12-13`, `37-38`). This has no functional effect.

## Checked, no finding

- Abort order is empty name → name too long → no roles → too many roles → duplicate (`credit.move:37-46`). An empty name with no roles aborts `EEmptyString`. A 201-byte name with no roles aborts `EMaxDisplayNameLengthExceeded`. Fifty-one identical roles abort `EMaxRolesExceeded` before the duplicate check runs. All verified by probes.
- Length is counted in bytes: a 201-byte name made of 3-byte characters aborts (probe).
- The duplicate check compares every pair with `i < j` (`credit.move:41-50`), so it catches non-adjacent duplicates (probe `A,B,C,A`). With at most 50 roles that is at most 1,225 comparisons.
- Credits with different `Role` types are distinct types, so they cannot alias.
- Consumers at the audited pin (`music-protocol-extensions`, credit rev `a5ad1f6`): `recording_credits` adds a cap of 10 roles per credit (`recording_credits.move:91`); `release_credits` requires exactly one role (`release_credits.move:60`); `composition_credits` relies on this package's 50-role cap, which is effectively bounded by its six-variant role enum. No economic module reads credits.

## Operational requirements

- `Published.toml` records mainnet and testnet publications that predate the current source. The abort codes have since been renumbered (30–33, 40 → 0–4), so the deployed bytecode does not match this audit. The current source must be published fresh, and indexers or clients that decode abort codes must use the new numbers.

## Verification

- `sui move test --coverage`: 9/9 pass. `sui move coverage summary`: 100.00% (`credit`).
- `sui move build -e mainnet --warnings-are-errors` and `-e testnet`: both succeed with no warnings (sui 1.82.1).
- 10 throwaway probe tests (abort order, multibyte length, non-adjacent duplicates, unrestricted name content, large role payload) all passed. They were not committed.
