# This file will be sourced in default.sh
# https://github.com/kingaigfcash/aigfcash-runpod-template

# ---------------- User-tunable ----------------
# Set to "stable" (auto-latest tag), "master", or an explicit tag like "v0.3.50".
: "${PIN_COMFYUI_REF:=stable}"

DEFAULT_WORKFLOW="https://raw.githubusercontent.com/kingaigfcash/aigfcash-runpod-template/refs/heads/main/workflows/default_workflow.json"

APT_PACKAGES=(
  git git-lfs curl
  python3-pip python3-venv python3-dev
  build-essential pkg-config
  libgl1 libglib2.0-0 libsm6 libxext6 ffmpeg
)

# Keep this light; torch/xformers come with the base image.
PIP_PACKAGES=(
  wheel setuptools pip
  # small but commonly-missing runtime deps seen in your logs
  av colorama gguf piexif pydantic-settings alembic uv
  imageio imageio-ffmpeg opencv-python-headless matplotlib
  timm albumentations shapely
  safetensors>=0.4.2 transformers>=4.28.1 tokenizers>=0.13.3 sentencepiece
  psutil pyyaml tqdm einops scipy kornia>=0.7.1
)

# ---------------- Custom nodes ----------------
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
  # NOTE: archived / legacy, can be skipped; kept for parity
  "https://github.com/0xbitches/ComfyUI-LCM"
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

WORKFLOWS=("https://github.com/kingaigfcash/aigfcash-runpod-template.git")

# ---------------- Models (same as yours) ----------------
CHECKPOINT_MODELS=(
  "https://huggingface.co/kingcashflow/modelcheckpoints/resolve/main/AIIM_Realism.safetensors"
  "https://huggingface.co/kingcashflow/modelcheckpoints/resolve/main/AIIM_Realism_FAST.safetensors"
  "https://huggingface.co/kingcashflow/modelcheckpoints/resolve/main/uberRealisticPornMergePonyxl_ponyxlHybridV1.safetensors"
  "https://huggingface.co/AiWise/epiCRealism-XL-vXI-aBEAST/resolve/5c3950c035ce565d0358b76805de5ef2c74be919/epicrealismXL_vxiAbeast.safetensors"
)
UNET_MODELS=()
VAE_MODELS=("https://huggingface.co/stabilityai/sdxl-vae/resolve/main/diffusion_pytorch_model.safetensors")
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
INSIGHTFACE_MODELS=("https://huggingface.co/datasets/Gourieff/ReActor/resolve/main/models/inswapper_128.onnx")
ULTRALYTICS_BBOX_MODELS=(
  "https://huggingface.co/Bingsu/adetailer/resolve/main/face_yolov8m.pt"
  "https://huggingface.co/Bingsu/adetailer/resolve/main/hand_yolov8n.pt"
  "https://huggingface.co/Bingsu/adetailer/resolve/main/face_yolov8n_v2.pt"
  "https://huggingface.co/Bingsu/adetailer/resolve/main/hand_yolov9c.pt"
  "https://huggingface.co/kingcashflow/underboobXL/resolve/main/Eyeful_v2-Individual.pt"
)
ULTRALYTICS_SEGM_MODELS=("https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8m-seg.pt")
SAM_MODELS=("https://dl.fbaipublicfiles.com/segment_anything/sam_vit_b_01ec64.pth")

# ----------------- DO NOT EDIT BELOW -------------------

normalize_path() { echo "${1//\/\///}"; }

# Choose venv pip (or micromamba) used by the base image
pip_install() {
  if [[ -z $MAMBA_BASE ]]; then
    "$COMFYUI_VENV_PIP" install --no-cache-dir "$@"
  else
    micromamba run -n comfyui pip install --no-cache-dir "$@"
  fi
}

