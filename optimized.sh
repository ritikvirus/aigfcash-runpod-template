#!/bin/sh
# POSIX-safe first-boot provisioning for AI‑Dock ComfyUI on RunPod
# This script is intended to be sourced/executed by the container on first boot.
# It will:
#  - Stop ComfyUI so it doesn’t race provisioning
#  - Optionally checkout a stable ComfyUI tag
#  - Install apt & Python deps
#  - Clone/update custom nodes and install their requirements
#  - Download models with retries and basic integrity checks
#  - Write a default workflow graph if provided
#  - Restart ComfyUI at the end

set -eu

# ---------- User‑tunable defaults ----------
DEFAULT_WORKFLOW="https://raw.githubusercontent.com/kingaigfcash/aigfcash-runpod-template/refs/heads/main/workflows/default_workflow.json"

# Keep apt light; CUDA/Torch come from the image
APT_PACKAGES="git git-lfs python3-pip python3-venv python3-dev build-essential pkg-config libgl1 libglib2.0-0 ffmpeg libsm6 libxext6 curl"

# Base Python packages (installed into ComfyUI venv)
BASE_PIP_PACKAGES="wheel setuptools pip opencv-python-headless imageio imageio-ffmpeg matplotlib av colorama piexif pydantic-settings alembic uv timm albumentations shapely safetensors>=0.4.2 transformers>=4.28.1 tokenizers>=0.13.3 sentencepiece psutil pyyaml tqdm einops scipy kornia>=0.7.1"

# Known pins to heal frequent node breakages
PIN_PIPS="Pillow==9.5.0 huggingface_hub==0.25.2"

# Custom nodes to clone/update
NODES="
https://github.com/ltdrdata/ComfyUI-Manager
https://github.com/cubiq/ComfyUI_essentials
https://github.com/Gourieff/ComfyUI-ReActor
https://github.com/ltdrdata/ComfyUI-Impact-Pack
https://github.com/ltdrdata/ComfyUI-Impact-Subpack
https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite
https://github.com/giriss/comfy-image-saver
https://github.com/pythongosssss/ComfyUI-WD14-Tagger
https://github.com/hylarucoder/comfyui-copilot
https://github.com/kijai/ComfyUI-KJNodes
https://github.com/KoreTeknology/ComfyUI-Universal-Styler
https://github.com/Fannovel16/ComfyUI-Frame-Interpolation
https://github.com/mpiquero1111/ComfyUI-SaveImgPrompt
https://github.com/melMass/comfy_mtb
https://github.com/rgthree/rgthree-comfy
https://github.com/ssitu/ComfyUI_UltimateSDUpscale
https://github.com/if-ai/ComfyUI_IF_AI_LoadImages
https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes
https://github.com/shiimizu/ComfyUI-TiledDiffusion
https://github.com/BadCafeCode/masquerade-nodes-comfyui
https://github.com/city96/ComfyUI_ExtraModels
https://github.com/city96/ComfyUI-GGUF
https://github.com/Ryuukeisyou/comfyui_face_parsing
https://github.com/chflame163/ComfyUI_LayerStyle
https://github.com/chflame163/ComfyUI_LayerStyle_Advance
https://github.com/cubiq/ComfyUI_FaceAnalysis
https://github.com/chrisgoringe/cg-use-everywhere
https://github.com/jakechai/ComfyUI-JakeUpgrade
https://github.com/cubiq/ComfyUI_IPAdapter_plus
https://github.com/0xbitches/ComfyUI-LCM
https://github.com/flowtyone/ComfyUI-Flowty-LDSR
https://github.com/Fannovel16/comfyui_controlnet_aux
https://github.com/un-seen/comfyui-tensorops
https://github.com/glifxyz/ComfyUI-GlifNodes
https://github.com/EllangoK/ComfyUI-post-processing-nodes
https://github.com/sipherxyz/comfyui-art-venture
https://github.com/storyicon/comfyui_segment_anything
https://github.com/kijai/ComfyUI-Florence2
https://github.com/pythongosssss/ComfyUI-Custom-Scripts
https://github.com/hay86/ComfyUI_LatentSync
https://github.com/pamparamm/sd-perturbed-attention
https://github.com/WASasquatch/was-node-suite-comfyui
"

