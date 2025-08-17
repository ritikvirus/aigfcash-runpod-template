#!/usr/bin/env bash
# optimized.sh – provisioning for ghcr.io/ai-dock/comfyui
set -Eeuo pipefail

### ---------- USER CONFIG ----------
DEFAULT_WORKFLOW="https://raw.githubusercontent.com/kingaigfcash/aigfcash-runpod-template/refs/heads/main/workflows/default_workflow.json"

APT_PACKAGES=(
  git git-lfs python3-pip python3-venv python3-dev
  build-essential pkg-config curl
  libgl1 libglib2.0-0 ffmpeg libsm6 libxext6
)

PIP_BASE=(
  wheel setuptools pip
  opencv-python-headless imageio imageio-ffmpeg
  matplotlib av colorama piexif
  pydantic-settings alembic uv timm albumentations shapely
  safetensors>=0.4.2 transformers>=4.28.1 tokenizers>=0.13.3 sentencepiece
  psutil pyyaml tqdm einops scipy "kornia>=0.7.1"
)

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

### ---------- BOOTSTRAP ----------
if [[ ! -d /opt/environments/python ]]; then export MAMBA_BASE=true; fi
source /opt/ai-dock/etc/environment.sh
source /opt/ai-dock/bin/venv-set.sh comfyui

PIP="${COMFYUI_VENV_PIP}"
PY="${COMFYUI_VENV_PYTHON}"

apt-get update -y
apt-get upgrade -y
apt-get install -y "${APT_PACKAGES[@]}" || true
git lfs install || true
"$PIP" install --upgrade pip setuptools wheel
"$PIP" install --no-cache-dir "${PIP_BASE[@]}"

# Known breakages
"$PIP" install --no-cache-dir "Pillow==9.5.0"            # keep PIL.Image.LINEAR alive
"$PIP" install --no-cache-dir "huggingface_hub==0.25.2"  # cached_download for GlifNodes

# Clone/update nodes + install *all* requirements*.txt (recursive, shallow)
mkdir -p "${WORKSPACE}/ComfyUI/custom_nodes"
for repo in "${NODES[@]}"; do
  dir="${repo##*/}"
  path="${WORKSPACE}/ComfyUI/custom_nodes/${dir}"
  if [[ -d $path ]]; then
    [[ "${AUTO_UPDATE:-true}" != "false" ]] && (cd "$path" && git pull --rebase --autostash || true)
  else
    git clone --recursive --depth=1 "$repo" "$path" || true
  fi
  # Install any requirements*.txt found up to depth 3
  while IFS= read -r req; do
    echo "Installing requirements from $req"
    "$PIP" install --no-cache-dir -r "$req" || true
  done < <(find "$path" -maxdepth 3 -type f -iname "requirements*.txt" | sort -u)
done

# Keep ComfyUI frontend current
"$PIP" install --upgrade comfyui-frontend-package

# Models: helpers
normpath(){ echo "${1//\/\///}"; }
dl(){
  local url="$1" dir="$2" token=""
  [[ "$url" =~ ^https://huggingface.co ]] && token="${HF_TOKEN:-}"
  [[ "$url" =~ ^https://civitai.com ]] && token="${CIVITAI_TOKEN:-}"
  mkdir -p "$dir"
  fname="$(basename "$url")"
  [[ -s "$dir/$fname" ]] && { echo "Exists: $dir/$fname"; return 0; }
  echo "Downloading -> $dir/$fname"
  if [[ -n "$token" ]]; then
    curl -fsSL -H "Authorization: Bearer $token" -o "$dir/$fname" "$url"
  else
    curl -fsSL -o "$dir/$fname" "$url"
  fi
  [[ -s "$dir/$fname" ]] || echo "WARN: empty download $url"
}

# Create model dirs
mkdir -p \
  "${WORKSPACE}/ComfyUI/models/checkpoints" \
  "${WORKSPACE}/ComfyUI/models/ultralytics/bbox" \
  "${WORKSPACE}/ComfyUI/models/ultralytics/segm" \
  "${WORKSPACE}/ComfyUI/models/sams" \
  "${WORKSPACE}/ComfyUI/models/insightface" \
  "${WORKSPACE}/storage/stable_diffusion/models/unet" \
  "${WORKSPACE}/storage/stable_diffusion/models/clip" \
  "${WORKSPACE}/storage/stable_diffusion/models/lora" \
  "${WORKSPACE}/storage/stable_diffusion/models/controlnet" \
  "${WORKSPACE}/storage/stable_diffusion/models/vae" \
  "${WORKSPACE}/storage/stable_diffusion/models/esrgan"

# Pull models
for u in "${CHECKPOINT_MODELS[@]}";      do dl "$u" "${WORKSPACE}/ComfyUI/models/checkpoints"; done
for u in "${UNET_MODELS[@]}";            do dl "$u" "${WORKSPACE}/storage/stable_diffusion/models/unet"; done
for u in "${CLIP_MODELS[@]}";            do dl "$u" "${WORKSPACE}/storage/stable_diffusion/models/clip"; done
for u in "${LORA_MODELS[@]}";            do dl "$u" "${WORKSPACE}/storage/stable_diffusion/models/lora"; done
for u in "${CONTROLNET_MODELS[@]}";      do dl "$u" "${WORKSPACE}/storage/stable_diffusion/models/controlnet"; done
for u in "${VAE_MODELS[@]}";             do dl "$u" "${WORKSPACE}/storage/stable_diffusion/models/vae"; done
for u in "${ESRGAN_MODELS[@]}";          do dl "$u" "${WORKSPACE}/storage/stable_diffusion/models/esrgan"; done
for u in "${ULTRALYTICS_BBOX_MODELS[@]}";do dl "$u" "${WORKSPACE}/ComfyUI/models/ultralytics/bbox"; done
for u in "${ULTRALYTICS_SEGM_MODELS[@]}";do dl "$u" "${WORKSPACE}/ComfyUI/models/ultralytics/segm"; done
for u in "${SAM_MODELS[@]}";             do dl "$u" "${WORKSPACE}/ComfyUI/models/sams"; done
for u in "${INSIGHTFACE_MODELS[@]}";     do dl "$u" "${WORKSPACE}/ComfyUI/models/insightface"; done

# Workflows
for repo in "${WORKFLOWS[@]}"; do
  name="$(basename "$repo" .git)"
  tmp="/tmp/$name"; tgt="${WORKSPACE}/ComfyUI/user/default/workflows"
  [[ -d "$tmp" ]] && (cd "$tmp" && git pull --rebase --autostash) || git clone "$repo" "$tmp"
  mkdir -p "$tgt"; [[ -d "$tmp/workflows" ]] && cp -r "$tmp/workflows/"* "$tgt/" || true
done

# Sanity imports & friendly restart
"$PY" - <<'PY'
mods = ["av","colorama","piexif","PIL","huggingface_hub","timm","albumentations"]
missing = []
for m in mods:
    try: __import__(m)
    except Exception as e: missing.append(f"{m}: {e}")
print("Sanity check:", "OK" if not missing else f"Missing -> {missing}")
PY

# Restart ComfyUI so it sees the new deps immediately
command -v supervisorctl >/dev/null 2>&1 && supervisorctl restart comfyui || true
echo "Provisioning complete."
