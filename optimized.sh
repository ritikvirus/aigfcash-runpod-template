#!/usr/bin/env bash
set -Eeuo pipefail

# ------------- Tunables (env overridable) -------------
: "${WORKSPACE:=/workspace}"
: "${COMFY_DIR:=${WORKSPACE}/ComfyUI}"
: "${COMFYUI_REF:=latest}"        # "latest" will auto-detect newest tag (vX.Y.Z)
: "${AUTO_UPDATE:=true}"           # update nodes if already cloned
: "${CLEAN_INSTALL:=true}"         # wipe existing ComfyUI dir on first run
: "${HF_TOKEN:=}"                  # optional, for model downloads (not used here)
: "${CIVITAI_TOKEN:=}"             # optional, for model downloads (not used here)

# Your node list (add/remove freely)
NODES=(
  "https://github.com/Comfy-Org/ComfyUI-Manager"
  "https://github.com/cubiq/ComfyUI_essentials"
  "https://github.com/Gourieff/ComfyUI-ReActor"
  "https://github.com/ltdrdata/ComfyUI-Impact-Pack"
  "https://github.com/ltdrdata/ComfyUI-Impact-Subpack"
  "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite"
  "https://github.com/giriss/comfy-image-saver"
  "https://github.com/pythongosssss/ComfyUI-WD14-Tagger"
  "https://github.com/hylarucoder/comfyui-copilot"
  "https://github.com/kijai/ComfyUI-KJNodes"
  "https://github.com/KoreTeknology/ComfyUI-Universal-Styler"
  "https://github.com/Fannovel16/ComfyUI-Frame-Interpolation"
  "https://github.com/mpiquero1111/ComfyUI-SaveImgPrompt"
  "https://github.com/melMass/comfy_mtb"
  "https://github.com/rgthree/rgthree-comfy"
  "https://github.com/ssitu/ComfyUI_UltimateSDUpscale"
  "https://github.com/if-ai/ComfyUI_IF_AI_LoadImages"
  "https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes"
  "https://github.com/shiimizu/ComfyUI-TiledDiffusion"
  "https://github.com/BadCafeCode/masquerade-nodes-comfyui"
  "https://github.com/city96/ComfyUI_ExtraModels"
  "https://github.com/city96/ComfyUI-GGUF"
  "https://github.com/Ryuukeisyou/comfyui_face_parsing"
  "https://github.com/chflame163/ComfyUI_LayerStyle"
  "https://github.com/chflame163/ComfyUI_LayerStyle_Advance"
  "https://github.com/cubiq/ComfyUI_FaceAnalysis"
  "https://github.com/chrisgoringe/cg-use-everywhere"
  "https://github.com/jakechai/ComfyUI-JakeUpgrade"
  "https://github.com/cubiq/ComfyUI_IPAdapter_plus"
  "https://github.com/flowtyone/ComfyUI-Flowty-LDSR"
  "https://github.com/Fannovel16/comfyui_controlnet_aux"
  "https://github.com/un-seen/comfyui-tensorops"
  "https://github.com/glifxyz/ComfyUI-GlifNodes"
  "https://github.com/EllangoK/ComfyUI-post-processing-nodes"
  "https://github.com/sipherxyz/comfyui-art-venture"
  "https://github.com/storyicon/comfyui_segment_anything"
  "https://github.com/kijai/ComfyUI-Florence2"
  "https://github.com/pythongosssss/ComfyUI-Custom-Scripts"
  "https://github.com/hay86/ComfyUI_LatentSync"
  "https://github.com/pamparamm/sd-perturbed-attention"
  "https://github.com/WASasquatch/was-node-suite-comfyui"
)

# ------------- Logging helpers -------------
log()  { printf "\e[1;32m[SETUP]\e[0m %s\n" "$*"; }
warn() { printf "\e[1;33m[WARN ]\e[0m %s\n" "$*"; }
err()  { printf "\e[1;31m[ERROR]\e[0m %s\n" "$*"; }
trap 'err "failed at line $LINENO"; exit 1' ERR

# ------------- Environment / venv -------------
use_venv() {
  # Prefer AI-Dock supplied venv if available
  if [[ -f /opt/ai-dock/etc/environment.sh ]]; then
    source /opt/ai-dock/etc/environment.sh || true
  fi
  if [[ -f /opt/ai-dock/bin/venv-set.sh ]]; then
    # Switch to comfyui venv shipped with the image
    # (AI-Dock recommends using a provisioning script & its venv) 
    source /opt/ai-dock/bin/venv-set.sh comfyui || true
  fi

  # If still no venv, create one
  if ! python3 -c 'import sys;import sysconfig;print(sys.prefix)'; then
    warn "No Python found; container may be unusual."
  fi
  if ! python3 -c 'import sys; print(hasattr(sys, "real_prefix") or (sys.base_prefix!=sys.prefix))' | grep -q 'True'; then
    log "Creating local venv..."
    python3 -m venv "${WORKSPACE}/.venv"
    source "${WORKSPACE}/.venv/bin/activate"
  fi

  PIP="python -m pip"
}

# ------------- Core steps -------------
latest_tag() {
  # Returns latest v* tag from upstream (sorted by version)
  git ls-remote --tags --refs https://github.com/comfyanonymous/ComfyUI.git \
    | awk -F/ '/refs\/tags\/v[0-9]/{print $3}' | sort -V | tail -n1
}

