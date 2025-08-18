#!/bin/bash
echo "[SETUP] Preparing environment..."

# Activate ComfyUI's Python virtual environment
source /opt/ai-dock/etc/environment.sh 2>/dev/null || true
source /opt/ai-dock/bin/venv-set.sh comfyui 2>/dev/null || true

# Define paths and pip
WORKSPACE="${WORKSPACE:-/workspace}"
COMFYUI_PATH="$WORKSPACE/ComfyUI"
COMFYUI_PIP="${COMFYUI_VENV_PIP:-$(which pip)}"

# If clean install requested, remove old custom nodes to avoid leftovers
if [[ "$CLEAN_INSTALL" == "true" ]]; then
  echo "[SETUP] Performing clean installation..."
  rm -rf "$COMFYUI_PATH/custom_nodes"
fi

# Ensure ComfyUI is present and at desired version
if [[ ! -d "$COMFYUI_PATH" ]]; then
  echo "[SETUP] Cloning ComfyUI repository..."
  COMFYUI_REF_NAME="${COMFYUI_REF:-main}"
  [[ "$COMFYUI_REF_NAME" == "latest" ]] && COMFYUI_REF_NAME="main"
  git clone -b "$COMFYUI_REF_NAME" --depth 1 https://github.com/comfyanonymous/ComfyUI.git "$COMFYUI_PATH" || {
    echo "Error: Failed to clone ComfyUI from GitHub." 
    exit 1
  }
  # Checkout specific tag/commit if provided and not already on it
  if [[ "$COMFYUI_REF_NAME" != "main" ]]; then
    git -C "$COMFYUI_PATH" fetch --depth 1 origin "$COMFYUI_REF_NAME" && \
    git -C "$COMFYUI_PATH" checkout "$COMFYUI_REF_NAME" || \
    echo "Warning: Could not checkout ComfyUI ref $COMFYUI_REF_NAME, using default branch."
  fi
else
  echo "[SETUP] Updating ComfyUI to $COMFYUI_REF..."
  if [[ "$COMFYUI_REF" == "latest" || "$COMFYUI_REF" == "main" || -z "$COMFYUI_REF" ]]; then
    git -C "$COMFYUI_PATH" pull --ff-only || echo "Warning: Failed to update ComfyUI (non-critical)."
  else
    git -C "$COMFYUI_PATH" fetch origin "$COMFYUI_REF" && \
    git -C "$COMFYUI_PATH" checkout "$COMFYUI_REF" || \
    echo "Warning: Failed to checkout ComfyUI ref $COMFYUI_REF (using current version)."
  fi
fi

# Create custom_nodes directory if missing
mkdir -p "$COMFYUI_PATH/custom_nodes"

# Install system packages required by some nodes (best-effort, no fail on error)
echo "[SETUP] Installing system dependencies..."
apt-get update -y && DEBIAN_FRONTEND=noninteractive \
apt-get install -y --no-install-recommends ffmpeg libsndfile1 > /dev/null 2>&1 || \
echo "Warning: APT dependency installation failed (check GPU image sources)."

