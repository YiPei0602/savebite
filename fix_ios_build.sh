#!/bin/bash
# Quick fix script for Xcode 26 BoringSSL path issues
# Run this after 'pod install' or before 'flutter run'

cd "$(dirname "$0")/ios"

echo "Fixing BoringSSL paths for Xcode 26..."

BORING_SSL_DIR="Pods/Target Support Files/BoringSSL-GRPC"
BORING_SSL_RPC_DIR="Pods/Target Support Files/BoringSSL RPC"

if [ -d "$BORING_SSL_DIR" ]; then
    mkdir -p "$BORING_SSL_RPC_DIR"
    echo "Copying files from BoringSSL-GRPC to BoringSSL RPC..."
    for file in "$BORING_SSL_DIR"/*; do
        if [ -f "$file" ]; then
            basename=$(basename "$file")
            newname=$(echo "$basename" | sed 's/BoringSSL-GRPC/BoringSSL RPC/g')
            cp "$file" "$BORING_SSL_RPC_DIR/$newname"
            echo "  ✓ $newname"
        fi
    done
    echo "✓ Fixed! You can now run 'flutter run -d iPhone 17'"
else
    echo "⚠ Error: BoringSSL-GRPC directory not found. Run 'pod install' first."
    exit 1
fi

