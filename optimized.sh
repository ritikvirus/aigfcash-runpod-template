#!/bin/sh
# POSIX-safe provisioning for AI-Dock ComfyUI
# Will be sourced/executed by the container on first boot.

set -e

# ---------- Config (edit lists below) ----------
DEFAULT_WORKFLOW="https://raw.githubusercontent.com/kingaigfcash/aigfcash-runpod-template/refs/heads/main/workflows/default_workflow.json"

APT_PACKAGES="git git-lfs python3-pip python3-venv python3-dev build-essential pkg-config libgl1 libglib2.0-0 ffmpeg libsm6 libxext6 curl"

# keep light; torch/cu are part of the image
BASE_PIP_PACKAGES="wheel setuptools pip opencv-python-headless imageio imageio-ffmpeg matplotlib av colorama piexif pydantic-settings alembic uv timm albumentations shapely safetensors>=0.4.2 transformers>=4.28.1 tokenizers>=0.13.3 sentencepiece psutil pyyaml tqdm einops scipy kornia>=0.7.1"

# Known pins to heal node breakages
PIN_PIPS="Pillow==9.5.0 huggingface_hub==0.25.2"

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

# ---------- Internals ----------
WORKSPACE="${WORKSPACE:-/workspace}"
COMFY_DIR="$WORKSPACE/ComfyUI"
AUTO_UPDATE="${AUTO_UPDATE:-true}"
COMFYUI_REF="${COMFYUI_REF:-master}"

# These are exported by the image, but set fallbacks just in case
COMFYUI_VENV_PYTHON="${COMFYUI_VENV_PYTHON:-/opt/environments/python/comfyui/bin/python}"
COMFYUI_VENV_PIP="${COMFYUI_VENV_PIP:-/opt/environments/python/comfyui/bin/pip}"
APT_INSTALL="${APT_INSTALL:-apt-get install -y}"

log() { printf "%s\n" "$*"; }

pip_install() {
  # shellcheck disable=SC2068
  "$COMFYUI_VENV_PIP" install --no-cache-dir $@
}

download_to() {
  url="$1"; target_dir="$2"
  mkdir -p "$target_dir"
  fname="$(basename "$url")"
  out="$target_dir/$fname"
  if [ -s "$out" ]; then log "Exists: $out"; return 0; fi
  if printf "%s" "$url" | grep -q "huggingface.co"; then
    if [ -n "$HF_TOKEN" ]; then
      curl -sS -L -H "Authorization: Bearer $HF_TOKEN" -o "$out" "$url"
    else
      curl -sS -L -o "$out" "$url"
    fi
  elif printf "%s" "$url" | grep -q "civitai.com"; then
    if [ -n "$CIVITAI_TOKEN" ]; then
      curl -sS -L -H "Authorization: Bearer $CIVITAI_TOKEN" -o "$out" "$url"
    else
      curl -sS -L -o "$out" "$url"
    fi
  else
    curl -sS -L -o "$out" "$url"
  fi
  [ -s "$out" ] || { log "ERROR: empty download for $url"; return 1; }
  return 0
}

install_apt() {
  log "Updating apt..."
  apt-get update -y
  apt-get upgrade -y || true
  for pkg in $APT_PACKAGES; do
    log "APT: $pkg"
  done
  # shellcheck disable=SC2086
  $APT_INSTALL $APT_PACKAGES
}

update_comfyui_checkout() {
  if [ -d "$COMFY_DIR/.git" ]; then
    log "Updating ComfyUI checkout to $COMFYUI_REF"
    git -C "$COMFY_DIR" fetch --tags --prune || true
    git -C "$COMFY_DIR" checkout -f "$COMFYUI_REF" || git -C "$COMFY_DIR" checkout -f master
    git -C "$COMFY_DIR" submodule update --init --recursive || true
  fi
}