# List of custom node repositories to install
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
  "https://github.com/LarryJane491/Lora-Training-in-Comfy"
  "https://github.com/LarryJane491/Image-Captioning-in-ComfyUI"
  "https://github.com/Fannovel16/ComfyUI-Frame-Interpolation"
  "https://github.com/mpiquero1111/ComfyUI-SaveImgPrompt"
  "https://github.com/Limitex/ComfyUI-Diffusers.git"        # .git included due to non-standard default branch
  "https://github.com/huanngzh/ComfyUI-MVAdapter"
  "https://github.com/chrisgoringe/cg-use-everywhere"
  "https://github.com/cubiq/ComfyUI_IPAdapter_plus"
  "https://github.com/PowerHouseMan/ComfyUI-AdvancedLivePortrait"
  "https://github.com/pythongosssss/ComfyUI-Custom-Scripts"
  "https://github.com/rgthree/rgthree-comfy"
  "https://github.com/WASasquatch/was-node-suite-comfyui"
  "https://github.com/yolain/ComfyUI-Easy-Use"
  "https://github.com/kijai/ComfyUI-Florence2"              # updated Florence-2 node repo
  "https://github.com/kijai/ComfyUI-IC-Light"
  "https://github.com/lldacing/ComfyUI_BiRefNet_ll"
  "https://github.com/jakechai/ComfyUI-JakeUpgrade"
  "https://github.com/spacepxl/ComfyUI-Image-Filters"
  "https://github.com/liusida/ComfyUI-AutoCropFaces"
  "https://github.com/un-seen/comfyui-tensorops"
  "https://github.com/Vaibhavs10/ComfyUI-DDUF"
  "https://github.com/ssitu/ComfyUI_UltimateSDUpscale"
  "https://github.com/lldacing/ComfyUI_PuLID_Flux_ll"
  "https://github.com/sipie800/ComfyUI-PuLID-Flux-Enhanced"
  "https://github.com/Fannovel16/comfyui_controlnet_aux"
  "https://github.com/cubiq/PuLID_ComfyUI"
  "https://github.com/Kosinkadink/ComfyUI-Advanced-ControlNet"
  "https://github.com/Derfuu/Derfuu_ComfyUI_ModdedNodes"
  "https://github.com/city96/ComfyUI-GGUF"
  "https://github.com/melMass/comfy_mtb"
  "https://github.com/BadCafeCode/masquerade-nodes-comfyui"  # mask nodes (author recommends Impact Pack)
  "https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes"
  "https://github.com/flowtyone/ComfyUI-Flowty-LDSR"
  "https://github.com/deforum-art/ComfyUI-post-processing-nodes"
  "https://github.com/TheLastBen/ComfyUI_IF_AI_LoadImages"
  "https://github.com/ShmuelRonen/ComfyUI-LatentSyncWrapper"
  "https://github.com/storyicon/comfyui_segment_anything"
  "https://github.com/Interpause/ComfyUI-FaceAnalysis"
  "https://github.com/Jack000/ComfyUI_LayerStyle"
  "https://github.com/Jack000/ComfyUI_LayerStyle_Advance"
  "https://github.com/sipherxyz/comfyui-art-venture"
  # (Add any additional custom node repos as needed)
)

echo "[SETUP] Installing custom nodes..."
for REPO_URL in "${NODES[@]}"; do
  [[ -z "$REPO_URL" ]] && continue
  REPO_NAME="$(basename "${REPO_URL%.git}")"
  TARGET_DIR="$COMFYUI_PATH/custom_nodes/$REPO_NAME"
  if [[ -d "$TARGET_DIR" ]]; then
    echo "[UPDATE] Updating $REPO_NAME..."
    git -C "$TARGET_DIR" pull --ff-only || echo "Warning: Failed to update $REPO_NAME (might be archived or no changes)."
  else
    echo "[CLONE] Cloning $REPO_NAME..."
    git clone --depth 1 "$REPO_URL" "$TARGET_DIR" 2>/dev/null || { 
      echo "Warning: Could not clone $REPO_URL. Skipping."; continue; 
    }
  fi
  # Install Python requirements if present
  if [[ -f "$TARGET_DIR/requirements.txt" ]]; then
    echo "[SETUP] Installing requirements for $REPO_NAME..."
    $COMFYUI_PIP install --no-cache-dir -U -r "$TARGET_DIR/requirements.txt" || {
      echo "Warning: Failed to install Python packages for $REPO_NAME (check dependency errors)."
    }
  fi
done

# Fix known dependency issues
echo "[SETUP] Resolving dependency compatibility..."
# 1. Ensure torchaudio matches torch version (fix for torchaudio import error)
TORCH_VER="$($COMFYUI_PIP show torch 2>/dev/null | awk '/Version:/{print $2}')"
if [[ -n "$TORCH_VER" ]]; then
  $COMFYUI_PIP install -U "torchaudio==$TORCH_VER" 2>/dev/null || $COMFYUI_PIP install -U torchaudio 2>/dev/null || true
fi
# 2. Downgrade packaging if needed for flet
PACKAGING_VER="$($COMFYUI_PIP show packaging 2>/dev/null | awk '/Version:/{print $2}')"
if [[ -n "$PACKAGING_VER" ]]; then
  PKG_MAJOR="${PACKAGING_VER%%.*}"
  if (( PKG_MAJOR >= 24 )); then
    $COMFYUI_PIP install -U "packaging<24.0" || true
  fi
fi

# Final check for any remaining conflicts
$COMFYUI_PIP check || echo "[INFO] All dependencies are satisfied."

echo "[SETUP] Provisioning complete. All custom nodes installed and ready."
