#!/bin/bash

# Flutter Development Environment Setup Script
# This script configures your environment for Flutter development

echo "🔧 Setting up Flutter development environment..."

# Set Java 17 as default
export JAVA_HOME=/opt/homebrew/opt/openjdk@17
export PATH="$JAVA_HOME/bin:$PATH"

# Add to shell profile for persistence
SHELL_PROFILE="$HOME/.zshrc"

if ! grep -q "JAVA_HOME=/opt/homebrew/opt/openjdk@17" "$SHELL_PROFILE"; then
    echo "" >> "$SHELL_PROFILE"
    echo "# Java 17 for Flutter/Android development" >> "$SHELL_PROFILE"
    echo "export JAVA_HOME=/opt/homebrew/opt/openjdk@17" >> "$SHELL_PROFILE"
    echo "export PATH=\"\$JAVA_HOME/bin:\$PATH\"" >> "$SHELL_PROFILE"
    echo "✅ Added Java 17 to $SHELL_PROFILE"
else
    echo "✅ Java 17 already configured in $SHELL_PROFILE"
fi

# Symlink Java 17 for system-wide access (requires sudo)
if [ ! -L "/Library/Java/JavaVirtualMachines/openjdk-17.jdk" ]; then
    echo "🔐 Symlinking Java 17 (requires sudo password)..."
    sudo ln -sfn /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk
    echo "✅ Java 17 symlinked"
else
    echo "✅ Java 17 already symlinked"
fi

# Verify Java version
echo ""
echo "📋 Current Java version:"
java -version

echo ""
echo "✅ Environment setup complete!"
echo ""
echo "Next steps:"
echo "1. Accept Android licenses: flutter doctor --android-licenses"
echo "2. Run: source ~/.zshrc (or restart terminal)"
echo "3. Verify setup: flutter doctor -v"
