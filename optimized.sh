#!/usr/bin/env bash
set -Eeuo pipefail
trap 'code=$?; echo -e "\e[1;31m[ERROR]\e[0m ${BASH_SOURCE[0]}:${LINENO} exit $code"; exit $code' ERR

# ---------------------------
# AIGFCash Runpod Bootstrapper (AI-Dock compatible)
# Clean install for ComfyUI + nodes + models
# ---------------------------

# ======== Tunables (unchanged) ========
: "${COMFYUI_REF:=v0.3.50}"     # tag/branch/commit OR "latest"
: "${AUTO_UPDATE:=true}"
: "${WORKSPACE:=/workspace}"
: "${COMFY_DIR:=${WORKSPACE%/}/ComfyUI}"
: "${HF_TOKEN:=}"
: "${CIVITAI_TOKEN:=}"
: "${DEFAULT_WORKFLOW:=https://raw.githubusercontent.com/kingaigfcash/aigfcash-runpod-template/main/workflows/default_workflow.json}"

APT_PACKAGES=(
  git git-lfs curl ca-certificates build-essential pkg-config
  python3-dev python3-pip python3-venv
  libgl1 libglib2.0-0 ffmpeg libsm6 libxext6
)

BASE_PIP_PACKAGES=(
  "pip" "setuptools" "wheel"
  "huggingface_hub==0.25.2"
  "tqdm" "pyyaml" "psutil" "colorama" "imageio" "imageio-ffmpeg" "matplotlib"
  "av" "piexif" "pydantic-settings" "uv" "einops" "scipy" "kornia>=0.7.1"
  "safetensors>=0.4.2" "transformers>=4.28.1" "tokenizers>=0.13.3" "sentencepiece"
  "timm" "albumentations" "shapely" "soundfile" "pydub"
)

# ------ Nodes (unchanged list) ------
NODES=(
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
)

