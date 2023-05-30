# Let's Encrypt 2023 Ceremony

Let's Encrypt plans to generate new intermediates (both RSA 2048 and ECDSA P-384) in 2023, to complement the cohort of existing intermediates (R3, R4, E1, and E2) already present in our [hierarchy](https://letsencrypt.org/certificates/).

This directory contains example config files that simulated the certificate
profiles in detail. We are using it to gather feedback prior to our key ceremony.

To try it out:

- Install the [`ceremony`](https://github.com/letsencrypt/boulder/blob/main/cmd/ceremony/README.md) tool in your `$PATH`.

  ```sh
  go install https://github.com/letsencrypt/boulder/cmd/ceremony
  ```

- Install [SoftHSMv2](https://github.com/opendnssec/SoftHSMv2).

  ```sh
  sudo apt install softhsm2
  ```

- Update the YAML files, if necessary, to reflect that path to your SoftHSMv2
  install.

- Execute the demo ceremony.

  ```sh
  ./reset.sh && ./run.sh`
  ```
