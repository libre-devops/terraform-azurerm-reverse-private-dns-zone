# check blocks run after every plan and apply and emit a warning (without blocking) when an
# invariant is violated.

# A vnet CIDR wider than /24 lands in a containing zone that also covers addresses OUTSIDE the
# vnet (a /22 in its /16 zone). That is harmless for private resolution but worth a conscious
# look when the same /16 hosts unrelated networks elsewhere in the estate.
check "wide_containing_zones_are_visible" {
  assert {
    condition = alltrue([
      for id, v in data.azurerm_virtual_network.this : alltrue([
        for c in v.address_space :
        tonumber(split("/", c)[1]) % 8 == 0
      ])
    ])
    error_message = "At least one vnet CIDR is not octet-aligned, so its reverse zone covers a wider range than the vnet itself (a /22 lands in its /16 zone). Fine for private resolution; confirm no unrelated network elsewhere expects to own that zone."
  }
}
