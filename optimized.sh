#!/usr/bin/env bash
# AI-Dock provisioning script for ComfyUI (idempotent, first-boot clean install)
# - Uses AI-Dock conventions: provisioning_* functions + provisioning_start
# - Installs custom nodes + their requirements (no pip-installing nodes themselves)
# - Downloads models with HF/Civitai tokens if provided
# - Writes defaultGraph.js from DEFAULT_WORKFLOW
# - Passes a correct ComfyUI "import comfy" sanity check (adds COMFY_DIR to sys.path)

set -Eeuo pipefail

# ======== Tunables (can be overridden by env) ========
: "${WORKSPACE:=/workspace}"
: "${AUTO_UPDATE:=true}"
: "${COMFYUI_REF:=v0.3.50}"
: "${DEFAULT_WORKFLOW:=https://raw.githubusercontent.com/kingaigfcash/aigfcash-runpod-template/refs/heads/main/workflows/default_workflow.json}"
: "${HF_TOKEN:=}"
: "${CIVITAI_TOKEN:=}"

# Nodes (curated; skips archived/obsolete)
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

# Models to prefetch
CHECKPOINT_MODELS=(
  https://huggingface.co/kingcashflow/modelcheckpoints/resolve/main/AIIM_Realism.safetensors
  https://huggingface.co/kingcashflow/modelcheckpoints/resolve/main/AIIM_Realism_FAST.safetensors
  https://huggingface.co/kingcashflow/modelcheckpoints/resolve/main/uberRealisticPornMergePonyxl_ponyxlHybridV1.safetensors
  https://huggingface.co/AiWise/epiCRealism-XL-vXI-aBEAST/resolve/5c3950c035ce565d0358b76805de5ef2c74be919/epicrealismXL_vxiAbeast.safetensors
)
UNET_MODELS=()
CLIP_MODELS=()
VAE_MODELS=(https://huggingface.co/stabilityai/sdxl-vae/resolve/main/diffusion_pytorch_model.safetensors)
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

# ======== Helpers ========
log()  { printf "\e[1;32m[PROV]\e[0m %s\n" "$*"; }
warn() { printf "\e[1;33m[WARN]\e[0m %s\n" "$*"; }
err()  { printf "\e[1;31m[ERR ]\e[0m %s\n" "$*"; }

# Download with auth + sanity size check
provisioning_download() {
  local url="$1" outdir="$2" dots="${3:-4M}"
  local args=(-qnc --content-disposition -e "dotbytes=${dots}" -P "$outdir")
  if [[ -n "$HF_TOKEN"     && "$url" =~ ^https://([a-zA-Z0-9_-]+\.)?huggingface\.co(/|$|\?) ]]; then
    wget --header="Authorization: Bearer $HF_TOKEN" "${args[@]}" "$url"
  elif [[ -n "$CIVITAI_TOKEN" && "$url" =~ ^https://([a-zA-Z0-9_-]+\.)?civitai\.com(/|$|\?) ]]; then
    wget --header="Authorization: Bearer $CIVITAI_TOKEN" "${args[@]}" "$url"
  else
    wget "${args[@]}" "$url"
  fi
}

# ======== AI-Dock contract: provisioning_* entrypoint ========
provisioning_start() {
  # Standard AI-Dock environment
  source /opt/ai-dock/etc/environment.sh
  source /opt/ai-dock/bin/venv-set.sh comfyui  # sets COMFYUI_VENV_PIP/COMFYUI_VENV_PYTHON
  export COMFY_DIR="${WORKSPACE%/}/ComfyUI"
  log "Workspace: ${WORKSPACE%/} | COMFY_DIR: ${COMFY_DIR}"

  # (Optional) Ensure ComfyUI is on the requested tag; preflight usually does this already.
  if [[ -d "$COMFY_DIR/.git" ]]; then
    (cd "$COMFY_DIR" && git fetch --tags && git checkout -f "$COMFYUI_REF" || true)
  fi

  install_python_extras
  install_custom_nodes
  write_default_graph
  make_model_dirs
  prefetch_models
  sanity_check

  log "Provisioning complete: ComfyUI will start now."
}

install_python_extras() {
  # Keep Torch stack from the image; only add safe extras many nodes assume.
  "$COMFYUI_VENV_PIP" install --no-cache-dir \
    opencv-contrib-python-headless==4.10.0.84 \
    ultralytics onnxruntime \
    tqdm pyyaml psutil colorama imageio imageio-ffmpeg matplotlib \
    av piexif pydantic-settings uv einops scipy "kornia>=0.7.1" \
    "safetensors>=0.4.2" "transformers>=4.28.1" "tokenizers>=0.13.3" sentencepiece \
    timm albumentations shapely soundfile pydub || warn "extras install had non-fatal issues"
}

install_custom_nodes() {
  local base="$COMFY_DIR/custom_nodes"
  mkdir -p "$base"
  for repo in "${NODES[@]}"; do
    local dir="${repo##*/}"
    local path="$base/$dir"
    local req="$path/requirements.txt"
    if [[ -d "$path" ]]; then
      if [[ ${AUTO_UPDATE,,} == "true" ]]; then
        log "Updating node: $repo"
        (cd "$path" && git pull --rebase --autostash || true)
      else
        log "Node exists, skip update: $repo"
      fi
    else
      log "Cloning node: $repo"
      git clone --recursive "$repo" "$path" || warn "clone failed: $repo"
    fi
    if [[ -s "$req" ]]; then
      log "Installing requirements for $dir"
      "$COMFYUI_VENV_PIP" install --no-cache-dir -r "$req" || warn "requirements failed for $dir"
    fi
  done
}

write_default_graph() {
  if [[ -n "$DEFAULT_WORKFLOW" ]]; then
    local js="$COMFY_DIR/web/scripts/defaultGraph.js"
    log "Setting default workflow graph"
    curl -fsSL "$DEFAULT_WORKFLOW" -o /tmp/_wf.json \
      && printf 'export const defaultGraph = %s;\n' "$(cat /tmp/_wf.json)" > "$js" \
      || warn "could not write defaultGraph.js"
  fi
}

make_model_dirs() {
  mkdir -p \
    "$COMFY_DIR/models/checkpoints" \
    "$COMFY_DIR/models/ultralytics/bbox" \
    "$COMFY_DIR/models/ultralytics/segm" \
    "$COMFY_DIR/models/sams" \
    "$COMFY_DIR/models/insightface" \
    "${WORKSPACE%/}/storage/stable_diffusion/models/unet" \
    "${WORKSPACE%/}/storage/stable_diffusion/models/clip" \
    "${WORKSPACE%/}/storage/stable_diffusion/models/lora" \
    "${WORKSPACE%/}/storage/stable_diffusion/models/controlnet" \
    "${WORKSPACE%/}/storage/stable_diffusion/models/vae" \
    "${WORKSPACE%/}/storage/stable_diffusion/models/esrgan"
}

prefetch_models() {
  log "Downloading models… (tokened endpoints supported)"
  for u in "${CHECKPOINT_MODELS[@]}"; do provisioning_download "$u" "$COMFY_DIR/models/checkpoints" ; done
  for u in "${ULTRALYTICS_BBOX_MODELS[@]}"; do provisioning_download "$u" "$COMFY_DIR/models/ultralytics/bbox" ; done
  for u in "${ULTRALYTICS_SEGM_MODELS[@]}"; do provisioning_download "$u" "$COMFY_DIR/models/ultralytics/segm" ; done
  for u in "${SAM_MODELS[@]}"; do provisioning_download "$u" "$COMFY_DIR/models/sams" ; done
  for u in "${INSIGHTFACE_MODELS[@]}"; do provisioning_download "$u" "$COMFY_DIR/models/insightface" ; done
  for u in "${UNET_MODELS[@]}";     do provisioning_download "$u" "${WORKSPACE%/}/storage/stable_diffusion/models/unet" ; done
  for u in "${CLIP_MODELS[@]}";     do provisioning_download "$u" "${WORKSPACE%/}/storage/stable_diffusion/models/clip" ; done
  for u in "${LORA_MODELS[@]}";     do provisioning_download "$u" "${WORKSPACE%/}/storage/stable_diffusion/models/lora" ; done
  for u in "${CONTROLNET_MODELS[@]}"; do provisioning_download "$u" "${WORKSPACE%/}/storage/stable_diffusion/models/controlnet" ; done
  for u in "${VAE_MODELS[@]}";      do provisioning_download "$u" "${WORKSPACE%/}/storage/stable_diffusion/models/vae" ; done
  for u in "${ESRGAN_MODELS[@]}";   do provisioning_download "$u" "${WORKSPACE%/}/storage/stable_diffusion/models/esrgan" ; done
}

sanity_check() {
  log "Sanity check: import comfy from repo path"
  "$COMFYUI_VENV_PYTHON" - <<'PY'
import os, sys
COMFY_DIR = os.environ.get("COMFY_DIR", "/workspace/ComfyUI")
sys.path.insert(0, COMFY_DIR)
import comfy  # should succeed because we added the repo root
print("Comfy import OK from", COMFY_DIR)
PY
}

# entry
provisioning_start
