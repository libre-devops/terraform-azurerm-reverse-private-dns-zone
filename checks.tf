# check blocks run after every plan and apply and emit a warning (without blocking) when an
# invariant is violated.

# In classful mode a non-octet CIDR lands in a containing zone that also covers addresses
# OUTSIDE the vnet (a /22 in its /16 zone) and shadows reverse resolution for that whole range
# in linked vnets. Classless mode (the default) derives exact dash-form zones instead.
check "wide_containing_zones_are_visible" {
  assert {
    condition = var.use_classless_zones || alltrue([
      for id, v in data.azurerm_virtual_network.this : alltrue([
        for c in v.address_space :
        tonumber(split("/", c)[1]) % 8 == 0
      ])
    ])
    error_message = "Classful mode with a non-octet vnet CIDR: its reverse zone covers a wider range than the vnet and shadows reverse resolution for all of it in linked vnets. Consider use_classless_zones = true (the documented dash-form zones are exact to the range)."
  }
}
