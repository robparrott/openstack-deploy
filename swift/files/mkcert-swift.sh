#!/bin/sh

# Generates a self-signed certificate.
# Edit swift-openssl.cnf before running this.

OPENSSL=${OPENSSL-openssl}
SSLDIR=${SSLDIR-/etc/ssl}
OPENSSLCONFIG=${OPENSSLCONFIG-/etc/swift/swift-openssl.cnf}

CERTDIR=/etc/swift
KEYDIR=$CERTDIR

CERTFILE=$CERTDIR/cert.crt
KEYFILE=$KEYDIR/cert.key

$OPENSSL req -new -x509 -nodes -config $OPENSSLCONFIG -out $CERTFILE -keyout $KEYFILE -days 365 || exit 2
chmod 0600 $KEYFILE
echo 
$OPENSSL x509 -subject -fingerprint -noout -in $CERTFILE || exit 2
