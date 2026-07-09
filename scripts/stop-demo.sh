#!/usr/bin/env bash
# stop-demo.sh - Stop the DGX Sovereign AI demo
#
# What it does:
# - Closes the dedicated Firefox demo window
# - Stops the local Open WebUI port-forward
# - Scales Open WebUI to zero
# - Scales Mistral/vLLM to zero
# - Leaves k3s, GPU Operator, PVCs, users, and data intact
#
# Run with:
#   ./scripts/stop-demo.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

export KUBECONFIG="${KUBECONFIG:-/etc/rancher/k3s/k3s.yaml}"

LOG="$SCRIPT_DIR/stop-demo.log"
PORTFORWARD_PID="/tmp/dgx-openwebui-portforward.pid"
FIREFOX_PROFILE="$PROJECT_DIR/.demo/firefox-profile"

exec > >(tee -a "$LOG") 2>&1

notify() {
  local message="$1"

  if command -v zenity >/dev/null 2>&1; then
    zenity --info --width=440 --text="$message" || true
  elif command -v notify-send >/dev/null 2>&1; then
    notify-send "DGX Demo" "$message" || true
  else
    echo "$message"
  fi
}

echo "======================================"
echo " Stopping DGX Sovereign AI Demo"
echo "======================================"
echo ""

echo "Closing DGX Demo Firefox window..."
pkill -f "$FIREFOX_PROFILE" >/dev/null 2>&1 || true

echo "Stopping local Web UI tunnel..."
if [ -f "$PORTFORWARD_PID" ]; then
  kill "$(cat "$PORTFORWARD_PID")" >/dev/null 2>&1 || true
  rm -f "$PORTFORWARD_PID"
fi

pkill -f "kubectl -n ui port-forward svc/openwebui 18080:80" >/dev/null 2>&1 || true

if command -v kubectl >/dev/null 2>&1 && [ -f "$KUBECONFIG" ]; then
  echo "Scaling down Open WebUI..."
  kubectl -n ui scale deployment/openwebui --replicas=0 || true

  echo "Scaling down Mistral..."
  kubectl -n llm scale deployment/mistral --replicas=0 || true

  echo "Waiting for demo pods to stop..."
  for i in {1..60}; do
    MISTRAL_COUNT="$(kubectl -n llm get pods -l app=mistral --no-headers 2>/dev/null | wc -l || true)"
    WEBUI_COUNT="$(kubectl -n ui get pods -l app=openwebui --no-headers 2>/dev/null | wc -l || true)"

    if [ "$MISTRAL_COUNT" = "0" ] && [ "$WEBUI_COUNT" = "0" ]; then
      echo "Demo pods stopped."
      break
    fi

    if (( i % 6 == 0 )); then
      echo "Still waiting for pods to stop..."
    fi

    sleep 5
  done
else
  echo "kubectl or kubeconfig not available; skipping Kubernetes scale-down."
fi

echo ""
echo "GPU status:"
nvidia-smi || true

echo ""
notify "DGX demo stopped.

Open WebUI and Mistral are scaled to zero.
Kubernetes remains installed."

echo "Done."