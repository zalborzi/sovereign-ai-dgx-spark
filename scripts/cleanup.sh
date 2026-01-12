#!/bin/bash
# cleanup.sh - Completely remove k3s and all related components
# Run with: sudo ./cleanup.sh

set -e

echo "=== Sovereign AI DGX Spark Cleanup ==="
echo ""

# Uninstall k3s
if [ -f /usr/local/bin/k3s-uninstall.sh ]; then
    echo "[1/5] Uninstalling k3s..."
    /usr/local/bin/k3s-uninstall.sh
else
    echo "[1/5] k3s not installed, skipping..."
fi

# Remove Helm
echo "[2/5] Removing Helm..."
rm -f /usr/local/bin/helm

# Clean up directories
echo "[3/5] Cleaning up directories..."
rm -rf /etc/rancher
rm -rf /var/lib/rancher

# Clean up user directories (run as user, not root)
echo "[4/5] Cleaning up user config..."
rm -rf ~/.config/helm
rm -rf ~/.cache/helm
rm -rf ~/.kube

# Verify
echo "[5/5] Verifying cleanup..."
echo ""

if command -v kubectl &> /dev/null; then
    echo "WARNING: kubectl still found"
else
    echo "✓ kubectl removed"
fi

if command -v helm &> /dev/null; then
    echo "WARNING: helm still found"
else
    echo "✓ helm removed"
fi

if command -v nvidia-smi &> /dev/null; then
    echo "✓ NVIDIA driver intact"
    nvidia-smi --query-gpu=name,driver_version --format=csv,noheader
else
    echo "WARNING: nvidia-smi not found"
fi

echo ""
echo "=== Cleanup complete ==="
echo "GPU driver preserved. System ready for handover."
