#!/bin/bash
# Flutter build hook to fix BoringSSL paths before Xcode build
# This runs automatically before each Flutter build

cd "$(dirname "$0")"

BORING_SSL_DIR="Pods/Target Support Files/BoringSSL-GRPC"
BORING_SSL_RPC_DIR="Pods/Target Support Files/BoringSSL RPC"

if [ -d "$BORING_SSL_DIR" ]; then
    mkdir -p "$BORING_SSL_RPC_DIR"
    for file in "$BORING_SSL_DIR"/*; do
        if [ -f "$file" ]; then
            basename=$(basename "$file")
            newname=$(echo "$basename" | sed 's/BoringSSL-GRPC/BoringSSL RPC/g')
            cp "$file" "$BORING_SSL_RPC_DIR/$newname"
        fi
    done
fi

