package main

import (
	"bytes"
	"crypto/x509"
	"encoding/hex"
	"encoding/pem"
	"fmt"
	"io/ioutil"
	"log"
	"os"
)

type certificate struct {
	*x509.Certificate
	filename string
}

func main() {
	var certs []*certificate
	for _, f := range os.Args[1:] {
		c, err := readCert(f)
		if err != nil {
			log.Fatal(err)
		}
		certs = append(certs, c)
	}

	// Key: hex bytes of SKID
	bySKID := make(map[string][]*certificate)
	// Key: raw Subject
	bySubject := make(map[string][]*certificate)

	var errors bool
	for _, c := range certs {
		skid := hex.EncodeToString(c.SubjectKeyId)
		if skid == "" {
			fmt.Fprintf(os.Stderr, "no SKID in %q\n", c.filename)
		}
		if otherCerts, ok := bySKID[skid]; ok && !bytes.Equal(c.RawSubject, otherCerts[0].RawSubject) {
			fmt.Fprintf(os.Stderr, "SKID %s has conflicting subjects in %q and %q: %q vs %q\n",
				skid, c.filename, otherCerts[0].filename, c.Subject, otherCerts[0].Subject)
			errors = true
		}

		if otherCerts, ok := bySubject[string(c.RawSubject)]; ok && !bytes.Equal(c.SubjectKeyId, otherCerts[0].SubjectKeyId) {
			fmt.Fprintf(os.Stderr, "subject %s has conflicting SKIDs in %q and %q: %q vs %q\n",
				c.Subject, c.filename, otherCerts[0].filename, c.SubjectKeyId, otherCerts[0].SubjectKeyId)
			errors = true
		}

		bySKID[skid] = append(bySKID[skid], c)
		subject := string(c.RawSubject)
		bySubject[subject] = append(bySubject[subject], c)
	}

	// For each certificate, if any other certificate in our pool represents its issuer (has an AKID matching its SKID),
	// verify the signature from that issuer using that certificate.
	var verified int
	for _, c := range certs {
		akid := hex.EncodeToString(c.AuthorityKeyId)

		// First, find issuers by the Authority Key Identifier (AKID)
		//
		// Self-signed certificates, may have an empty AKID, in which case we skip this.
		//
		// https://datatracker.ietf.org/doc/html/rfc5280#section-4.2.1.1
		//     where a CA distributes its public key in the form of a "self-signed"
		//     certificate, the authority key identifier MAY be omitted.
		// https://cabforum.org/working-groups/server/baseline-requirements/requirements/#71212-root-ca-extensions
		//     7.1.2.1.2 Root CA Extensions
		//     authorityKeyIdentifier	RECOMMENDED
		selfSigned := bytes.Equal(c.RawIssuer, c.RawSubject)
		if akid == "" && !selfSigned {
			fmt.Fprintf(os.Stderr, "no AuthorityKeyId in %q\n", c.filename)
		}

		issuers := bySKID[akid]
		if len(issuers) == 0 && akid != "" {
			fmt.Fprintf(os.Stderr, "no issuer (by AKID) in provided hierarchy for %q (%s)\n", c.filename, akid)
			errors = true
		}

		for _, issuer := range issuers {
			err := c.CheckSignatureFrom(issuer.Certificate)
			if err != nil {
				fmt.Fprintf(os.Stderr, "signature mismatch for %q signing %q: %v\n", issuer.filename, c.filename, err)
				errors = true
			}
			verified++
		}

		// Second, find issuers by the Issuer distinguishedName.
		issuerDN := string(c.RawIssuer)
		issuers = bySubject[issuerDN]
		if len(issuers) == 0 {
			fmt.Fprintf(os.Stderr, "no issuer (by distinguishedName) found in listed hierarchy for %q (%q)\n", c.filename, c.Issuer)
			errors = true
		}

		for _, issuer := range issuers {
			err := c.CheckSignatureFrom(issuer.Certificate)
			if err != nil {
				fmt.Fprintf(os.Stderr, "signature mismatch for %q signing %q: %v\n", issuer.filename, c.filename, err)
				errors = true
			}
			verified++
		}
	}

	if errors {
		os.Exit(1)
	}

	fmt.Printf("Read %d certificates and verified %d signatures\n", len(certs), verified)
}

func readCert(filename string) (*certificate, error) {
	bytes, err := ioutil.ReadFile(filename)
	if err != nil {
		return nil, fmt.Errorf("error reading %s: %v", filename, err)
	}
	block, _ := pem.Decode(bytes)
	if block == nil {
		return nil, fmt.Errorf("no PEM data in %s", filename)
	}
	if block.Type != "CERTIFICATE" {
		return nil, fmt.Errorf("%s is not a certificate", filename)
	}
	cert, err := x509.ParseCertificate(block.Bytes)
	if err != nil {
		return nil, fmt.Errorf("error parsing %s: %v", filename, err)
	}
	return &certificate{cert, filename}, nil
}
