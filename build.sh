#!/bin/bash
# Quick build script for Radxa A7Z OpenWrt

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENWRT_DIR="${PROJECT_ROOT}/openwrt-sunxi-aiot"
KERNEL_PATCHVER="${KERNEL_PATCHVER:-6.6}"

echo "=== Radxa A7Z OpenWrt Build Script ==="
echo "Project root: ${PROJECT_ROOT}"
echo "OpenWrt dir: ${OPENWRT_DIR}"
echo "Kernel patch version: ${KERNEL_PATCHVER}"

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
cp "${PROJECT_ROOT}/.config.default" .config
make KERNEL_PATCHVER="${KERNEL_PATCHVER}" defconfig
grep -q '^CONFIG_TARGET_allwinner_aiot_DEVICE_radxa-cubie-a7z=y$' .config

# Step 4: Build bootloader
echo ""
echo "Step 4: Building U-Boot bootloader..."
make KERNEL_PATCHVER="${KERNEL_PATCHVER}" package/boot/uboot-allwinner/compile V=s

# Step 5: Build firmware
echo ""
echo "Step 5: Building complete firmware..."
NPROC=$(nproc)
echo "Using ${NPROC} parallel jobs"
make KERNEL_PATCHVER="${KERNEL_PATCHVER}" -j"${NPROC}" V=s

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