CHECKPOINT_MODELS=(
  https://huggingface.co/kingcashflow/modelcheckpoints/resolve/main/AIIM_Realism.safetensors
  https://huggingface.co/kingcashflow/modelcheckpoints/resolve/main/AIIM_Realism_FAST.safetensors
  https://huggingface.co/kingcashflow/modelcheckpoints/resolve/main/uberRealisticPornMergePonyxl_ponyxlHybridV1.safetensors
  https://huggingface.co/AiWise/epiCRealism-XL-vXI-aBEAST/resolve/5c3950c035ce565d0358b76805de5ef2c74be919/epicrealismXL_vxiAbeast.safetensors
)
UNET_MODELS=()
VAE_MODELS=( https://huggingface.co/stabilityai/sdxl-vae/resolve/main/diffusion_pytorch_model.safetensors )
CLIP_MODELS=()
LORA_MODELS=(
  https://huggingface.co/kingcashflow/LoRas/resolve/main/depth_of_field_slider_v1.safetensors
  https://huggingface.co/kingcashflow/LoRas/resolve/main/zoom_slider_v1.safetensors
  https://huggingface.co/kingcashflow/LoRas/resolve/main/add_detail.safetensors
  https://huggingface.co/kingcashflow/underboobXL/resolve/main/UnderboobXL.safetensors
)
CONTROLNET_MODELS=(
  https://huggingface.co/xinsir/controlnet-openpose-sdxl-1.0/resolve/main/diffusion_pytorch_model.safetensors
  https://huggingface.co/xinsir/controlnet-depth-sdxl-1.0/resolve/main/diffusion_pytorch_model.safetensors
  https://huggingface.co/dimitribarbot/controlnet-dwpose-sdxl-1.0/resolve/main/diffusion_pytorch_model.safetensors
)
ESRGAN_MODELS=()
INSIGHTFACE_MODELS=( https://huggingface.co/datasets/Gourieff/ReActor/resolve/main/models/inswapper_128.onnx )
ULTRALYTICS_BBOX_MODELS=(
  https://huggingface.co/Bingsu/adetailer/resolve/main/face_yolov8m.pt
  https://huggingface.co/Bingsu/adetailer/resolve/main/hand_yolov8n.pt
  https://huggingface.co/Bingsu/adetailer/resolve/main/face_yolov8n_v2.pt
  https://huggingface.co/Bingsu/adetailer/resolve/main/hand_yolov9c.pt
  https://huggingface.co/kingcashflow/underboobXL/resolve/main/Eyeful_v2-Individual.pt
)
ULTRALYTICS_SEGM_MODELS=( https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8m-seg.pt )
SAM_MODELS=( https://dl.fbaipublicfiles.com/segment_anything/sam_vit_b_01ec64.pth )
WORKFLOWS=( https://github.com/kingaigfcash/aigfcash-runpod-template.git )

log()  { printf "\e[1;32m[SETUP]\e[0m %s\n" "$*"; }
warn() { printf "\e[1;33m[WARN ]\e[0m %s\n" "$*"; }
err()  { printf "\e[1;31m[ERROR]\e[0m %s\n" "$*"; }

sudo_if() { if command -v sudo >/dev/null 2>&1; then sudo "$@"; else "$@"; fi; }

# Prefer AI-Dock's comfyui venv if present
pipx() {
  if [[ -n "${COMFYUI_VENV_PIP:-}" && -x "${COMFYUI_VENV_PIP}" ]]; then
    "${COMFYUI_VENV_PIP}" "$@"
  else
    pip "$@"
  fi
}
pyx() {
  if [[ -n "${COMFYUI_VENV_PYTHON:-}" && -x "${COMFYUI_VENV_PYTHON}" ]]; then
    "${COMFYUI_VENV_PYTHON}" "$@"
  else
    python3 "$@"
  fi
}

# Auth check for HF
have_hf_token() {
  [[ -n "${HF_TOKEN}" ]] && curl -fsSL -H "Authorization: Bearer ${HF_TOKEN}" https://huggingface.co/api/whoami-v2 >/dev/null
}

# Robust downloader
fetch() {
  local url="$1" out="$2"; shift 2 || true
  local auth=()
  [[ "$url" =~ ^https://huggingface\.co ]] && [[ -n "${HF_TOKEN}" ]] && auth=(-H "Authorization: Bearer ${HF_TOKEN}")
  [[ "$url" =~ ^https://civitai\.com ]]    && [[ -n "${CIVITAI_TOKEN}" ]] && auth=(-H "Authorization: Bearer ${CIVITAI_TOKEN}")
  mkdir -p "$(dirname "$out")"
  for i in 1 2 3; do
    curl -fL --retry 5 --retry-delay 2 "${auth[@]}" -o "$out.partial" "$url" && mv -f "$out.partial" "$out" || true
    if [[ -s "$out" && $(stat -c%s "$out") -ge 262144 ]]; then
      echo OK; return 0
    fi
    warn "download retry $i: $url"; sleep 2
  done
  return 1
}

# ---------- NEW: detect Torch & channel; pin TorchAudio/TorchVision accordingly ----------
detect_torch() {
  pyx - <<'PY'
import torch, re, json
ver = re.sub(r'\+.*$', '', torch.__version__)
cuda = torch.version.cuda or ''
chan = 'cpu' if not cuda else ('cu' + cuda.replace('.', ''))
print(json.dumps({"torch": ver, "cuda": cuda, "channel": chan}))
PY
}
pin_torch_family() {
  log "Pinning Torch family (torchvision/torchaudio) to match installed torch..."
  local js; js="$(detect_torch)"
  local TORCH_BASE_VER CU_CHAN
  TORCH_BASE_VER="$(python3 - <<PY
import json,sys; d=json.loads(sys.argv[1]); print(d["torch"])
PY
"${js}")"
  CU_CHAN="$(python3 - <<PY
import json,sys; d=json.loads(sys.argv[1]); print(d["channel"])
PY
"${js}")"

  # Map torchvision/torchaudio to torch — see PyTorch docs/prev versions. 
  # 2.4.x→0.19.1/2.4.1, 2.5.x→0.20.1/2.5.1, 2.6.x→0.21.0/2.6.0,
  # 2.7.x→0.22.1/2.7.x, 2.8.x→0.23.0/2.8.0
  local TV="" TA=""
  case "$TORCH_BASE_VER" in
    2.4.*) TV="0.19.1"; TA="2.4.1" ;;
    2.5.*) TV="0.20.1"; TA="2.5.1" ;;
    2.6.*) TV="0.21.0"; TA="2.6.0" ;;
    2.7.*) TV="0.22.1"; TA="${TORCH_BASE_VER%%.*.*}.7.0"; TA="2.7.0" ;;  # normalize to 2.7.0
    2.8.*) TV="0.23.0"; TA="2.8.0" ;;
    *) warn "Unknown torch $TORCH_BASE_VER; will skip pinning"; return 0 ;;
  esac

  local INDEX_URL="https://download.pytorch.org/whl/${CU_CHAN}"
  [[ "$CU_CHAN" == "cpu" ]] && INDEX_URL="https://download.pytorch.org/whl/cpu"

  # Ensure clean re-install of vision/audio WITHOUT changing torch
  pipx uninstall -y torchvision torchaudio >/dev/null 2>&1 || true
  pipx install --no-cache-dir --index-url "$INDEX_URL" \
      "torchvision==${TV}" "torchaudio==${TA}" --no-deps --force-reinstall || true
}

