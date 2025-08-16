#!/usr/bin/env bash
set -euo pipefail

# ====== Settings ======
DEFAULT_WORKFLOW="https://raw.githubusercontent.com/kingaigfcash/aigfcash-runpod-template/refs/heads/main/workflows/default_workflow.json"

APT_PACKAGES=( git python3-pip python3-venv python3-dev build-essential libgl1 ffmpeg libsm6 libxext6 )

# critical pins needed for legacy nodes
PIP_PINS=( "Pillow==9.5.0" "huggingface_hub==0.25.2" "uv>=0.4.20" )

# general deps (PyAV first so ComfyUI can import `av` on first start)
PIP_PACKAGES=( "av" "numpy>=1.25.0" "einops" "transformers>=4.28.1" "tokenizers>=0.13.3" "sentencepiece"
               "safetensors>=0.4.2" "aiohttp>=3.11.8" "yarl>=1.18.0" "pyyaml" "scipy" "tqdm" "psutil"
               "kornia>=0.7.1" "comfyui-frontend-package==1.14.5" )

# curated nodes
NODES=(
  "https://github.com/ltdrdata/ComfyUI-Manager"
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
  "https://github.com/jojkaart/ComfyUI-sampler-lcm-alternative"
)

WORKFLOWS=( "https://github.com/kingaigfcash/aigfcash-runpod-template.git" )

CHECKPOINT_MODELS=(
  "https://huggingface.co/kingcashflow/modelcheckpoints/resolve/main/AIIM_Realism.safetensors"
  "https://huggingface.co/kingcashflow/modelcheckpoints/resolve/main/AIIM_Realism_FAST.safetensors"
  "https://huggingface.co/kingcashflow/modelcheckpoints/resolve/main/uberRealisticPornMergePonyxl_ponyxlHybridV1.safetensors"
  "https://huggingface.co/AiWise/epiCRealism-XL-vXI-aBEAST/resolve/5c3950c035ce565d0358b76805de5ef2c74be919/epicrealismXL_vxiAbeast.safetensors"
)
UNET_MODELS=()
VAE_MODELS=( "https://huggingface.co/stabilityai/sdxl-vae/resolve/main/diffusion_pytorch_model.safetensors" )
CLIP_MODELS=()
LORA_MODELS=(
  "https://huggingface.co/kingcashflow/LoRas/resolve/main/depth_of_field_slider_v1.safetensors"
  "https://huggingface.co/kingcashflow/LoRas/resolve/main/zoom_slider_v1.safetensors"
  "https://huggingface.co/kingcashflow/LoRas/resolve/main/add_detail.safetensors"
  "https://huggingface.co/kingcashflow/underboobXL/resolve/main/UnderboobXL.safetensors"
)
CONTROLNET_MODELS=(
  "https://huggingface.co/xinsir/controlnet-openpose-sdxl-1.0/resolve/main/diffusion_pytorch_model.safetensors"
  "https://huggingface.co/xinsir/controlnet-depth-sdxl-1.0/resolve/main/diffusion_pytorch_model.safetensors"
  "https://huggingface.co/dimitribarbot/controlnet-dwpose-sdxl-1.0/resolve/main/diffusion_pytorch_model.safetensors"
)
ESRGAN_MODELS=()
INSIGHTFACE_MODELS=( "https://huggingface.co/datasets/Gourieff/ReActor/resolve/main/models/inswapper_128.onnx" )
ULTRALYTICS_BBOX_MODELS=(
  "https://huggingface.co/Bingsu/adetailer/resolve/main/face_yolov8m.pt"
  "https://huggingface.co/Bingsu/adetailer/resolve/main/hand_yolov8n.pt"
  "https://huggingface.co/Bingsu/adetailer/resolve/main/face_yolov8n_v2.pt"
  "https://huggingface.co/Bingsu/adetailer/resolve/main/hand_yolov9c.pt"
  "https://huggingface.co/kingcashflow/underboobXL/resolve/main/Eyeful_v2-Individual.pt"
)
ULTRALYTICS_SEGM_MODELS=( "https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8m-seg.pt" )
SAM_MODELS=( "https://dl.fbaipublicfiles.com/segment_anything/sam_vit_b_01ec64.pth" )

