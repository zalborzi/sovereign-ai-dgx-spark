#!/usr/bin/env bash
# cleanup.sh - Completely remove the DGX demo Kubernetes stack
#
# WARNING:
# This is destructive.
# It removes k3s, Helm, Rancher/k3s state, local kube config,
# local demo desktop launchers, demo Firefox profile, and demo port-forward state.
#
# It does NOT remove the NVIDIA driver.
# It does NOT delete this Git repository.
#
# Run with:
#   sudo ./scripts/cleanup.sh
#
# Non-interactive:
#   sudo FORCE=1 ./scripts/cleanup.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME="$(eval echo "~$REAL_USER")"

PORTFORWARD_PID="/tmp/dgx-openwebui-portforward.pid"
LOCAL_HOSTNAME="dgx-demo.test"

echo "======================================"
echo " Sovereign AI DGX Spark Cleanup"
echo "======================================"
echo ""
echo "Project folder:"
echo "$PROJECT_DIR"
echo ""

if [ "${EUID}" -ne 0 ]; then
  echo "ERROR: cleanup.sh must be run with sudo."
  echo ""
  echo "Run:"
  echo "  sudo ./scripts/cleanup.sh"
  exit 1
fi

if [ "${FORCE:-0}" != "1" ]; then
  echo "This will remove:"
  echo "- k3s"
  echo "- Kubernetes resources"
  echo "- Helm binary"
  echo "- /etc/rancher"
  echo "- /var/lib/rancher"
  echo "- local kube/helm config for user: $REAL_USER"
  echo "- DGX demo desktop launchers and local demo browser profile"
  echo ""
  echo "It will NOT remove:"
  echo "- NVIDIA driver"
  echo "- this Git repository"
  echo ""
  read -r -p "Type CLEANUP to continue: " CONFIRM

  if [ "$CONFIRM" != "CLEANUP" ]; then
    echo "Cleanup cancelled."
    exit 0
  fi
fi

echo ""
echo "[1/9] Stopping demo processes..."

if [ -f "$PORTFORWARD_PID" ]; then
  kill "$(cat "$PORTFORWARD_PID")" >/dev/null 2>&1 || true
  rm -f "$PORTFORWARD_PID"
fi

pkill -f "kubectl -n ui port-forward svc/openwebui 18080:80" >/dev/null 2>&1 || true
pkill -f "$PROJECT_DIR/.demo/firefox-profile" >/dev/null 2>&1 || true

echo "[2/9] Scaling demo workloads to zero if Kubernetes is reachable..."

export KUBECONFIG="/etc/rancher/k3s/k3s.yaml"

if command -v kubectl >/dev/null 2>&1 && [ -f "$KUBECONFIG" ]; then
  kubectl -n ui scale deployment/openwebui --replicas=0 >/dev/null 2>&1 || true
  kubectl -n llm scale deployment/mistral --replicas=0 >/dev/null 2>&1 || true
else
  echo "Kubernetes not reachable or kubeconfig missing; skipping workload scale-down."
fi

echo "[3/9] Uninstalling k3s..."

if [ -f /usr/local/bin/k3s-uninstall.sh ]; then
  /usr/local/bin/k3s-uninstall.sh || true
else
  echo "k3s uninstall script not found; skipping."
fi

echo "[4/9] Removing Helm binary..."

rm -f /usr/local/bin/helm

echo "[5/9] Removing Rancher/k3s directories..."

rm -rf /etc/rancher
rm -rf /var/lib/rancher

echo "[6/9] Removing user kube/helm config for $REAL_USER..."

rm -rf "$REAL_HOME/.config/helm"
rm -rf "$REAL_HOME/.cache/helm"
rm -rf "$REAL_HOME/.kube"

echo "[7/9] Removing local demo hostname from /etc/hosts..."

if grep -q "$LOCAL_HOSTNAME" /etc/hosts; then
  cp /etc/hosts /etc/hosts.bak.dgx-demo || true
  sed -i "/$LOCAL_HOSTNAME/d" /etc/hosts
fi

echo "[8/9] Removing desktop launchers and local demo state..."

DESKTOP_DIR="$REAL_HOME/Desktop"
if [ -d "$REAL_HOME/Bureau" ]; then
  DESKTOP_DIR="$REAL_HOME/Bureau"
fi

rm -f "$DESKTOP_DIR/Start_DGX_Demo.desktop"
rm -f "$DESKTOP_DIR/Stop_DGX_Demo.desktop"
rm -f "$REAL_HOME/.local/share/icons/dgx-demo-start.svg"
rm -f "$REAL_HOME/.local/share/icons/dgx-demo-stop.svg"

rm -rf "$PROJECT_DIR/.demo"
rm -f "$SCRIPT_DIR/start-demo.log"
rm -f "$SCRIPT_DIR/stop-demo.log"
rm -f "$SCRIPT_DIR/openwebui-portforward.log"

echo "[9/9] Verifying cleanup..."
echo ""

if command -v kubectl >/dev/null 2>&1; then
  echo "WARNING: kubectl still found:"
  command -v kubectl || true
else
  echo "✓ kubectl not found"
fi

if command -v helm >/dev/null 2>&1; then
  echo "WARNING: helm still found:"
  command -v helm || true
else
  echo "✓ helm not found"
fi

if systemctl list-unit-files | grep -q '^k3s.service'; then
  echo "WARNING: k3s systemd service still exists"
else
  echo "✓ k3s service removed"
fi

if command -v nvidia-smi >/dev/null 2>&1; then
  echo "✓ NVIDIA driver intact"
  nvidia-smi --query-gpu=name,driver_version --format=csv,noheader || true
else
  echo "WARNING: nvidia-smi not found"
fi

echo ""
echo "======================================"
echo " Cleanup complete"
echo "======================================"
echo "GPU driver preserved. System ready for handover."
echo ""