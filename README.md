# Let's Encrypt Key Ceremony Demos

This repository contains ceremony config files nearly identical to those used
for various root and intermediate ceremonies conducted by Let's Encrypt over its
history. You can see the outcomes of those real ceremonies on the [Let's Encrypt
Chains of Trust](https://letsencrypt.org/certificates/) page. You can inspect
the configs for each historical ceremony in //ceremonies/YYYY, and the
corresponding outputs (demo public keys and certs, but not private keys and not
the *real* outputs produced by the actual ceremonies) in //outputs/YYYY.

It is also used to develop and demonstrate new config files for upcoming ceremonies. To prepare for an upcoming ceremony:

- Install [SoftHSMv2](https://github.com/opendnssec/SoftHSMv2):

  ```sh
  sudo apt install softhsm2
  ```

- Create a new //ceremonies/YYYY subdirectory, and populate it with:
  - a README.md describing the ceremony;
  - the necessary yaml files for the kind of ceremony you're preparing; and
  - a run.sh which pins a specific version of the boulder ceremony tool to use.

- Add your new ceremony's run.sh to run-all.sh.

- Execute the ceremonies. Note that it's not generally feasible to execute only
  the newest ceremony: this is because many ceremonies involve cross-signs from
  previously-generated roots, and that requires access to those roots' private keys. Since we don't check any private keys into this repo, you have to regenerate everything from the beginning of time:

  ```sh
  ./reset.sh && ./run-all.sh
  ```

- Once you're happy with the results, update the //outputs directory with the
  results from your new ceremony, and updated versions of all the historical
  ceremonies:

  ```sh
  ./update-output-files.sh
  ```

If you're working on making changes to the boulder ceremony tool itself, you can point the various run.sh scripts at a specific binary using the `CEREMONY_BIN_YYYY` environment variables, for example:

```sh
export CEREMONY_BIN_2025=/path/to/active/development/boulder/bin/ceremony
rm ceremonies/2025/*.pem && ./ceremonies/2025/run.sh
  ```

If you run into difficulties communicating with the softhsm when you do this, you may also need to explicitly point it at the repo's config file:

```sh
export SOFTHSM2_CONF="$(pwd)/softhsm2.conf"
rm ceremonies/2025/*.pem && ./ceremonies/2025/run.sh
```