# ====== Helpers ======
normalize_path(){ echo "${1//\/\///}"; }

pip_install() {
  local PIP_BIN="${COMFYUI_VENV_PIP:-/opt/environments/python/comfyui/bin/pip}"
  command -v "$PIP_BIN" >/dev/null 2>&1 || PIP_BIN="pip"
  "$PIP_BIN" install --no-cache-dir "$@"
}

retry(){ # retry <cmd...>
  local n=0 max=${MAX_RETRIES:-3}
  until "$@"; do
    n=$((n+1)); [[ $n -ge $max ]] && return 1
    echo "Retry $n/$max: $*"; sleep $((2*n))
  done
}

provisioning_print_header(){
  printf "\n===== Provisioning container =====\n"
}

provisioning_print_end(){
  printf "\nProvisioning complete: Web UI will start now\n"
}

apt_update_and_upgrade(){
  sudo apt-get update -y && sudo apt-get upgrade -y
}

provisioning_get_apt_packages(){
  [[ -n ${APT_PACKAGES[*]} ]] && sudo ${APT_INSTALL:-"apt-get install -y --no-install-recommends"} "${APT_PACKAGES[@]}"
}

provisioning_install_pins(){
  [[ -z ${PIP_PINS[*]} ]] && return 0
  printf "%s\n" "${PIP_PINS[@]}" > "/tmp/requirements-pins.txt"
  pip_install -r /tmp/requirements-pins.txt
}

install_build_tools_and_extras(){
  sudo apt-get update && sudo apt-get install -y build-essential
  pip_install --upgrade pip setuptools wheel
}

provisioning_get_pip_packages(){
  [[ -n ${PIP_PACKAGES[*]} ]] && pip_install "${PIP_PACKAGES[@]}"
}

provisioning_get_nodes(){
  local PIP_BIN="${COMFYUI_VENV_PIP:-/opt/environments/python/comfyui/bin/pip}"
  local PY_BIN="${COMFYUI_VENV_PYTHON:-/opt/environments/python/comfyui/bin/python}"
  local WORK="${WORKSPACE%/}/ComfyUI/custom_nodes"
  mkdir -p "$WORK"

  for repo in "${NODES[@]}"; do
    dir="${repo##*/}"
    path="$WORK/$dir"
    req="$path/requirements.txt"
    echo "---- Node: $dir"
    if [[ -d "$path" ]]; then
      [[ ${AUTO_UPDATE,,} != "false" ]] && ( cd "$path" && retry git pull --rebase --autostash || true )
    else
      retry git clone --recursive "$repo" "$path" || { echo "ERROR: clone failed: $dir"; continue; }
    fi
    [[ -f "$req" ]] && retry "$PIP_BIN" install --no-cache-dir -r "$req" || true
    [[ -f "$path/install.py" ]] && retry "$PY_BIN" "$path/install.py" || true
    [[ -x "$path/install.sh" ]] && ( cd "$path" && retry bash ./install.sh ) || true
    if [[ -f "$path/pyproject.toml" || -f "$path/setup.py" ]]; then
      retry "$PIP_BIN" install --no-cache-dir -e "$path" || true
    fi
  done

  retry "$PIP_BIN" install --no-cache-dir --upgrade comfyui-frontend-package || true
}

make_model_dirs(){
  mkdir -p "${WORKSPACE%/}/ComfyUI/models/"{checkpoints,ultralytics/bbox,ultralytics/segm,sams,insightface}
  mkdir -p "${WORKSPACE%/}/storage/stable_diffusion/models/"{unet,clip,lora,controlnet,vae,esrgan}
}

