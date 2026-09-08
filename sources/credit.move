// Copyright (c) Miso Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Represents a party's credit on a work or activity.
/// A credit pairs a display name with one or more roles, identifying how
/// a party contributed to the work.
module credit::credit;

use std::string::String;

// === Structs ===

/// A credit attributing roles to a party on a work.
/// Generic over the role type to support domain-specific roles.
public struct Credit<Role: copy + drop + store> has copy, drop, store {
    /// Human-readable name to display for this credit.
    display_name: String,
    /// Roles assigned to the credited party.
    roles: vector<Role>,
}

// === Constants ===

/// Maximum length of a display name in bytes.
const MAX_DISPLAY_NAME_LENGTH: u64 = 200;
/// Minimum number of roles in a credit — a credit with no roles is meaningless.
const MIN_ROLES: u64 = 1;
/// Maximum number of roles in a credit. A sanity rail, not a domain rule:
/// consumers enforce their own (tighter) caps at their use sites; this bounds
/// the worst case for every consumer and keeps the duplicate check trivial.
const MAX_ROLES: u64 = 50;

// === Errors ===

// Constraint errors (30-39)
/// Display name exceeds maximum length.
const EMaxDisplayNameLengthExceeded: u64 = 30;
/// String must not be empty.
const EEmptyString: u64 = 31;
/// Credit must have at least one role.
const ENoRoles: u64 = 32;
/// Credit has too many roles.
const EMaxRolesExceeded: u64 = 33;

// Conflict errors (40-49)
/// Credit contains duplicate roles.
const EDuplicateRoles: u64 = 40;

// === Public Functions ===

/// Creates a new credit with the given display name and roles.
/// Requires 1 to `MAX_ROLES` roles; aborts with `EDuplicateRoles` if roles
/// contains duplicates.
public fun new<Role: copy + drop + store>(display_name: String, roles: vector<Role>): Credit<Role> {
    assert!(!display_name.is_empty(), EEmptyString);
    assert!(display_name.length() <= MAX_DISPLAY_NAME_LENGTH, EMaxDisplayNameLengthExceeded);
    assert!(roles.length() >= MIN_ROLES, ENoRoles);
    assert!(roles.length() <= MAX_ROLES, EMaxRolesExceeded);
    let len = roles.length();
    let mut i = 0;
    while (i < len) {
        let mut j = i + 1;
        while (j < len) {
            assert!(&roles[i] != &roles[j], EDuplicateRoles);
            j = j + 1;
        };
        i = i + 1;
    };
    Credit { display_name, roles }
}

// === Public View Functions ===

/// Returns the display name for this credit.
public fun display_name<Role: copy + drop + store>(self: &Credit<Role>): &String {
    &self.display_name
}

/// Returns a reference to the roles assigned in this credit.
public fun roles<Role: copy + drop + store>(self: &Credit<Role>): &vector<Role> {
    &self.roles
}
