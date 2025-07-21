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
	bySKID := make(map[string]*certificate)
	// Key: raw Subject
	bySubject := make(map[string]*certificate)

	var errors bool
	for _, c := range certs {
		skid := hex.EncodeToString(c.SubjectKeyId)
		if otherCert, ok := bySKID[skid]; ok && !bytes.Equal(c.RawSubject, otherCert.RawSubject) {
			fmt.Fprintf(os.Stderr, "SKID %s has conflicting subjects in %s and %s: %s vs %s\n",
				skid, c.filename, otherCert.filename, c.Subject, otherCert.Subject)
			errors = true
		}

		if otherCert, ok := bySubject[string(c.RawSubject)]; ok && !bytes.Equal(c.SubjectKeyId, otherCert.SubjectKeyId) {
			fmt.Fprintf(os.Stderr, "subject %s has conflicting SKIDs in %s and %s: %x vs %x\n",
				c.Subject, c.filename, otherCert.filename, c.SubjectKeyId, otherCert.SubjectKeyId)
			errors = true
		}

		bySKID[skid] = c
		bySubject[string(c.RawSubject)] = c
	}

	if errors {
		os.Exit(1)
	}
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
