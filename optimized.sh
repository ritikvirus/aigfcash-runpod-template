#!/usr/bin/env bash
# Re-exec with bash if invoked via sh
if [ -z "${BASH_VERSION:-}" ]; then exec /usr/bin/env bash "$0" "$@"; fi
set -Eeuo pipefail

# ---------------------------
# AIGFCash Runpod Bootstrapper (Blackwell-safe)
# ---------------------------

# ======== Tunables ========
: "${COMFYUI_REF:=v0.3.50}"
: "${AUTO_UPDATE:=true}"
: "${WORKSPACE:=/workspace}"
: "${COMFY_DIR:=${WORKSPACE}/ComfyUI}"
: "${HF_TOKEN:=}"
: "${CIVITAI_TOKEN:=}"

# Default workflow (optional)
: "${DEFAULT_WORKFLOW:=https://raw.githubusercontent.com/kingaigfcash/aigfcash-runpod-template/refs/heads/main/workflows/default_workflow.json}"

APT_PACKAGES=(
  git git-lfs curl ca-certificates build-essential pkg-config
  python3-dev python3-pip python3-venv
  libgl1 libglib2.0-0 ffmpeg libsm6 libxext6
)

BASE_PIP_PACKAGES=(
  pip setuptools wheel
  "huggingface_hub==0.25.2"
  tqdm pyyaml psutil colorama imageio imageio-ffmpeg matplotlib
  av piexif pydantic-settings uv einops scipy "kornia>=0.7.1"
  "safetensors>=0.4.2" "transformers>=4.28.1" "tokenizers>=0.13.3" sentencepiece
  timm albumentations shapely
  soundfile pydub
)

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
VAE_MODELS=(https://huggingface.co/stabilityai/sdxl-vae/resolve/main/diffusion_pytorch_model.safetensors)
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
INSIGHTFACE_MODELS=(https://huggingface.co/datasets/Gourieff/ReActor/resolve/main/models/inswapper_128.onnx)
ULTRALYTICS_BBOX_MODELS=(
  https://huggingface.co/Bingsu/adetailer/resolve/main/face_yolov8m.pt
  https://huggingface.co/Bingsu/adetailer/resolve/main/hand_yolov8n.pt
  https://huggingface.co/Bingsu/adetailer/resolve/main/face_yolov8n_v2.pt
  https://huggingface.co/Bingsu/adetailer/resolve/main/hand_yolov9c.pt
  https://huggingface.co/kingcashflow/underboobXL/resolve/main/Eyeful_v2-Individual.pt
)
ULTRALYTICS_SEGM_MODELS=(https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8m-seg.pt)
SAM_MODELS=(https://dl.fbaipublicfiles.com/segment_anything/sam_vit_b_01ec64.pth)

WORKFLOWS=(https://github.com/kingaigfcash/aigfcash-runpod-template.git)

# ======== Helpers ========
log() { printf "\e[1;32m[SETUP]\e[0m %s\n" "$*"; }
warn() { printf "\e[1;33m[WARN ]\e[0m %s\n" "$*"; }
err() { printf "\e[1;31m[ERROR]\e[0m %s\n" "$*"; }

sudo_if(){ if command -v sudo >/dev/null 2>&1; then sudo "$@"; else "$@"; fi; }

# Use ComfyUI venv pip/python if present
pipx(){
  if [[ -n "${COMFYUI_VENV_PIP:-}" && -x "${COMFYUI_VENV_PIP}" ]]; then "${COMFYUI_VENV_PIP}" "$@"; else pip "$@"; fi
}
pyx(){
  if [[ -n "${COMFYUI_VENV_PYTHON:-}" && -x "${COMFYUI_VENV_PYTHON}" ]]; then "${COMFYUI_VENV_PYTHON}" "$@"; else python3 "$@"; fi
}

have_hf_token(){ [[ -n "${HF_TOKEN}" ]] && curl -fsSL -H "Authorization: Bearer ${HF_TOKEN}" https://huggingface.co/api/whoami-v2 >/dev/null; }

fetch(){
  local url="$1" out="$2"; shift 2 || true
  local auth=()
  if [[ "$url" =~ ^https://huggingface\.co ]]; then
    [[ -n "${HF_TOKEN}" ]] && auth=(-H "Authorization: Bearer ${HF_TOKEN}")
  elif [[ "$url" =~ ^https://civitai\.com ]]; then
    [[ -n "${CIVITAI_TOKEN}" ]] && auth=(-H "Authorization: Bearer ${CIVITAI_TOKEN}")
  fi
  mkdir -p "$(dirname "$out")"
  local i
  for i in 1 2 3; do
    curl -fL --retry 5 --retry-delay 2 "${auth[@]}" -o "$out.partial" "$url" && mv -f "$out.partial" "$out" || true
    if [[ -s "$out" && $(stat -c%s "$out") -ge 262144 ]]; then echo OK; return 0; fi
    warn "download retry $i for $url"; sleep 2
  done
  return 1
}

# ======== Torch selector (handles 50-series) ========
TORCH_INDEX_URL=""
TORCH_VERSION=""
TORCHVISION_VERSION=""
TORCHAUDIO_VERSION=""
make_torch_plan(){
  # default: respect current torch if present
  local gpu="${RUNPOD_GPU_NAME:-$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null || true)}"
  if [[ "$gpu" =~ (5080|5090|Blackwell|50[0-9]{2}) ]]; then
    # Blackwell requires CUDA 12.8 builds
    TORCH_INDEX_URL="https://download.pytorch.org/whl/cu128"
    TORCH_VERSION="${TORCH_VERSION_OVERRIDE:-2.8.0}"
    TORCHVISION_VERSION="${TORCHVISION_VERSION_OVERRIDE:-0.23.0}"
    TORCHAUDIO_VERSION="${TORCHAUDIO_VERSION_OVERRIDE:-2.8.0}"
    log "Detected ${gpu:-GPU}; planning PyTorch ${TORCH_VERSION} (cu128)."
  else
    # If torch already present, match its minor for vision/audio; otherwise default to cu121 baseline
    TORCH_INDEX_URL="https://download.pytorch.org/whl/cu121"
    if pyx - <<'PY' >/dev/null 2>&1; then
import torch, sys; print(torch.__version__.split('+')[0])
PY
    then
      local tv=""
      local ta=""
      local tver="$(pyx - <<'PY'
import torch, sys; print(torch.__version__.split('+')[0])
PY
)"
      case "$tver" in
        2.4.*) tv=0.19.1; ta=2.4.1;;
        2.5.*) tv=0.20.1; ta=2.5.1;;
        2.6.*) tv=0.21.0; ta=2.6.0;;
        *) tv=""; ta="";;
      esac
      if [[ -n "$tv" ]]; then
        TORCH_VERSION="$tver"; TORCHVISION_VERSION="$tv"; TORCHAUDIO_VERSION="$ta"
        log "Matching existing torch ${TORCH_VERSION} (cu121) with torchvision ${tv}, torchaudio ${ta}."
      fi
    fi
  fi
}

install_torch_stack(){
  [[ -z "$TORCH_VERSION" ]] && return 0
  log "Installing pinned torch stack from ${TORCH_INDEX_URL} ..."
  pipx install --upgrade --index-url "$TORCH_INDEX_URL" "torch==${TORCH_VERSION}" "torchvision==${TORCHVISION_VERSION}" "torchaudio==${TORCHAUDIO_VERSION}"
  # Remove incompatible xformers if present; ComfyUI runs fine without it
  pipx uninstall -y xformers || true
  # Global constraints so nodes cannot change torch later
  cat > /tmp/torch-constraints.txt <<EOF
torch==${TORCH_VERSION}
torchvision==${TORCHVISION_VERSION}
torchaudio==${TORCHAUDIO_VERSION}
EOF
}

# ======== Steps ========
prepare_env(){
  export PIP_NO_INPUT=1
  log "Preparing environment..."
  if [[ -f /opt/ai-dock/etc/environment.sh ]]; then source /opt/ai-dock/etc/environment.sh; fi
  if [[ -f /opt/ai-dock/bin/venv-set.sh ]]; then source /opt/ai-dock/bin/venv-set.sh comfyui; fi
}

install_apt(){
  log "Installing apt packages..."
  sudo_if apt-get update -y || warn "apt update failed; continuing..."
  sudo_if apt-get install -y --no-install-recommends "${APT_PACKAGES[@]}" || warn "apt install skipped/failed."
}

clone_comfyui(){
  log "Cloning/Updating ComfyUI (${COMFYUI_REF})..."
  mkdir -p "${COMFY_DIR%/*}"
  if [[ -d "${COMFY_DIR}/.git" ]]; then
    (cd "$COMFY_DIR" && git fetch --tags && git checkout -f "${COMFYUI_REF}" && git pull --ff-only || true)
  else
    git clone https://github.com/comfyanonymous/ComfyUI "$COMFY_DIR"
    (cd "$COMFY_DIR" && git checkout -f "${COMFYUI_REF}")
  fi
}

install_python_base(){
  log "Upgrading pip/setuptools/wheel..."
  pipx install --upgrade pip setuptools wheel
  log "Installing base Python packages..."
  pipx install --no-cache-dir ${BASE_PIP_PACKAGES[*]}

  # prefer contrib build for opencv
  pipx uninstall -y opencv-python opencv-python-headless || true
  pipx install --no-cache-dir opencv-contrib-python-headless==4.10.0.84

  # Choose and install torch plan
  make_torch_plan
  install_torch_stack

  # Install ComfyUI exact requirements (pin with constraints if we set torch)
  if [[ -f "${COMFY_DIR}/requirements.txt" ]]; then
    log "Installing ComfyUI requirements from ${COMFYUI_REF}..."
    if [[ -f /tmp/torch-constraints.txt ]]; then
      pipx install --no-cache-dir -r "${COMFY_DIR}/requirements.txt" -c /tmp/torch-constraints.txt
    else
      pipx install --no-cache-dir -r "${COMFY_DIR}/requirements.txt"
    fi
  fi
}

install_nodes(){
  log "Installing custom nodes..."
  local base="${COMFY_DIR}/custom_nodes"
  mkdir -p "$base"
  for repo in "${NODES[@]}"; do
    local dir="${repo##*/}"; local path="$base/$dir"; local req="$path/requirements.txt"
    if [[ -d "$path" ]]; then
      if [[ ${AUTO_UPDATE,,} != "false" ]]; then
        log "Updating node: $repo"; (cd "$path" && git pull --rebase --autostash || true)
      else
        log "Node exists, skipping update: $repo"
      fi
    else
      log "Cloning node: $repo"; git clone --recursive "$repo" "$path" || warn "clone failed: $repo"
    fi
    if [[ -s "$req" ]]; then
      log "Installing requirements for $dir"
      if [[ -f /tmp/torch-constraints.txt ]]; then
        pipx install --no-cache-dir -r "$req" -c /tmp/torch-constraints.txt || warn "requirements failed for $dir"
      else
        pipx install --no-cache-dir -r "$req" || warn "requirements failed for $dir"
      fi
    fi
  done
  # Common util packages many nodes assume
  pipx install --no-cache-dir ultralytics onnxruntime || true
}

install_workflows(){
  [[ ${#WORKFLOWS[@]} -eq 0 ]] && return 0
  log "Syncing workflows..."
  for repo in "${WORKFLOWS[@]}"; do
    local name=$(basename "$repo" .git)
    local temp="/tmp/$name"
    local target="${COMFY_DIR}/user/default/workflows"
    if [[ -d "$temp/.git" ]]; then (cd "$temp" && git pull --rebase --autostash || true); else git clone "$repo" "$temp" || true; fi
    mkdir -p "$target"
    [[ -d "$temp/workflows" ]] && cp -rf "$temp/workflows"/* "$target/"
  done
}

write_default_graph(){
  if [[ -n "$DEFAULT_WORKFLOW" ]]; then
    log "Writing default graph.js from DEFAULT_WORKFLOW"
    local js="${COMFY_DIR}/web/scripts/defaultGraph.js"
    curl -fsSL "$DEFAULT_WORKFLOW" -o /tmp/_wf.json && \
      { echo -n "export const defaultGraph = "; cat /tmp/_wf.json; echo ";" ; } > "$js" || true
  fi
}

make_model_dirs(){
  mkdir -p \
    "${COMFY_DIR}/models/checkpoints" \
    "${COMFY_DIR}/models/ultralytics/bbox" \
    "${COMFY_DIR}/models/ultralytics/segm" \
    "${COMFY_DIR}/models/sams" \
    "${COMFY_DIR}/models/insightface" \
    "${WORKSPACE}/storage/stable_diffusion/models/unet" \
    "${WORKSPACE}/storage/stable_diffusion/models/clip" \
    "${WORKSPACE}/storage/stable_diffusion/models/lora" \
    "${WORKSPACE}/storage/stable_diffusion/models/controlnet" \
    "${WORKSPACE}/storage/stable_diffusion/models/vae" \
    "${WORKSPACE}/storage/stable_diffusion/models/esrgan"
}

fetch_models(){
  log "Downloading models (with validation)..."
  local d
  for d in "${CHECKPOINT_MODELS[@]}"; do fetch "$d" "${COMFY_DIR}/models/checkpoints/$(basename "$d")" || warn "failed: $d"; done
  for d in "${UNET_MODELS[@]}"; do fetch "$d" "${WORKSPACE}/storage/stable_diffusion/models/unet/$(basename "$d")" || warn "failed: $d"; done
  for d in "${CLIP_MODELS[@]}"; do fetch "$d" "${WORKSPACE}/storage/stable_diffusion/models/clip/$(basename "$d")" || warn "failed: $d"; done
  for d in "${LORA_MODELS[@]}"; do fetch "$d" "${WORKSPACE}/storage/stable_diffusion/models/lora/$(basename "$d")" || warn "failed: $d"; done
  for d in "${CONTROLNET_MODELS[@]}"; do fetch "$d" "${WORKSPACE}/storage/stable_diffusion/models/controlnet/$(basename "$d")" || warn "failed: $d"; done
  for d in "${VAE_MODELS[@]}"; do fetch "$d" "${WORKSPACE}/storage/stable_diffusion/models/vae/$(basename "$d")" || warn "failed: $d"; done
  for d in "${ESRGAN_MODELS[@]}"; do fetch "$d" "${WORKSPACE}/storage/stable_diffusion/models/esrgan/$(basename "$d")" || warn "failed: $d"; done
  for d in "${ULTRALYTICS_BBOX_MODELS[@]}"; do fetch "$d" "${COMFY_DIR}/models/ultralytics/bbox/$(basename "$d")" || warn "failed: $d"; done
  for d in "${ULTRALYTICS_SEGM_MODELS[@]}"; do fetch "$d" "${COMFY_DIR}/models/ultralytics/segm/$(basename "$d")" || warn "failed: $d"; done
  for d in "${SAM_MODELS[@]}"; do fetch "$d" "${COMFY_DIR}/models/sams/$(basename "$d")" || warn "failed: $d"; done
  for d in "${INSIGHTFACE_MODELS[@]}"; do fetch "$d" "${COMFY_DIR}/models/insightface/$(basename "$d")" || warn "failed: $d"; done
}

post_checks(){
  log "Running quick sanity checks..."
  # Core imports: ensure PYTHONPATH or cwd is repo
  ( cd "$COMFY_DIR" && PYTHONPATH="$COMFY_DIR:$PYTHONPATH" pyx - <<'PY'
try:
    import comfy
    import comfy_extras.nodes_audio as _
    print("ComfyUI core & audio extras import OK")
except Exception as e:
    print("[SANITY] Import error:", e)
PY
  )
  # Basic module presence for nodes
  ( cd "$COMFY_DIR" && PYTHONPATH="$COMFY_DIR:$PYTHONPATH" pyx - <<'PY'
import importlib
mods = ['nodes','CUSTOM_NODES']
for m in mods:
    try:
        importlib.import_module(m)
        print("OK:", m)
    except Exception as e:
        print("MISS:", m, e)
PY
  )
}

main(){
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