# Models (examples — extend as needed)
CHECKPOINT_MODELS="
https://huggingface.co/kingcashflow/modelcheckpoints/resolve/main/AIIM_Realism.safetensors
https://huggingface.co/kingcashflow/modelcheckpoints/resolve/main/AIIM_Realism_FAST.safetensors
https://huggingface.co/kingcashflow/modelcheckpoints/resolve/main/uberRealisticPornMergePonyxl_ponyxlHybridV1.safetensors
https://huggingface.co/AiWise/epiCRealism-XL-vXI-aBEAST/resolve/5c3950c035ce565d0358b76805de5ef2c74be919/epicrealismXL_vxiAbeast.safetensors
"
VAE_MODELS="
https://huggingface.co/stabilityai/sdxl-vae/resolve/main/diffusion_pytorch_model.safetensors
"
LORA_MODELS="
https://huggingface.co/kingcashflow/LoRas/resolve/main/depth_of_field_slider_v1.safetensors
https://huggingface.co/kingcashflow/LoRas/resolve/main/zoom_slider_v1.safetensors
https://huggingface.co/kingcashflow/LoRas/resolve/main/add_detail.safetensors
https://huggingface.co/kingcashflow/underboobXL/resolve/main/UnderboobXL.safetensors
"
CONTROLNET_MODELS="
https://huggingface.co/xinsir/controlnet-openpose-sdxl-1.0/resolve/main/diffusion_pytorch_model.safetensors
https://huggingface.co/xinsir/controlnet-depth-sdxl-1.0/resolve/main/diffusion_pytorch_model.safetensors
https://huggingface.co/dimitribarbot/controlnet-dwpose-sdxl-1.0/resolve/main/diffusion_pytorch_model.safetensors
"
INSIGHTFACE_MODELS="
https://huggingface.co/datasets/Gourieff/ReActor/resolve/main/models/inswapper_128.onnx
"
ULTRALYTICS_BBOX_MODELS="
https://huggingface.co/Bingsu/adetailer/resolve/main/face_yolov8m.pt
https://huggingface.co/Bingsu/adetailer/resolve/main/hand_yolov8n.pt
https://huggingface.co/Bingsu/adetailer/resolve/main/face_yolov8n_v2.pt
https://huggingface.co/Bingsu/adetailer/resolve/main/hand_yolov9c.pt
https://huggingface.co/kingcashflow/underboobXL/resolve/main/Eyeful_v2-Individual.pt
"
ULTRALYTICS_SEGM_MODELS="
https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8m-seg.pt
"
SAM_MODELS="
https://dl.fbaipublicfiles.com/segment_anything/sam_vit_b_01ec64.pth
"

# ---------- Internals / env fallbacks ----------
WORKSPACE="${WORKSPACE:-/workspace}"
COMFY_DIR="$WORKSPACE/ComfyUI"
AUTO_UPDATE="${AUTO_UPDATE:-true}"                 # true/false
# Default to the latest stable tag as of 2025‑08‑13; override with COMFYUI_REF=master to track head
COMFYUI_REF="${COMFYUI_REF:-v0.3.50}"

COMFYUI_VENV_PYTHON="${COMFYUI_VENV_PYTHON:-/opt/environments/python/comfyui/bin/python}"
COMFYUI_VENV_PIP="${COMFYUI_VENV_PIP:-/opt/environments/python/comfyui/bin/pip}"
APT_INSTALL="${APT_INSTALL:-apt-get install -y}"

log() { printf "%s\n" "$*"; }
warn() { printf "WARN: %s\n" "$*"; }
run() { log "> $*"; "$@"; }

# Retry‑friendly download with auth headers and resume
_download_to() {
  url="$1"; out="$2"; tmp="$out.part"
  hdr=""; case "$url" in
    https://huggingface.co/*) [ -n "${HF_TOKEN:-}" ] && hdr="-H" && hdr="$hdr" "Authorization: Bearer $HF_TOKEN";;
    https://civitai.com/*)    [ -n "${CIVITAI_TOKEN:-}" ] && hdr="-H" && hdr="$hdr" "Authorization: Bearer $CIVITAI_TOKEN";;
  esac
  mkdir -p "$(dirname "$out")"
  if [ -s "$out" ]; then log "Exists: $out"; return 0; fi
  run curl -fSsL --retry 5 --retry-delay 3 --continue-at - ${hdr:+-H "$hdr"} -o "$tmp" "$url" || return 1
  mv "$tmp" "$out"
}

# Basic integrity check: safetensors quick header validation via python
_validate_if_safetensors() {
  f="$1"; case "$f" in *.safetensors)
    "$COMFYUI_VENV_PYTHON" - "$f" <<'PY' || return 1
import sys
from safetensors.numpy import load_file
try:
    load_file(sys.argv[1])  # parses header & metadata
    print("OK safetensors:", sys.argv[1])
except Exception as e:
    print("BROKEN safetensors:", sys.argv[1], e)
    raise
PY
  esac
}

install_apt() {
  log "Updating apt and installing base packages..."
  run apt-get update -y
  run apt-get upgrade -y || true
  for pkg in $APT_PACKAGES; do log "APT: $pkg"; done
  # shellcheck disable=SC2086
  run $APT_INSTALL $APT_PACKAGES
}

stop_comfy_service() {
  command -v supervisorctl >/dev/null 2>&1 || { warn "supervisorctl not found; skipping service stop"; return; }
  run supervisorctl stop comfyui || true
}

start_comfy_service() {
  command -v supervisorctl >/dev/null 2>&1 || { warn "supervisorctl not found; skipping service start"; return; }
  run supervisorctl start comfyui || run supervisorctl restart comfyui || true
}

prepare_git() {
  # avoid "unsafe repository" warnings and locking races
  git config --global --add safe.directory "$COMFY_DIR" 2>/dev/null || true
}

