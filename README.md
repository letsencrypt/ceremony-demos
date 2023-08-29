# Let's Encrypt Key Ceremony Demos

This directory contains example config files that simulate certificate profiles
used by Let's Encrypt for various key ceremonies in detail. The primary goal is
to gather feedback prior to upcoming key ceremonies. The repository will also
serve as a historical marker of past ceremonies detailing the evolution of the
[Let's Encrypt chain of trust](https://letsencrypt.org/certificates/).

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
  ./reset.sh && ./run.sh
  ```

- If you're working on a specific branch of boulder making changes to the `ceremony` tool and need to test an uncoming ceremony:

  ```sh
  export _CEREMONY_BIN=/path/to/active/development/boulder/bin/ceremony
  ./run.sh
  ```