provisioning_download(){
  local url="$1" target_dir="$2" auth=""
  target_dir=$(normalize_path "$target_dir"); mkdir -p "$target_dir"
  [[ $url =~ ^https://huggingface.co ]] && auth="$HF_TOKEN"
  [[ $url =~ ^https://civitai.com ]] && auth="$CIVITAI_TOKEN"
  local out="$target_dir/$(basename "$url")"
  if [[ -s "$out" ]]; then echo "Skip existing: $out"; return 0; fi
  if [[ -n "$auth" ]]; then
    curl -fsSL -H "Authorization: Bearer $auth" -o "$out" "$url"
  else
    curl -fsSL -o "$out" "$url"
  fi
}

provisioning_get_models(){
  [[ -z ${2:-} ]] && return 0
  local dir="$1"; shift
  for u in "$@"; do provisioning_download "$u" "$dir"; done
}

fetch_all_models(){
  provisioning_get_models "${WORKSPACE%/}/ComfyUI/models/checkpoints" "${CHECKPOINT_MODELS[@]}"
  provisioning_get_models "${WORKSPACE%/}/storage/stable_diffusion/models/unet" "${UNET_MODELS[@]}"
  provisioning_get_models "${WORKSPACE%/}/storage/stable_diffusion/models/clip" "${CLIP_MODELS[@]}"
  provisioning_get_models "${WORKSPACE%/}/storage/stable_diffusion/models/lora" "${LORA_MODELS[@]}"
  provisioning_get_models "${WORKSPACE%/}/storage/stable_diffusion/models/controlnet" "${CONTROLNET_MODELS[@]}"
  provisioning_get_models "${WORKSPACE%/}/storage/stable_diffusion/models/vae" "${VAE_MODELS[@]}"
  provisioning_get_models "${WORKSPACE%/}/storage/stable_diffusion/models/esrgan" "${ESRGAN_MODELS[@]}"
  provisioning_get_models "${WORKSPACE%/}/ComfyUI/models/ultralytics/bbox" "${ULTRALYTICS_BBOX_MODELS[@]}"
  provisioning_get_models "${WORKSPACE%/}/ComfyUI/models/ultralytics/segm" "${ULTRALYTICS_SEGM_MODELS[@]}"
  provisioning_get_models "${WORKSPACE%/}/ComfyUI/models/sams" "${SAM_MODELS[@]}"
  provisioning_get_models "${WORKSPACE%/}/ComfyUI/models/insightface" "${INSIGHTFACE_MODELS[@]}"
}

provisioning_get_workflows(){
  for repo in "${WORKFLOWS[@]}"; do
    dir=$(basename "$repo" .git)
    temp="/tmp/$dir"; tgt="${WORKSPACE%/}/ComfyUI/user/default/workflows"
    if [[ -d "$temp" ]]; then
      [[ ${AUTO_UPDATE,,} != "false" ]] && ( cd "$temp" && git pull )
    else
      git clone "$repo" "$temp"
    fi
    mkdir -p "$tgt"
    [[ -d "$temp/workflows" ]] && cp -r "$temp/workflows"/* "$tgt/" || true
  done
}

provisioning_get_default_workflow(){
  [[ -z "$DEFAULT_WORKFLOW" ]] && return 0
  wf=$(curl -fsSL "$DEFAULT_WORKFLOW" || true)
  [[ -z "$wf" ]] || echo "export const defaultGraph = $wf;" > "${WORKSPACE%/}/ComfyUI/web/scripts/defaultGraph.js"
}

provisioning_has_valid_hf_token(){
  [[ -n "${HF_TOKEN:-}" ]] || return 1
  curl -fsS -o /dev/null -H "Authorization: Bearer $HF_TOKEN" https://huggingface.co/api/whoami-v2
}

# ====== Entry ======
provisioning_start(){
  # activate comfyui venv the way AI-Dock expects
  source /opt/ai-dock/etc/environment.sh
  source /opt/ai-dock/bin/venv-set.sh comfyui

  export HF_HOME="${WORKSPACE%/}/.cache/huggingface"
  export XDG_CACHE_HOME="${WORKSPACE%/}/.cache"
  export TORCH_HOME="${WORKSPACE%/}/.cache/torch"

  provisioning_print_header
  apt_update_and_upgrade
  provisioning_get_apt_packages
  provisioning_install_pins        # Pillow, huggingface_hub, uv
  install_build_tools_and_extras
  provisioning_get_pip_packages    # av + friends
  provisioning_get_nodes           # clone/update nodes + reqs
  make_model_dirs
  fetch_all_models
  provisioning_get_workflows
  provisioning_get_default_workflow
  provisioning_print_end
}

# Optional gated downloads by HF token (bbox/segm/SAM/insightface)
if provisioning_has_valid_hf_token; then
  :
fi

provisioning_start