# ---------- NEW: build constraints file to prevent nodes from changing Torch ----------
write_torch_constraints() {
  local out="$1"
  local js; js="$(detect_torch)"
  local TORCH_BASE_VER CU_CHAN
  TORCH_BASE_VER="$(python3 - <<PY
import json,sys; d=json.loads(sys.argv[1]); print(d["torch"])
PY
"${js}")"
  CU_CHAN="$(python3 - <<PY
import json,sys; d=json.loads(sys.argv[1]); print(d["channel"])
PY
"${js}")"

  local TV="" TA=""
  case "$TORCH_BASE_VER" in
    2.4.*) TV="0.19.1"; TA="2.4.1" ;;
    2.5.*) TV="0.20.1"; TA="2.5.1" ;;
    2.6.*) TV="0.21.0"; TA="2.6.0" ;;
    2.7.*) TV="0.22.1"; TA="2.7.0" ;;
    2.8.*) TV="0.23.0"; TA="2.8.0" ;;
    *) TV=""; TA="";;
  esac

  : > "$out"
  echo "torch==${TORCH_BASE_VER}" >> "$out"
  [[ -n "$TV" ]] && echo "torchvision==${TV}" >> "$out"
  [[ -n "$TA" ]] && echo "torchaudio==${TA}" >> "$out"

  # Export helper for caller
  echo "$CU_CHAN"
}

prepare_env() {
  log "Preparing environment..."
  [[ -f /opt/ai-dock/etc/environment.sh ]] && source /opt/ai-dock/etc/environment.sh
  [[ -f /opt/ai-dock/bin/venv-set.sh    ]] && source /opt/ai-dock/bin/venv-set.sh comfyui
  umask 002
  mkdir -p "${COMFY_DIR%/*}"
}

install_apt() {
  log "Installing apt packages (best-effort)..."
  sudo_if apt-get update -y || warn "apt update failed (non-root?)"
  sudo_if apt-get install -y --no-install-recommends "${APT_PACKAGES[@]}" || warn "apt install skipped/failed"
}

