# Let's Encrypt 2020 Hierarchy

Let's Encrypt is generating a new ECDSA P-384 root and new intermediates in
2020. We will be using [Boulder's `ceremony` tooling to generate these][ceremony].

This directory contains example config files that simulate the certificate
profiles we will generate in detail. To try it out:

 - install the `ceremony` tool in your $PATH
 - install SoftHSMv2
 - Update the YAML files, if necessary, to reflect that path to your SoftHSMv2
   install.
 - Run ./run.sh.
 - If you make any modifications, run ./reset.sh && ./run.sh.

[ceremony]: https://github.com/letsencrypt/boulder/blob/main/cmd/ceremony/README.md
