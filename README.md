# Let's Encrypt 2020 Hierarchy

Let's Encrypt generated ECDSA P-384 root and new intermediates in
2020. We will used [Boulder's `ceremony` tooling to generate these][ceremony].

This directory contains example config files that simulated the certificate
profiles in detail. We used it to gather feedback prior to our key ceremony.
To try it out:

 - install the `ceremony` tool in your $PATH
 - install SoftHSMv2
 - Update the YAML files, if necessary, to reflect that path to your SoftHSMv2
   install.
 - Run ./run.sh.
 - If you make any modifications, run ./reset.sh && ./run.sh.

[ceremony]: https://github.com/letsencrypt/boulder/blob/main/cmd/ceremony/README.md
