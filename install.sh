#!/usr/bin/env bash
# MaskDINO environment setup for this cluster (Euler).
# Run from anywhere: bash install.sh
set -e
set -o pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${REPO_ROOT}/myenv"
OPS_DIR="${REPO_ROOT}/maskdino/modeling/pixel_decoder/ops"

# --- start from a clean shell state -----------------------------------------
if [ -n "${VIRTUAL_ENV:-}" ]; then
    deactivate 2>/dev/null || true
fi
if command -v module >/dev/null 2>&1; then
    module purge
else
    source /etc/profile.d/modules.sh
    module purge
fi

echo "==> Loading toolchain modules"
module load stack/2024-06 gcc/12.2.0 cuda/11.3.1 python/3.9 eth_proxy

# --- venv --------------------------------------------------------------------
if [ -d "${VENV_DIR}" ]; then
    echo "==> Reusing existing venv at ${VENV_DIR}"
else
    echo "==> Creating venv at ${VENV_DIR}"
    python -m venv "${VENV_DIR}"
fi
source "${VENV_DIR}/bin/activate"

# --- python deps ---------------------------------------------------------------
echo "==> Installing base tooling"
# setuptools>=81 dropped pkg_resources, which torch==1.10.0 still imports
# internally at startup -> pin below 81.
pip install --upgrade pip wheel "setuptools<81"

echo "==> Installing torch/torchvision (cu113)"
pip install torch==1.10.0+cu113 torchvision==0.11.1+cu113 \
    --index-url https://download.pytorch.org/whl/cu113

echo "==> Installing detectron2"
python -m pip install detectron2 \
    -f https://dl.fbaipublicfiles.com/detectron2/wheels/cu113/torch1.10/index.html

echo "==> Installing opencv-python"
pip install opencv-python

echo "==> Installing project requirements"
pip install -r "${REPO_ROOT}/requirements.txt"

echo "==> Re-pinning numpy/setuptools/Pillow"
# torch/opencv/requirements.txt can transitively pull numpy>=2, which breaks
# torch 1.10's compiled extensions (built against the NumPy 1.x ABI). Pinning
# below 1.24 specifically (not just <2) because this detectron2 build still
# uses removed aliases like np.bool (e.g. in the panoptic-segmentation
# visualizer path) that numpy dropped in 1.24. Likewise Pillow>=10 removed
# the Image.LINEAR/BICUBIC aliases detectron2's transform.py still imports.
pip install "numpy==1.23.5" "setuptools<81" "Pillow<10"

python -c "
import torch, numpy, cv2
print('torch', torch.__version__, '| numpy', numpy.__version__, '| cv2', cv2.__version__)
print('cuda available:', torch.cuda.is_available())
"

# --- locate a pre-GCC11 host compiler for nvcc --------------------------------
# CUDA 11.3's nvcc only supports host compilers up to gcc-10, and the
# stack/2024-06 module tree only exposes gcc-12.2.0. Even bypassing that
# version check (-allow-unsupported-compiler) isn't enough: Ubuntu 22.04's
# glibc (2.35) headers gate a newer attribute syntax behind
# __GNUC_PREREQ(11,0), which nvcc's own header parser can't read. Building
# with a <11 host compiler makes glibc skip that code path entirely.
echo "==> Locating a pre-GCC11 compiler for building CUDA ops"
module purge
module load stack/2025-06 gcc/8.5.0
GCC85_CC="$(command -v gcc)"
GCC85_CXX="$(command -v g++)"
module purge
echo "    using CC=${GCC85_CC}"
echo "    using CXX=${GCC85_CXX}"

echo "==> Reloading toolchain + venv for the build"
module load stack/2024-06 gcc/12.2.0 cuda/11.3.1 python/3.9 eth_proxy
source "${VENV_DIR}/bin/activate"
export CC="${GCC85_CC}"
export CXX="${GCC85_CXX}"

# --- patch setup.py to bypass nvcc's compiler-version gate --------------------
SETUP_PY="${OPS_DIR}/setup.py"
if ! grep -q "allow-unsupported-compiler" "${SETUP_PY}"; then
    echo "==> Patching ${SETUP_PY} to add -allow-unsupported-compiler"
    sed -i '/"-D__CUDA_NO_HALF2_OPERATORS__",/a\            "-allow-unsupported-compiler",' "${SETUP_PY}"
fi

# --- build the CUDA ops --------------------------------------------------------
echo "==> Building MultiScaleDeformableAttention CUDA ops"
cd "${OPS_DIR}"
rm -rf build
FORCE_CUDA=1 sh make.sh

python -c "
import torch  # must be imported first: the extension needs torch's libc10.so etc. already loaded
import MultiScaleDeformableAttention as MSDA
print('MultiScaleDeformableAttention extension OK:', hasattr(MSDA, 'ms_deform_attn_forward'))
"

echo "==> Done. Next time, just run:"
echo "    module load stack/2024-06 gcc/12.2.0 cuda/11.3.1 python/3.9 eth_proxy"
echo "    source ${VENV_DIR}/bin/activate"