provisioning_start() {
  if [[ ! -d /opt/environments/python ]]; then export MAMBA_BASE=true; fi
  source /opt/ai-dock/etc/environment.sh
  source /opt/ai-dock/bin/venv-set.sh comfyui

  provisioning_print_header

  sudo apt-get update -y
  sudo apt-get upgrade -y
  provisioning_get_apt_packages
  git lfs install

  # Keep the venv tooling modern
  "$COMFYUI_VENV_PIP" install -U pip setuptools wheel

  # 1) Make sure core ComfyUI is the requested version and fully satisfied
  provisioning_update_comfyui_core

  # 2) Nodes + their requirements
  provisioning_get_nodes

  # 3) Base python deps you want regardless of nodes
  provisioning_get_pip_packages

  # 4) Known upstream breakages (pins) + sanity check
  provisioning_fix_known_breakages

  # 5) Models/dirs/workflows
  mkdir -p "${WORKSPACE}/ComfyUI/models/checkpoints" \
           "${WORKSPACE}/ComfyUI/models/ultralytics/bbox" \
           "${WORKSPACE}/ComfyUI/models/ultralytics/segm" \
           "${WORKSPACE}/ComfyUI/models/sams" \
           "${WORKSPACE}/ComfyUI/models/insightface"

  provisioning_get_models "${WORKSPACE}/ComfyUI/models/checkpoints" "${CHECKPOINT_MODELS[@]}"
  provisioning_get_models "${WORKSPACE}/storage/stable_diffusion/models/unet" "${UNET_MODELS[@]}"
  provisioning_get_models "${WORKSPACE}/storage/stable_diffusion/models/clip" "${CLIP_MODELS[@]}"
  provisioning_get_models "${WORKSPACE}/storage/stable_diffusion/models/lora" "${LORA_MODELS[@]}"
  provisioning_get_models "${WORKSPACE}/storage/stable_diffusion/models/controlnet" "${CONTROLNET_MODELS[@]}"
  provisioning_get_models "${WORKSPACE}/storage/stable_diffusion/models/vae" "${VAE_MODELS[@]}"
  provisioning_get_models "${WORKSPACE}/storage/stable_diffusion/models/esrgan" "${ESRGAN_MODELS[@]}"
  provisioning_get_models "${WORKSPACE}/ComfyUI/models/ultralytics/bbox" "${ULTRALYTICS_BBOX_MODELS[@]}"
  provisioning_get_models "${WORKSPACE}/ComfyUI/models/ultralytics/segm" "${ULTRALYTICS_SEGM_MODELS[@]}"
  provisioning_get_models "${WORKSPACE}/ComfyUI/models/sams" "${SAM_MODELS[@]}"
  provisioning_get_models "${WORKSPACE}/ComfyUI/models/insightface" "${INSIGHTFACE_MODELS[@]}"

  provisioning_get_workflows
  provisioning_print_end
  start_additional_downloads
}

provisioning_get_apt_packages() {
  [[ -n $APT_PACKAGES ]] && sudo $APT_INSTALL "${APT_PACKAGES[@]}"
}

provisioning_get_pip_packages() {
  [[ -n $PIP_PACKAGES ]] && pip_install "${PIP_PACKAGES[@]}"
}

# --- NEW: Ensure ComfyUI itself is pinned to a stable ref and fully installed
provisioning_update_comfyui_core() {
  local repo="${WORKSPACE}/ComfyUI"
  if [[ ! -d "$repo/.git" ]]; then
    echo "ComfyUI repo not found at $repo; skipping core update."
    return
  fi
  pushd "$repo" >/dev/null

  git fetch origin --tags --prune
  local target="$PIN_COMFYUI_REF"
  if [[ "$target" == "stable" || "$target" == "latest" ]]; then
    target="$(git describe --tags "$(git rev-list --tags --max-count=1)")"
  fi
  if [[ -n "$target" ]]; then
    echo "Checking out ComfyUI @$target"
    git checkout -q "$target" || true
  else
    echo "Pulling ComfyUI master"
    git checkout -q master || true
    git pull --rebase --autostash
  fi
  git submodule update --init --recursive

  # Install/upgrade ComfyUI’s own requirements (brings the right frontend)
  if [[ -f requirements.txt ]]; then
    pip_install -r requirements.txt
  fi

  # Belt-and-suspenders: ensure current recommended frontend is present
  # (your logs had 1.14.5 while ComfyUI expected ≈1.25.x) 
  pip_install -U "comfyui-frontend-package>=1.25.8" "comfyui-embedded-docs" "comfyui-workflow-templates"

  popd >/dev/null
}

provisioning_get_nodes() {
  echo "Installing build tools for nodes…"
  sudo apt-get update -y && sudo apt-get install -y build-essential

  for repo in "${NODES[@]}"; do
    dir="${repo##*/}"
    path="${WORKSPACE}/ComfyUI/custom_nodes/${dir}"
    req="${path}/requirements.txt"

    if [[ -d "$path" ]]; then
      if [[ ${AUTO_UPDATE,,} != "false" ]]; then
        echo "Updating node: $dir"
        (cd "$path" && git pull --rebase --autostash || true)
      fi
    else
      echo "Cloning node: $dir"
      git clone --recursive "$repo" "$path"
    fi

    if [[ -f "$req" ]]; then
      echo "Installing $dir requirements.txt"
      pip_install -r "$req" || true
    fi
    # Some nodes actually are Python packages; install them too
    if [[ -f "${path}/pyproject.toml" || -f "${path}/setup.py" ]]; then
      echo "Installing $dir as a package"
      pip_install "$path" || true
    fi
  done

  echo "Upgrading comfyui-frontend-package (safety)…"
  pip_install -U comfyui-frontend-package
}