update_comfyui_checkout() {
  if [ -d "$COMFY_DIR/.git" ]; then
    log "Checking out ComfyUI: $COMFYUI_REF"
    ( cd "$COMFY_DIR" && git fetch --tags --prune || true
      git checkout -f "$COMFYUI_REF" || git checkout -f master
      git submodule update --init --recursive || true )
  else
    warn "ComfyUI repo not found at $COMFY_DIR — skipping checkout"
  fi
}

install_python_packages() {
  log "Upgrading pip tooling..."
  run "$COMFYUI_VENV_PIP" install --upgrade pip setuptools wheel
  log "Installing base Python packages..."
  # shellcheck disable=SC2086
  run "$COMFYUI_VENV_PIP" install --no-cache-dir $BASE_PIP_PACKAGES || true
  log "Applying known pins..."
  # shellcheck disable=SC2086
  run "$COMFYUI_VENV_PIP" install --no-cache-dir $PIN_PIPS
  if [ -f "$COMFY_DIR/requirements.txt" ]; then
    log "Installing ComfyUI requirements.txt..."
    run "$COMFYUI_VENV_PIP" install --no-cache-dir -r "$COMFY_DIR/requirements.txt" || true
  fi
}

install_nodes() {
  log "Installing/Updating custom nodes..."
  printf "%s\n" "$NODES" | while IFS= read -r repo; do
    [ -z "$repo" ] && continue
    dir="$(basename "$repo")"
    path="$COMFY_DIR/custom_nodes/$dir"
    if [ -d "$path/.git" ]; then
      [ "$AUTO_UPDATE" = "true" ] && { log "Updating $dir"; (cd "$path" && git pull --rebase --autostash || true); }
    else
      log "Cloning $dir"
      git clone --recursive "$repo" "$path" || true
    fi
    if [ -f "$path/requirements.txt" ]; then
      log "Installing pip requirements for $dir"
      run "$COMFYUI_VENV_PIP" install --no-cache-dir -r "$path/requirements.txt" || true
    fi
    if [ -f "$path/pyproject.toml" ] || [ -f "$path/setup.py" ]; then
      log "Installing $dir as package"
      run "$COMFYUI_VENV_PIP" install --no-cache-dir "$path" || true
    fi
  done
  log "Upgrading comfyui-frontend-package (frontend assets)..."
  run "$COMFYUI_VENV_PIP" install --no-cache-dir --upgrade comfyui-frontend-package || true
}

download_models() {
  log "Creating model directories..."
  mkdir -p \
    "$COMFY_DIR/models/checkpoints" \
    "$COMFY_DIR/models/ultralytics/bbox" \
    "$COMFY_DIR/models/ultralytics/segm" \
    "$COMFY_DIR/models/sams" \
    "$COMFY_DIR/models/insightface" \
    "$WORKSPACE/storage/stable_diffusion/models/vae" \
    "$WORKSPACE/storage/stable_diffusion/models/lora" \
    "$WORKSPACE/storage/stable_diffusion/models/controlnet"

  _dl_list() { list="$1" dest="$2"; printf "%s\n" "$list" | while IFS= read -r u; do
      [ -n "$u" ] || continue
      out="$dest/$(basename "$u")"
      log "Downloading: $u -> $out"
      _download_to "$u" "$out" || { warn "Download failed: $u"; continue; }
      _validate_if_safetensors "$out" || { warn "Integrity check failed: $out"; rm -f "$out"; }
    done; }

  _dl_list "$CHECKPOINT_MODELS" "$COMFY_DIR/models/checkpoints"
  _dl_list "$VAE_MODELS" "$WORKSPACE/storage/stable_diffusion/models/vae"
  _dl_list "$LORA_MODELS" "$WORKSPACE/storage/stable_diffusion/models/lora"
  _dl_list "$CONTROLNET_MODELS" "$WORKSPACE/storage/stable_diffusion/models/controlnet"
  _dl_list "$ULTRALYTICS_BBOX_MODELS" "$COMFY_DIR/models/ultralytics/bbox"
  _dl_list "$ULTRALYTICS_SEGM_MODELS" "$COMFY_DIR/models/ultralytics/segm"
  _dl_list "$SAM_MODELS" "$COMFY_DIR/models/sams"
  _dl_list "$INSIGHTFACE_MODELS" "$COMFY_DIR/models/insightface"
}

maybe_write_default_graph() {
  if [ -n "${DEFAULT_WORKFLOW:-}" ]; then
    wf_json="$(curl -fsSL "$DEFAULT_WORKFLOW" || true)"
    if [ -n "$wf_json" ]; then
      mkdir -p "$COMFY_DIR/web/scripts"
      printf "%s %s\n" "export const defaultGraph =" "$wf_json;" > "$COMFY_DIR/web/scripts/defaultGraph.js" || true
      log "defaultGraph.js written"
    fi
  fi
}

main() {
  printf "\n==== Provisioning container (POSIX) ====\n"
  stop_comfy_service
  install_apt
  prepare_git
  update_comfyui_checkout
  install_python_packages
  install_nodes
  download_models
  maybe_write_default_graph
  start_comfy_service
  printf "==== Provisioning complete ====\n\n"
}

main || { echo "Provisioning failed" >&2; exit 1; }