clone_comfyui() {
  local ref="$COMFYUI_REF"
  if [[ "${ref}" == "latest" ]]; then
    ref="$(latest_tag || true)"
    [[ -z "$ref" ]] && { warn "Could not resolve latest tag; defaulting to master"; ref="master"; }
  fi
  log "Cloning ComfyUI @ ${ref} ..."
  if [[ "${CLEAN_INSTALL,,}" == "true" && -d "${COMFY_DIR}" ]]; then
    rm -rf "${COMFY_DIR}"
  fi
  mkdir -p "${COMFY_DIR%/*}"
  if [[ -d "${COMFY_DIR}/.git" ]]; then
    (cd "${COMFY_DIR}" && git fetch --tags && git checkout -f "${ref}" && git pull --ff-only || true)
  else
    git clone https://github.com/comfyanonymous/ComfyUI "${COMFY_DIR}"
    (cd "${COMFY_DIR}" && git checkout -f "${ref}" || true)
  fi
}

prep_python() {
  log "Upgrading pip/setuptools/wheel..."
  $PIP install -q --upgrade pip setuptools wheel

  # Avoid OpenCV ABI mismatches many nodes hit: prefer contrib build
  if python -c 'import cv2' >/dev/null 2>&1; then
    $PIP uninstall -y opencv-python opencv-python-headless >/dev/null 2>&1 || true
  fi
  $PIP install -q --no-cache-dir opencv-contrib-python-headless==4.10.0.84

  # Pre-pin torchvision/torchaudio to match existing torch if present
  if python -c 'import torch' >/dev/null 2>&1; then
    local tv=''
    local ta=''
    local torch_ver
    torch_ver="$(python - <<'PY'
import torch, re
print(re.sub(r'\+.*$', '', torch.__version__))
PY
)"
    case "$torch_ver" in
      2.4.*) tv=0.19.1; ta=2.4.1;;
      2.5.*) tv=0.20.1; ta=2.5.1;;
      2.6.*) tv=0.21.0; ta=2.6.0;;
      *) warn "Unknown torch $torch_ver; skipping tv/ta pre-pin";;
    esac
    if [[ -n "$tv" ]]; then
      log "Pinning torchvision==$tv torchaudio==$ta to match torch==$torch_ver"
      $PIP install -q --no-cache-dir --index-url https://download.pytorch.org/whl/cu121 "torchvision==${tv}" "torchaudio==${ta}" || \
        warn "Could not pin torchvision/torchaudio; continuing"
    fi
  fi
}

install_comfy_requirements() {
  log "Installing ComfyUI requirements (GPU-safe)..."
  local req="${COMFY_DIR}/requirements.txt"
  if [[ ! -s "$req" ]]; then
    warn "requirements.txt not found in ComfyUI. Trying anyway with common deps."
  fi

  # Filter torch/vision/audio from requirements to preserve GPU build already in image
  if [[ -s "$req" ]]; then
    awk '!tolower($0) ~ /^(torch|torchvision|torchaudio)($|[<=>])/ {print $0}' "$req" > /tmp/requirements.filtered.txt
    $PIP install --no-cache-dir -r /tmp/requirements.filtered.txt
  else
    # Fallback minimal set from docs if requirements missing
    $PIP install --no-cache-dir \
      "einops" "transformers>=4.28.1" "tokenizers>=0.13.3" "sentencepiece" \
      "safetensors>=0.4.2" "pyyaml" "Pillow" "scipy" "tqdm" "psutil"
  fi
}

clone_and_install_nodes() {
  log "Installing custom nodes..."
  local base="${COMFY_DIR}/custom_nodes"
  mkdir -p "$base"

  for repo in "${NODES[@]}"; do
    local name="${repo##*/}"
    local path="${base}/${name}"
    log ">>> ${name}"
    if [[ -d "$path/.git" ]]; then
      if [[ "${AUTO_UPDATE,,}" == "true" ]]; then
        (cd "$path" && git pull --rebase --autostash || true) || warn "update failed: ${name}"
      else
        log "Already present, skipping update: ${name}"
      fi
    else
      git clone --recursive --depth=1 "$repo" "$path" || { warn "clone failed: $repo"; continue; }
    fi

    # Node requirements
    if [[ -s "$path/requirements.txt" ]]; then
      log "Installing ${name} requirements..."
      $PIP install --no-cache-dir -r "$path/requirements.txt" || warn "reqs failed for ${name}"
    fi

    # Some nodes (e.g. Impact-Pack/Subpack) require install.py
    if [[ -f "$path/install.py" ]]; then
      log "Running ${name}/install.py ..."
      (cd "$path" && python install.py) || warn "install.py failed for ${name}"
    fi
  done

  # Common extras frequently required across nodes
  $PIP install --no-cache-dir ultralytics onnxruntime || true
}

sanity_check() {
  log "Running quick sanity checks..."
  python - <<'PY'
try:
    import comfy
    print("OK: ComfyUI core import")
except Exception as e:
    print("FAIL: ComfyUI core import", e)

import importlib
mods = ["nodes", "CUSTOM_NODES"]
for m in mods:
    try:
        importlib.import_module(m)
        print("OK:", m)
    except Exception as e:
        print("MISS:", m, e)
PY
}

main() {
  log "Starting clean provision..."
  use_venv
  clone_comfyui
  prep_python
  install_comfy_requirements
  clone_and_install_nodes
  sanity_check
  log "Provisioning complete."
}

main "$@"