# Known upstream breakages & sanity checks
provisioning_fix_known_breakages() {
  # Pillow 10+ removed Image.LINEAR -> pin to <10 for Detectron2/OneFormer (aux preprocessors)
  pip_install "Pillow==9.5.0"   # keeps PIL.Image.LINEAR available

  # huggingface_hub removed cached_download -> pin to a version that still exports it
  pip_install "huggingface_hub==0.25.2"

  # ORT providers for controlnet_aux: try GPU wheel, fallback to CPU
  pip_install "onnx>=1.16.0"
  pip_install "onnxruntime-gpu==1.19.2" || pip_install "onnxruntime==1.19.2"

  # Quick imports check to surface anything critical early
  "$COMFYUI_VENV_PYTHON" - <<'PY'
mods = ["av","colorama","piexif","gguf","PIL","huggingface_hub","onnx","cv2"]
import importlib, sys
missing = []
for m in mods:
  try: importlib.import_module(m)
  except Exception as e: missing.append(f"{m} -> {e}")
if missing:
  print("Sanity import gaps:", "; ".join(missing), file=sys.stderr)
PY
}

provisioning_get_workflows() {
  for repo in "${WORKFLOWS[@]}"; do
    dir=$(basename "$repo" .git)
    tmp="/tmp/${dir}"
    tgt="${WORKSPACE}/ComfyUI/user/default/workflows"
    if [[ -d "$tmp" ]]; then
      [[ ${AUTO_UPDATE,,} != "false" ]] && (cd "$tmp" && git pull --rebase --autostash)
    else
      git clone "$repo" "$tmp"
    fi
    mkdir -p "$tgt"
    [[ -d "$tmp/workflows" ]] && cp -r "$tmp/workflows"/* "$tgt/"
  done
}

provisioning_get_default_workflow() {
  if [[ -n $DEFAULT_WORKFLOW ]]; then
    wf=$(curl -s "$DEFAULT_WORKFLOW")
    [[ -n $wf ]] && echo "export const defaultGraph = $wf;" > "${WORKSPACE}/ComfyUI/web/scripts/defaultGraph.js"
  fi
}

provisioning_get_models() {
  [[ -z $2 ]] && return 1
  dir=$(normalize_path "$1"); mkdir -p "$dir"; shift
  for url in "$@"; do
    echo "Downloading: $url"
    provisioning_download "$url" "$dir" || echo "WARN: failed $url"
  done
}

provisioning_download() {
  local url="$1" target_dir="$2" auth_token="" filename=""
  target_dir=$(normalize_path "$target_dir")
  [[ $url =~ ^https://huggingface.co ]] && auth_token="$HF_TOKEN"
  [[ $url =~ ^https://civitai.com ]] && auth_token="$CIVITAI_TOKEN"

  mkdir -p "$target_dir"
  filename="$(basename "$url")"; [[ -z $filename ]] && { echo "ERROR: bad URL"; return 1; }
  local target="$target_dir/$filename"

  if [[ -s "$target" ]]; then echo "Exists: $target"; return 0; fi
  echo "-> $target"
  if [[ -n $auth_token ]]; then
    curl -fS -L -H "Authorization: Bearer $auth_token" -o "$target" "$url" || return 1
  else
    curl -fS -L -o "$target" "$url" || return 1
  fi
  [[ -s "$target" ]] || { echo "ERROR: empty download"; return 1; }
}

provisioning_print_header() {
  printf "\n########## Provisioning container (ComfyUI) ##########\n\n"
  if [[ $DISK_GB_ALLOCATED -lt $DISK_GB_REQUIRED ]]; then
    printf "WARNING: Disk size (%sGB) below recommended %sGB\n" "$DISK_GB_ALLOCATED" "$DISK_GB_REQUIRED"
  fi
}
provisioning_print_end() { printf "\nProvisioning complete — starting Web UI\n\n"; }

# Optional token-gated model pulls (unchanged logic)
provisioning_has_valid_hf_token() {
  [[ -n "$HF_TOKEN" ]] || return 1
  local r; r=$(curl -o /dev/null -s -w "%{http_code}" -H "Authorization: Bearer $HF_TOKEN" https://huggingface.co/api/whoami-v2)
  [[ "$r" == "200" ]]
}
provisioning_has_valid_civitai_token() {
  [[ -n "$CIVITAI_TOKEN" ]] || return 1
  local r; r=$(curl -o /dev/null -s -w "%{http_code}" -H "Authorization: Bearer $CIVITAI_TOKEN" "https://civitai.com/api/v1/models?hidden=1&limit=1")
  [[ "$r" == "200" ]]
}
if provisioning_has_valid_hf_token; then
  echo "Downloading bbox models…"
  for u in "${ULTRALYTICS_BBOX_MODELS[@]}"; do provisioning_download "$u" "$WORKSPACE/ComfyUI/models/ultralytics/bbox"; done
  echo "Downloading segm models…"
  for u in "${ULTRALYTICS_SEGM_MODELS[@]}"; do provisioning_download "$u" "$WORKSPACE/ComfyUI/models/ultralytics/segm"; done
  echo "Downloading SAM models…"
  for u in "${SAM_MODELS[@]}"; do provisioning_download "$u" "$WORKSPACE/ComfyUI/models/sams"; done
  echo "Downloading Insightface models…"
  for u in "${INSIGHTFACE_MODELS[@]}"; do provisioning_download "$u" "$WORKSPACE/ComfyUI/models/insightface"; done
else
  echo "NOTE: Hugging Face token not present/valid — skipping gated model downloads."
fi

provisioning_start