install_nodes() {
  log "Installing/Updating custom nodes..."
  printf "%s\n" "$NODES" | while IFS= read -r repo; do
    [ -z "$repo" ] && continue
    dir="$(basename "$repo")"
    path="$COMFY_DIR/custom_nodes/$dir"
    if [ -d "$path/.git" ]; then
      if [ "$AUTO_UPDATE" = "true" ]; then
        log "Updating $dir"
        (cd "$path" && git pull --rebase --autostash || true)
      fi
    else
      log "Cloning $dir"
      git clone --recursive "$repo" "$path" || true
    fi
    if [ -f "$path/requirements.txt" ]; then
      log "PIP install requirements for $dir"
      pip_install -r "$path/requirements.txt" || true
    fi
    if [ -f "$path/pyproject.toml" ] || [ -f "$path/setup.py" ]; then
      log "PIP install package $dir"
      pip_install "$path" || true
    fi
  done
  log "Upgrading comfyui-frontend-package..."
  pip_install --upgrade comfyui-frontend-package
}

install_python_packages() {
  log "Upgrading pip tooling..."
  "$COMFYUI_VENV_PIP" install --upgrade pip setuptools wheel
  log "Installing base Python packages..."
  # shellcheck disable=SC2086
  pip_install $BASE_PIP_PACKAGES || true
  log "Applying known pins/fixes..."
  # shellcheck disable=SC2086
  pip_install $PIN_PIPS
  # Ensure ComfyUI reqs satisfied (alembic etc.)
  if [ -f "$COMFY_DIR/requirements.txt" ]; then
    pip_install -r "$COMFY_DIR/requirements.txt" || true
  fi
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

  log "Downloading checkpoint models..."
  printf "%s\n" "$CHECKPOINT_MODELS" | while IFS= read -r u; do [ -n "$u" ] && download_to "$u" "$COMFY_DIR/models/checkpoints" || true; done

  log "Downloading VAE models..."
  printf "%s\n" "$VAE_MODELS" | while IFS= read -r u; do [ -n "$u" ] && download_to "$u" "$WORKSPACE/storage/stable_diffusion/models/vae" || true; done

  log "Downloading LORA models..."
  printf "%s\n" "$LORA_MODELS" | while IFS= read -r u; do [ -n "$u" ] && download_to "$u" "$WORKSPACE/storage/stable_diffusion/models/lora" || true; done

  log "Downloading ControlNet models..."
  printf "%s\n" "$CONTROLNET_MODELS" | while IFS= read -r u; do [ -n "$u" ] && download_to "$u" "$WORKSPACE/storage/stable_diffusion/models/controlnet" || true; done

  log "Downloading Ultralytics BBOX models..."
  printf "%s\n" "$ULTRALYTICS_BBOX_MODELS" | while IFS= read -r u; do [ -n "$u" ] && download_to "$u" "$COMFY_DIR/models/ultralytics/bbox" || true; done

  log "Downloading Ultralytics SEGM models..."
  printf "%s\n" "$ULTRALYTICS_SEGM_MODELS" | while IFS= read -r u; do [ -n "$u" ] && download_to "$u" "$COMFY_DIR/models/ultralytics/segm" || true; done

  log "Downloading SAM models..."
  printf "%s\n" "$SAM_MODELS" | while IFS= read -r u; do [ -n "$u" ] && download_to "$u" "$COMFY_DIR/models/sams" || true; done

  log "Downloading InsightFace models..."
  printf "%s\n" "$INSIGHTFACE_MODELS" | while IFS= read -r u; do [ -n "$u" ] && download_to "$u" "$COMFY_DIR/models/insightface" || true; done
}

maybe_write_default_graph() {
  # optional: write default workflow into web client if URL is set
  if [ -n "$DEFAULT_WORKFLOW" ]; then
    wf_json="$(curl -s "$DEFAULT_WORKFLOW" || true)"
    if [ -n "$wf_json" ]; then
      mkdir -p "$COMFY_DIR/web/scripts"
      # Quote carefully to keep it POSIX-safe
      printf "%s %s\n" "export const defaultGraph =" "$wf_json;" > "$COMFY_DIR/web/scripts/defaultGraph.js" || true
    fi
  fi
}

main() {
  printf "\n==== Provisioning container (POSIX) ====\n"
  install_apt
  update_comfyui_checkout
  install_nodes
  install_python_packages
  download_models
  maybe_write_default_graph
  printf "==== Provisioning complete ====\n\n"
}

main
