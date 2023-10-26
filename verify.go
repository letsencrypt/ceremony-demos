// This program loads a group of certificates provided on the command line
// and verifies certain properties for consistency between certificates:
// - All certificates with the same Issuer string should have the same RawIssuer
// - All certificates with the same Subject string should have the same RawIssuer
// - All certificates with the same Issuer should have the same CRL and AIA Issuer URLs
// - All certificates with the same Subject should have the same public key.
package main

import (
	"bytes"
	"crypto/x509"
	"encoding/pem"
	"fmt"
	"io/ioutil"
	"log"
	"os"
)

// loadCert loads a PEM certificate specified by filename or returns an error
func loadCert(filename string) (cert *x509.Certificate, err error) {
	certPEM, err := ioutil.ReadFile(filename)
	if err != nil {
		return
	}
	block, _ := pem.Decode(certPEM)
	if block == nil {
		return nil, fmt.Errorf("No data in cert PEM file %s", filename)
	}
	cert, err = x509.ParseCertificate(block.Bytes)
	return
}

func main() {
	if err := main2(); err != nil {
		log.Fatal(err)
	}
}

type myCert struct {
	*x509.Certificate
	filename string
}

func main2() error {
	var certs []myCert
	for _, fn := range os.Args[1:] {
		cert, err := loadCert(fn)
		if err != nil {
			return err
		}
		certs = append(certs, myCert{cert, fn})
	}

	var certsByIssuer = make(map[string][]myCert)
	var certsBySubject = make(map[string][]myCert)
	for _, c := range certs {
		certsByIssuer[c.Issuer.String()] = append(certsByIssuer[c.Issuer.String()], c)
		certsBySubject[c.Subject.String()] = append(certsBySubject[c.Subject.String()], c)
	}
	fmt.Println("\nCerts by issuer:")
	for k, v := range certsByIssuer {
		fmt.Println(k)
		var rawIssuer = v[0].RawIssuer
		var issuerURL, crlURL string
		for _, c := range v {
			fmt.Println("  ", c.Subject)
			if !bytes.Equal(rawIssuer, c.RawIssuer) {
				return fmt.Errorf("%s has a mismatch in raw issuer", c.filename)
			}
			if len(c.CRLDistributionPoints) > 0 {
				if crlURL == "" && len(c.CRLDistributionPoints) > 0 {
					crlURL = c.CRLDistributionPoints[0]
				} else if crlURL != c.CRLDistributionPoints[0] {
					return fmt.Errorf("certificate %s has mismatching CRL URL: %q vs %q",
						c.filename, crlURL, c.CRLDistributionPoints)
				}
			}
			if len(c.IssuingCertificateURL) > 0 {
				if issuerURL == "" && len(c.IssuingCertificateURL) > 0 {
					issuerURL = c.IssuingCertificateURL[0]
				} else if issuerURL != c.IssuingCertificateURL[0] {
					return fmt.Errorf("certificate %s has mismatching issuer URL: %q vs %q",
						c.filename, issuerURL, c.IssuingCertificateURL)
				}
			}
		}
	}

	fmt.Println("\nCerts by subject:")
	for k, v := range certsBySubject {
		fmt.Printf("%s %d;", k, len(v))

		var rawSubject = v[0].RawSubject
		pubkeyBytes, err := x509.MarshalPKIXPublicKey(v[0].PublicKey)
		if err != nil {
			return err
		}
		for _, c := range v {
			fmt.Printf(" %s", c.filename)
			if !bytes.Equal(rawSubject, c.RawSubject) {
				return fmt.Errorf("%s has a mismatch in raw subject", c.filename)
			}
			pubkeyBytes2, err := x509.MarshalPKIXPublicKey(c.PublicKey)
			if err != nil {
				return err
			}
			if !bytes.Equal(pubkeyBytes, pubkeyBytes2) {
				return fmt.Errorf("%s has a mismatch in public key", c.filename)
			}
		}
		fmt.Printf("\n")
	}
	return nil
}
