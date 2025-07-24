# 2025 Root and Intermediate Ceremony

The 2025 ceremony includes:

* The creation of two new roots, Root YE and Root YR, the ECDSA and RSA roots in our Y generation, respectively.
* Cross-signs of each of those new roots from our old roots, ISRG Root X1 and ISRG Root X2, as well as a renewal of the cross-sign of X2 from X1 for maximum compatibility.
* Three new ECDSA P-384 intermediates under Root YE, named YE1, YE2, and YE3.
* Three new 2048-bit RSA intermediates under Root YR, named YR1, YR2, and YR3.

This hierarchy differs from our prior hierarchy in a few key ways:

1. We are generating two roots (one of each algorithm) instead of just one at a time. This will allow us to move our RSA and ECDSA (and potentially future post-quantum) hierarchies forward in lockstep, without having to worry about different ages and levels of ubiquity between them.
2. Thanks to this generational approach, we've also adopted a new naming scheme. This new generation of our hierarchy is designated as "generation Y" (appropriately following our current "generation X"), with the roots named "Root YR" and "Root YE", respectively. The intermediates under each of those roots share their name, and are differentiated by small integers, so the intermediates are named "YR1", "YR2", etc. Because we'll be able to reset the intermediate numbering every time we issue a new generation of roots, we expect the numbers to stay smaller than our current intermediate "R14".
3. Speaking of names, we're shortening those. Our new roots have a Subject Organization Name of simply "ISRG" (rather than the much longer "Internet Security Research Group"), and they have dropped the redundant "ISRG" from their Subject Common Names. This is part of our constant efforts to minimize the number of bytes transmitted during every TLS handshake, to help save global bandwidth.
4. The cross-signs onto these new roots have 7-year validity periods, rather than the 5-year validity period used by our prior X2-by-X1 cross-sign. This is so that the cross-signs won't be quite on the verge of expiring when the time of our next root ceremony (presumably 2030) approaches.
5. Finally, and perhaps most imporantly, none of the new intermediates assert the `tlsClientAuth` Extended Key Usage. This is to comply with modern Root Program requirements which state that "All corresponding unexpired and unrevoked subordinate CA certificates operated beneath an applicant root CA MUST, when disclosed to the CCADB on or after June 15, 2025, include the extendedKeyUsage extension and only assert an extendedKeyUsage purpose of id-kp-serverAuth." This means that all Subscriber certificates issued by this hierarchy will be serverAuth-only, as we [already announced](https://letsencrypt.org/2025/05/14/ending-tls-client-authentication/).
