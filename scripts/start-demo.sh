#!/usr/bin/env bash
# start-demo.sh - Start the DGX Sovereign AI demo
#
# What it does:
# - Ensures k3s is running
# - Applies the Kubernetes manifests
# - Starts vLLM / Mistral
# - Starts Open WebUI
# - Starts a local port-forward tunnel
# - Opens Firefox at http://dgx-demo.test:18080
#
# Run with:
#   ./scripts/start-demo.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

export KUBECONFIG="${KUBECONFIG:-/etc/rancher/k3s/k3s.yaml}"

URL="http://dgx-demo.test:18080"
LOCAL_HOSTNAME="dgx-demo.test"
LOCAL_PORT="18080"

LOG="$SCRIPT_DIR/start-demo.log"
PORTFORWARD_LOG="$SCRIPT_DIR/openwebui-portforward.log"
PORTFORWARD_PID="/tmp/dgx-openwebui-portforward.pid"
FIREFOX_PROFILE="$PROJECT_DIR/.demo/firefox-profile"

mkdir -p "$PROJECT_DIR/.demo"

exec > >(tee -a "$LOG") 2>&1

notify() {
  local message="$1"

  if command -v zenity >/dev/null 2>&1; then
    zenity --info --width=480 --text="$message" || true
  elif command -v notify-send >/dev/null 2>&1; then
    notify-send "DGX Demo" "$message" || true
  else
    echo "$message"
  fi
}

fail() {
  local message="$1"
  echo ""
  echo "ERROR: $message"
  notify "DGX demo failed.

$message

Check:
$LOG"
  exit 1
}

ensure_hosts_entry() {
  if grep -qE "^[[:space:]]*127\.0\.0\.1[[:space:]].*${LOCAL_HOSTNAME}" /etc/hosts; then
    return 0
  fi

  echo "Adding local hostname to /etc/hosts: $LOCAL_HOSTNAME"

  if command -v sudo >/dev/null 2>&1; then
    echo "127.0.0.1 $LOCAL_HOSTNAME" | sudo tee -a /etc/hosts >/dev/null
  else
    fail "sudo is not available. Add this line manually to /etc/hosts: 127.0.0.1 $LOCAL_HOSTNAME"
  fi
}

wait_for_vllm_port() {
  echo "Checking AI backend port..."

  for i in {1..60}; do
    if kubectl -n llm exec deployment/mistral -- bash -lc 'timeout 2 bash -c "</dev/tcp/127.0.0.1/8000"' >/dev/null 2>&1; then
      echo "AI backend port is ready."
      return 0
    fi

    if (( i % 6 == 0 )); then
      echo "Still checking AI backend... about $((i * 10)) seconds elapsed."
    fi

    sleep 10
  done

  return 1
}

start_webui_tunnel() {
  echo "Starting local Web UI tunnel..."

  if [ -f "$PORTFORWARD_PID" ]; then
    kill "$(cat "$PORTFORWARD_PID")" >/dev/null 2>&1 || true
    rm -f "$PORTFORWARD_PID"
  fi

  pkill -f "kubectl -n ui port-forward svc/openwebui ${LOCAL_PORT}:80" >/dev/null 2>&1 || true

  nohup kubectl -n ui port-forward svc/openwebui "${LOCAL_PORT}:80" --address 127.0.0.1 \
    > "$PORTFORWARD_LOG" 2>&1 &

  echo $! > "$PORTFORWARD_PID"
}

wait_for_webui() {
  echo "Checking Web UI..."

  for i in {1..60}; do
    if curl --noproxy '*' -fsS "$URL" >/dev/null 2>&1; then
      echo "Web UI is ready."
      return 0
    fi

    if (( i % 6 == 0 )); then
      echo "Still checking Web UI... about $((i * 5)) seconds elapsed."
    fi

    sleep 5
  done

  return 1
}

open_firefox() {
  echo "Opening Firefox..."

  mkdir -p "$FIREFOX_PROFILE"

  if command -v firefox >/dev/null 2>&1; then
    firefox --no-remote --profile "$FIREFOX_PROFILE" --new-window "$URL" >/dev/null 2>&1 &
  else
    xdg-open "$URL" >/dev/null 2>&1 &
  fi
}

echo "======================================"
echo " Starting DGX Sovereign AI Demo"
echo "======================================"
echo ""
echo "Project folder:"
echo "$PROJECT_DIR"
echo ""
echo "Please wait. First start can take 3–5 minutes."
echo "Do not close this window."
echo ""

ensure_hosts_entry

if ! command -v kubectl >/dev/null 2>&1; then
  fail "kubectl not found. Install k3s first."
fi

if [ ! -f "$KUBECONFIG" ]; then
  fail "Kubeconfig not found at $KUBECONFIG"
fi

if systemctl list-unit-files | grep -q '^k3s.service'; then
  if ! systemctl is-active --quiet k3s; then
    echo "Starting Kubernetes service..."
    if command -v pkexec >/dev/null 2>&1; then
      pkexec systemctl start k3s || sudo systemctl start k3s
    else
      sudo systemctl start k3s
    fi
  fi
fi

echo "Checking Kubernetes..."
kubectl get nodes >/dev/null || fail "Kubernetes is not reachable."

echo "Applying manifests..."
kubectl apply -f "$PROJECT_DIR/manifests/01-hf-cache-pvc.yaml"
kubectl apply -f "$PROJECT_DIR/manifests/02-mistral-vllm.yaml"
kubectl apply -f "$PROJECT_DIR/manifests/10-openwebui.yaml"

echo "Starting AI backend..."
kubectl -n llm scale deployment/mistral --replicas=1

echo "Starting Web UI..."
kubectl -n ui scale deployment/openwebui --replicas=1

echo "Waiting for Mistral deployment..."
if ! kubectl -n llm rollout status deployment/mistral --timeout=1200s; then
  echo ""
  echo "Recent Mistral logs:"
  kubectl -n llm logs deployment/mistral --tail=150 || true
  fail "Mistral did not become ready. If you are offline, the model cache may be incomplete."
fi

echo "Waiting for Open WebUI deployment..."
if ! kubectl -n ui rollout status deployment/openwebui --timeout=300s; then
  echo ""
  echo "Recent Open WebUI logs:"
  kubectl -n ui logs deployment/openwebui --tail=150 || true
  fail "Open WebUI did not become ready."
fi

if kubectl -n llm logs deployment/mistral --tail=150 | grep -qi "huggingface.co"; then
  echo ""
  echo "WARNING: Recent vLLM logs mention Hugging Face."
  echo "If the demo is meant to run offline, make sure the model is fully cached."
  echo ""
fi

if ! wait_for_vllm_port; then
  echo ""
  echo "Recent Mistral logs:"
  kubectl -n llm logs deployment/mistral --tail=150 || true
  fail "AI backend port 8000 is not ready."
fi

start_webui_tunnel

if ! wait_for_webui; then
  echo ""
  echo "Port-forward log:"
  cat "$PORTFORWARD_LOG" || true
  fail "Web UI tunnel did not become ready."
fi

open_firefox

notify "DGX demo is ready.

Open WebUI:
$URL

Users:
- finance-user = Finance user
- normal-user = Normal user
- admin = Admin"

echo ""
echo "======================================"
echo " DGX demo is ready"
echo "======================================"
echo "$URL"
echo ""