# hlint

This checks a pile of certificates for consistent correspondence of Subject to
subjectKeyIdentifier (SKID), and vice versa. If a single Subject appears with
different SKIDs, or a single SKID appears with different Subjects, it produces
an error.

Note that this is an opinionated tool: the is no general prohibition on distinct
Subjects sharing a public key (and thus a SKID), but it is not our practice or
intention to do so.

## Usage

```
hlint *.cert.pem
```
