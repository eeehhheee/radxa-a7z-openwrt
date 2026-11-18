#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPENWRT_DIR="${OPENWRT_DIR:-${ROOT_DIR}/Temp/openwrt-25.12}"
AIOT_DIR="${AIOT_DIR:-${ROOT_DIR}/openwrt-sunxi-aiot}"

for path in \
  "${OPENWRT_DIR}/scripts/package-metadata.pl" \
  "${OPENWRT_DIR}/package/kernel/linux/modules/netfilter.mk" \
  "${OPENWRT_DIR}/package/kernel/mac80211/patches/build/210-wireless_netns_local_backport.patch" \
  "${OPENWRT_DIR}/target/linux/sunxi/image/cortexa53.mk" \
  "${AIOT_DIR}/include/kernel-6.18" \
  "${AIOT_DIR}/target/linux/allwinner/patches-6.18" \
  "${AIOT_DIR}/target/linux/allwinner/files/bsp/Kconfig" \
  "${AIOT_DIR}/target/linux/allwinner/files/arch/arm64/boot/dts/allwinner/sun60iw2p1.dtsi" \
  "${AIOT_DIR}/target/linux/allwinner/files/arch/arm64/boot/dts/allwinner/sun60iw2p1-cpu-vf.dtsi" \
  "${AIOT_DIR}/target/linux/allwinner/files/arch/arm64/boot/dts/allwinner/sun60i-a733-cubie-a7z.dts" \
  "${AIOT_DIR}/target/linux/allwinner/image/gen_sdcard_image.sh" \
  "${AIOT_DIR}/target/linux/allwinner/image/extlinux/extlinux.conf" \
  "${AIOT_DIR}/package/boot/uboot-allwinner/files/radxa-cubie-a7z"; do
  if [[ ! -e "${path}" ]]; then
    printf 'Required overlay input is missing: %s\n' "${path}" >&2
    exit 1
  fi
done

SUNXI_DIR="${OPENWRT_DIR}/target/linux/sunxi"
install -d \
  "${OPENWRT_DIR}/include" \
  "${OPENWRT_DIR}/target/linux/generic" \
  "${SUNXI_DIR}/cortexa53" \
  "${SUNXI_DIR}/files/arch/arm64/boot/dts/allwinner" \
  "${SUNXI_DIR}/files" \
  "${SUNXI_DIR}/patches-6.18" \
  "${OPENWRT_DIR}/package/boot/uboot-allwinner/files"

cp "${AIOT_DIR}/include/kernel-6.18" "${OPENWRT_DIR}/include/kernel-6.18"
cp "${AIOT_DIR}/include/kernel-6.18" "${OPENWRT_DIR}/target/linux/generic/kernel-6.18"
cp "${AIOT_DIR}/target/linux/generic/config-6.18" "${OPENWRT_DIR}/target/linux/generic/config-6.18"
cp -a "${AIOT_DIR}/target/linux/generic/pending-6.18" "${OPENWRT_DIR}/target/linux/generic/"
cp "${SUNXI_DIR}/config-6.12" "${SUNXI_DIR}/config-6.18"
cat "${AIOT_DIR}/target/linux/allwinner/config-6.18" >> "${SUNXI_DIR}/config-6.18"
cp "${SUNXI_DIR}/cortexa53/config-6.12" "${SUNXI_DIR}/cortexa53/config-6.18"
cp -a "${AIOT_DIR}/target/linux/allwinner/patches-6.18/." "${SUNXI_DIR}/patches-6.18/"
# The 25.12 overlay supplies its own A7Z-only DTB registration below;
# do not also apply the 24.10 patch, which references the absent A7A DTS.
rm -f -- "${SUNXI_DIR}/patches-6.18/0002-register-radxa-cubie-a7-device-trees.patch"
cp "${AIOT_DIR}/target/linux/allwinner/patches-6.6/0001-add-sunxi-bsp-patch.patch" \
  "${SUNXI_DIR}/patches-6.18/0000-add-sunxi-bsp.patch"
