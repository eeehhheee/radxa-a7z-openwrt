#!/bin/bash
# Quick build script for Radxa A7Z OpenWrt

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENWRT_DIR="${PROJECT_ROOT}/openwrt-sunxi-aiot"

echo "=== Radxa A7Z OpenWrt Build Script ==="
echo "Project root: ${PROJECT_ROOT}"
echo "OpenWrt dir: ${OPENWRT_DIR}"

# Check if OpenWrt directory exists
if [ ! -d "${OPENWRT_DIR}" ]; then
    echo "Error: OpenWrt directory not found at ${OPENWRT_DIR}"
    exit 1
fi

cd "${OPENWRT_DIR}"

# Step 1: Update feeds
echo ""
echo "Step 1: Updating feeds..."
./scripts/feeds update -a

# Step 2: Install feeds
echo ""
echo "Step 2: Installing feeds..."
./scripts/feeds install -a

# Step 3: Configure
echo ""
echo "Step 3: Configuring build..."
if [ -f "${PROJECT_ROOT}/.config.default" ]; then
    cp "${PROJECT_ROOT}/.config.default" .config
fi
make defconfig

# Step 4: Build bootloader
echo ""
echo "Step 4: Building U-Boot bootloader..."
make package/boot/uboot-allwinner/compile V=s

# Step 5: Build firmware
echo ""
echo "Step 5: Building complete firmware..."
NPROC=$(nproc)
echo "Using ${NPROC} parallel jobs"
make -j${NPROC} V=s

# Check outputs
echo ""
echo "=== Build Complete ==="
if [ -d "bin/targets/allwinner/aiot/" ]; then
    echo "Firmware artifacts:"
    ls -lh bin/targets/allwinner/aiot/
else
    echo "Warning: No output directory found"
fi

echo ""
echo "Build log saved. Check bin/targets/allwinner/aiot/ for artifacts."