clone_comfyui() {
  log "Syncing ComfyUI repo..."
  if [[ -d "${COMFY_DIR}/.git" ]]; then
    ( cd "$COMFY_DIR"
      git fetch --tags --prune
      if [[ "${COMFYUI_REF}" == "latest" ]]; then
        COMFYUI_REF="$(git describe --tags "$(git rev-list --tags --max-count=1)")"
      fi
      git checkout -f "${COMFYUI_REF}"
      if git rev-parse --abbrev-ref HEAD | grep -vq '^HEAD$'; then git pull --ff-only || true; fi
    )
  else
    git clone https://github.com/comfyanonymous/ComfyUI "$COMFY_DIR"
    ( cd "$COMFY_DIR"
      git fetch --tags
      [[ "${COMFYUI_REF}" == "latest" ]] && COMFYUI_REF="$(git describe --tags "$(git rev-list --tags --max-count=1)")"
      git checkout -f "${COMFYUI_REF}"
    )
  fi
}

install_python_base() {
  log "Upgrading pip/setuptools/wheel..."
  pipx install --upgrade pip setuptools wheel

  log "Installing base Python packages..."
  pipx install --no-cache-dir "${BASE_PIP_PACKAGES[@]}"

  # Prefer contrib build for OpenCV features some nodes require
  pipx uninstall -y opencv-python opencv-python-headless >/dev/null 2>&1 || true
  pipx install --no-cache-dir "opencv-contrib-python-headless==4.10.0.84"

  # Install ComfyUI exact requirements for the checked-out tag
  if [[ -f "${COMFY_DIR}/requirements.txt" ]]; then
    log "Installing ComfyUI requirements from ${COMFYUI_REF}..."
    pipx install --no-cache-dir -r "${COMFY_DIR}/requirements.txt"
  fi

  # ---------- NEW: immediately pin torch family to what's already installed ----------
  pin_torch_family
}

install_nodes() {
  log "Installing custom nodes..."
  local base="${COMFY_DIR}/custom_nodes"
  mkdir -p "$base"

  for repo in "${NODES[@]}"; do
    local dir="${repo##*/}"
    local path="$base/$dir"
    local req="$path/requirements.txt"

    if [[ -d "$path/.git" ]]; then
      if [[ ${AUTO_UPDATE,,} != "false" ]]; then
        (cd "$path" && git pull --rebase --autostash || true)
      else
        log "Node exists, skipping update: $repo"
      fi
    else
      git clone --recursive "$repo" "$path" || warn "clone failed: $repo"
    fi

    if [[ -s "$req" ]]; then
      log "Installing requirements for $dir (with Torch constraints)"
      local CONSTRAINTS="/tmp/_torch_constraints.txt"
      local CU_CHAN; CU_CHAN="$(write_torch_constraints "$CONSTRAINTS")"
      local INDEX_URL="https://download.pytorch.org/whl/${CU_CHAN}"
      [[ "$CU_CHAN" == "cpu" ]] && INDEX_URL="https://download.pytorch.org/whl/cpu"

      # Respect Torch locks so nodes cannot change torch/vision/audio
      pipx install --no-cache-dir -r "$req" --constraint "$CONSTRAINTS" \
        --extra-index-url "$INDEX_URL" || warn "requirements failed for $dir"
    fi
  done

  # Common extras many nodes assume
  pipx install --no-cache-dir ultralytics onnxruntime || true

  # ---------- NEW: re-pin after all nodes (last line of defense) ----------
  pin_torch_family
}