cp "${ROOT_DIR}/porting/openwrt-25.12/0002-register-a7z-dtb.patch" \
  "${SUNXI_DIR}/patches-6.18/9999-register-a7z-dtb.patch"
cp -a "${AIOT_DIR}/target/linux/allwinner/files/bsp" "${SUNXI_DIR}/files/"
cp "${AIOT_DIR}/target/linux/allwinner/files/arch/arm64/boot/dts/allwinner/sun60iw2p1.dtsi" \
  "${SUNXI_DIR}/files/arch/arm64/boot/dts/allwinner/"
cp "${AIOT_DIR}/target/linux/allwinner/files/arch/arm64/boot/dts/allwinner/sun60iw2p1-cpu-vf.dtsi" \
  "${SUNXI_DIR}/files/arch/arm64/boot/dts/allwinner/"
cp "${AIOT_DIR}/target/linux/allwinner/files/arch/arm64/boot/dts/allwinner/sun60i-a733-cubie-a7z.dts" \
  "${SUNXI_DIR}/files/arch/arm64/boot/dts/allwinner/"
cp "${AIOT_DIR}/target/linux/allwinner/image/gen_sdcard_image.sh" \
  "${SUNXI_DIR}/image/gen_a7z_sdcard_image.sh"
cp -a "${AIOT_DIR}/target/linux/allwinner/image/extlinux" "${SUNXI_DIR}/image/"
cp "${AIOT_DIR}/package/boot/uboot-allwinner/Makefile" \
  "${OPENWRT_DIR}/package/boot/uboot-allwinner/Makefile"
cp -a "${AIOT_DIR}/package/boot/uboot-allwinner/files/radxa-cubie-a7z" \
  "${OPENWRT_DIR}/package/boot/uboot-allwinner/files/"

git -C "${OPENWRT_DIR}" apply --unidiff-zero \
  "${ROOT_DIR}/porting/openwrt-25.12/0003-avoid-recursive-virtual-deps.patch"
git -C "${OPENWRT_DIR}" apply \
  "${ROOT_DIR}/porting/openwrt-25.12/0006-reemit-virtual-deps-without-self-rank.patch"
git -C "${OPENWRT_DIR}" apply \
  "${ROOT_DIR}/porting/openwrt-25.12/0004-nf-flow-depends-on-nft-core.patch"
install -m 0644 "${ROOT_DIR}/porting/openwrt-25.12/0005-mac80211-sockwq-6.18.patch" \
  "${OPENWRT_DIR}/package/kernel/mac80211/patches/build/245-sockwq-native-6.18.patch"
sh "${ROOT_DIR}/scripts/test-package-metadata-virtual-deps.sh" "${OPENWRT_DIR}"
grep -Fq 'DEPENDS:=+kmod-nf-conntrack +kmod-nft-core' \
  "${OPENWRT_DIR}/package/kernel/linux/modules/netfilter.mk"

sed -i 's/^KERNEL_PATCHVER:=6\.12$/KERNEL_PATCHVER:=6.18/' "${SUNXI_DIR}/Makefile"
sed -i 's/@TARGET_allwinner/@TARGET_sunxi @TARGET_sunxi_cortexa53/' \
  "${OPENWRT_DIR}/package/boot/uboot-allwinner/Makefile"
grep -q '^KERNEL_PATCHVER:=6\.18$' "${SUNXI_DIR}/Makefile"
grep -Fq 'DEPENDS:=@TARGET_sunxi @TARGET_sunxi_cortexa53' \
  "${OPENWRT_DIR}/package/boot/uboot-allwinner/Makefile"

git -C "${OPENWRT_DIR}" apply --unidiff-zero "${ROOT_DIR}/porting/openwrt-25.12/0001-add-a7z-image-build-step.patch"
git -C "${OPENWRT_DIR}" apply "${ROOT_DIR}/porting/openwrt-25.12/0002-add-radxa-a7z-profile.patch"

printf 'OpenWrt 25.12 overlay applied to %s\n' "${OPENWRT_DIR}"
