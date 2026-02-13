# TEMPORARY - Remove after successful import
# Import the domain registration from root account state into this configuration.
# Prerequisites:
#   1. Root account repo has applied `removed { lifecycle { destroy = false } }`
#   2. `terraform init` has been run with both providers configured

import {
  to = aws_route53domains_registered_domain.camdenwander
  id = "camdenwander.com"
}