install_workflows() {
  [[ ${#WORKFLOWS[@]} -eq 0 ]] && return 0
  log "Syncing workflows..."
  for repo in "${WORKFLOWS[@]}"; do
    local name; name="$(basename "$repo" .git)"
    local temp="/tmp/$name"
    local target="${COMFY_DIR}/user/default/workflows"
    if [[ -d "$temp/.git" ]]; then
      (cd "$temp" && git pull --rebase --autostash || true)
    else
      git clone "$repo" "$temp" || true
    fi
    mkdir -p "$target"
    [[ -d "$temp/workflows" ]] && cp -rf "$temp/workflows/"* "$target/" || true
  done
}

write_default_graph() {
  if [[ -n "$DEFAULT_WORKFLOW" ]]; then
    log "Writing defaultGraph.js from DEFAULT_WORKFLOW"
    local js="${COMFY_DIR}/web/scripts/defaultGraph.js"
    if curl -fsSL "$DEFAULT_WORKFLOW" -o /tmp/_wf.json; then
      printf 'export const defaultGraph = %s;\n' "$(cat /tmp/_wf.json)" > "$js"
    fi
  fi
}

make_model_dirs() {
  mkdir -p \
    "${COMFY_DIR}/models/checkpoints" \
    "${COMFY_DIR}/models/ultralytics/bbox" \
    "${COMFY_DIR}/models/ultralytics/segm" \
    "${COMFY_DIR}/models/sams" \
    "${COMFY_DIR}/models/insightface" \
    "${WORKSPACE%/}/storage/stable_diffusion/models/unet" \
    "${WORKSPACE%/}/storage/stable_diffusion/models/clip" \
    "${WORKSPACE%/}/storage/stable_diffusion/models/lora" \
    "${WORKSPACE%/}/storage/stable_diffusion/models/controlnet" \
    "${WORKSPACE%/}/storage/stable_diffusion/models/vae" \
    "${WORKSPACE%/}/storage/stable_diffusion/models/esrgan"
}

fetch_models() {
  log "Downloading models (with validation + retries)..."
  local d
  for d in "${CHECKPOINT_MODELS[@]}"; do fetch "$d" "${COMFY_DIR}/models/checkpoints/$(basename "$d")" || warn "failed: $d"; done
  for d in "${UNET_MODELS[@]}"; do fetch "$d" "${WORKSPACE%/}/storage/stable_diffusion/models/unet/$(basename "$d")" || warn "failed: $d"; done
  for d in "${CLIP_MODELS[@]}"; do fetch "$d" "${WORKSPACE%/}/storage/stable_diffusion/models/clip/$(basename "$d")" || warn "failed: $d"; done
  for d in "${LORA_MODELS[@]}"; do fetch "$d" "${WORKSPACE%/}/storage/stable_diffusion/models/lora/$(basename "$d")" || warn "failed: $d"; done
  for d in "${CONTROLNET_MODELS[@]}"; do fetch "$d" "${WORKSPACE%/}/storage/stable_diffusion/models/controlnet/$(basename "$d")" || warn "failed: $d"; done
  for d in "${VAE_MODELS[@]}"; do fetch "$d" "${WORKSPACE%/}/storage/stable_diffusion/models/vae/$(basename "$d")" || warn "failed: $d"; done
  for d in "${ESRGAN_MODELS[@]}"; do fetch "$d" "${WORKSPACE%/}/storage/stable_diffusion/models/esrgan/$(basename "$d")" || warn "failed: $d"; done
  for d in "${ULTRALYTICS_BBOX_MODELS[@]}"; do fetch "$d" "${COMFY_DIR}/models/ultralytics/bbox/$(basename "$d")" || warn "failed: $d"; done
  for d in "${ULTRALYTICS_SEGM_MODELS[@]}"; do fetch "$d" "${COMFY_DIR}/models/ultralytics/segm/$(basename "$d")" || warn "failed: $d"; done
  for d in "${SAM_MODELS[@]}"; do fetch "$d" "${COMFY_DIR}/models/sams/$(basename "$d")" || warn "failed: $d"; done
  for d in "${INSIGHTFACE_MODELS[@]}"; do fetch "$d" "${COMFY_DIR}/models/insightface/$(basename "$d")" || warn "failed: $d"; done
}

post_checks() {
  log "Quick sanity checks..."
  pyx - <<'PY' || true
try:
    import comfy
    import torchaudio
    print("ComfyUI core + torchaudio imports OK")
except Exception as e:
    print("[SANITY] Import error:", e)
PY
}

main() {
  prepare_env
  install_apt
  clone_comfyui
  install_python_base
  install_nodes
  install_workflows
  write_default_graph
  make_model_dirs
  fetch_models
  post_checks
  log "Provisioning complete."
}

main "$@"
