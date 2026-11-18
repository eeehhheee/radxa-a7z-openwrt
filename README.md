# Radxa Cubie-A7Z OpenWrt Porting Project

这是针对 Radxa Cubie-A7Z 开发板的 OpenWrt 完整移植项目，包含自动化构建流水线。

## 项目概述

- **目标设备**: Radxa Cubie-A7Z (Allwinner A733 SoC)
- **OpenWrt 版本**: openwrt-24.10（基于 openwrt-sunxi-aiot）
- **默认内核版本**: Linux 6.6
- **实验性内核版本**: Linux 6.18（A7A/A7Z 配置通过，但构建暴露出 24.10 的 `backports-6.12.44` 与 6.18 API 不兼容；workflow 已切换到 25.12 的 `backports-6.18.55`，修复待重跑验证）
- **OpenWrt 25.12**: 父仓库 overlay 将 A7Z 接入 `sunxi/cortexa53` 并复用 vendor boot layout；首次 defconfig 暴露虚拟包 provider 自依赖，修正与回归测试已准备，后续 CI 验证中
- **构建方式**: GitHub Actions 自动化构建

## 目录结构

```
.
├── openwrt-sunxi-aiot/      # OpenWrt 源码（openwrt-24.10 分支）
├── allwinner-bsp/            # AllWinner BSP 驱动支持
├── .github/
│   └── workflows/
│       └── build-openwrt.yml # GitHub Actions 自动构建流水线
└── OPENWRT_RADXA_CUBIE_A7Z.md # 详细移植文档
```

## 快速开始

### 本地构建

```bash
# 默认构建 OpenWrt 24.10 + Linux 6.6
./build.sh

# 选择实验性 Linux 6.18（不修改子模块 Makefile）
KERNEL_PATCHVER=6.18 ./build.sh
```

脚本会更新并安装 feeds、生成 A7Z 配置、先编译 U-Boot，再编译完整固件。编译输出在 `openwrt-sunxi-aiot/bin/targets/allwinner/aiot/`。

### 支持的启动介质

项目支持三种启动方式：

- **SD Card** (`boot0_sdcard.bin`)
- **SPI NOR Flash** (`boot0_spinor.bin`)
- **UFS** (`boot0_ufs.bin`)

启动文件位置: `openwrt-sunxi-aiot/package/boot/uboot-allwinner/files/radxa-cubie-a7z/`

## 硬件支持

### 当前验证状态

仓库中存在 A7Z 的 target、镜像定义、设备树和预置 U-Boot 文件，但当前没有可复核的串口日志、硬件测试记录或成功的 GitHub Actions 运行结论。因此以下功能均应视为**待验证**：启动介质、网络、USB、PCIe、SD、GPIO/LED。DTS 中的 `skip-uboot-pcie-training` 目前只有设备树写入，仓库内没有对应的 U-Boot consumer，不能据此宣称 PCIe workaround 已生效。

### 已知问题

- Linux 6.18 前次 A7A/A7Z CI 在 `mac80211` 编译阶段失败：24.10 的 `backports-6.12.44` 与 Linux 6.18 的 `netns_local`/timer/socket API 不兼容。6.18 workflow 已改用 25.12 的 `backports-6.18.55` 及其兼容补丁，尚待 Actions 验证；另已修复 `kmod-nf-flow` 对 `nf_tables.ko` 的包依赖。
- OpenWrt 25.12 overlay 的首次 defconfig 因虚拟包默认 provider 自依赖失败；已调整 provider 过滤顺序并增加默认 provider 自依赖回归测试，同时修正设备配置符号和内核元数据路径，等待新 CI 验证。
- 25.12 overlay 尚未有成功构建，硬件启动、网络、USB、PCIe、SD、GPIO/LED 均未实机验证。DTS 中的 `skip-uboot-pcie-training` 目前只有设备树写入，仓库内没有对应的 U-Boot consumer，不能据此宣称 PCIe workaround 已生效。


## 构建流水线

### GitHub Actions

仓库包含三条构建流水线：

- `build-openwrt.yml`: OpenWrt 24.10 + Linux 6.6，A7Z profile。
- `build-openwrt-6.18.yml`: OpenWrt 24.10 + Linux 6.18，A7Z/A7A matrix，选择 LuCI、SSH、网络诊断、USB/存储、NVMe/PCI、USB Ethernet、Wi-Fi 和常用命令行工具。
- `build-openwrt-25.12.yml`: OpenWrt 25.12 `sunxi/cortexa53` + Linux 6.18 A7Z overlay，构建常用网络、管理和存储包。

三条 workflow 使用 `ubuntu-24.04`，支持 push、Pull Request（标准 workflow）和手动触发。产物与构建日志上传到 Actions artifacts。查看构建历史: [Actions 标签](../../actions)

## 设备刷写指南

### SD 卡刷写（推荐首次测试）

```bash
# 在 Linux 上刷写 (替换 /dev/sdX 为实际设备)
dd if=openwrt-snapshot-allwinner-aiot-radxa_cubie-a7z-sysupgrade.img.gz \
   of=/dev/sdX bs=4M status=progress
sync
```

### 串口访问

```
波特率: 115200
数据位: 8
停止位: 1
流控: 无
```

## 开发指南

### 修改设备树

设备树文件: `openwrt-sunxi-aiot/target/linux/allwinner/files/arch/arm64/boot/dts/allwinner/sun60i-a733-cubie-a7z.dts`

修改后需要重新编译:

```bash
cd openwrt-sunxi-aiot
make clean
make -j$(nproc) V=s
```

### 添加驱动

BSP 驱动位置: `allwinner-bsp/`

与 OpenWrt 的补丁集成: `openwrt-sunxi-aiot/target/linux/allwinner/patches-6.6/`

### 调试内核启动

使用串口查看完整启动日志:

```bash
dmesg
cat /proc/device-tree/model
```

## 常见问题

### Q: 构建失败怎么办？

A: 查看 GitHub Actions 的构建日志（Artifacts 中的 `build-log`），或在本地重现:

```bash
cd openwrt-sunxi-aiot
make -j1 V=s 2>&1 | tee build.log
```

### Q: 如何定制固件包？

A: 在 `menuconfig` 中选择需要的软件包，或修改:

```bash
make menuconfig
# 选择所需的 LuCI、网络、存储等包
make -j$(nproc) V=s
```

### Q: 如何回滚固件？

A: 准备 SD 卡恢复镜像，按文档第 4 节指引进行恢复。

## 文件说明

| 文件 | 说明 |
|------|------|
| `OPENWRT_RADXA_CUBIE_A7Z.md` | 详细的移植指南和硬件验证步骤 |
| `.github/workflows/build-openwrt.yml` | GitHub Actions 自动构建配置 |
| `openwrt-sunxi-aiot/` | OpenWrt 源码和配置 |
| `allwinner-bsp/` | AllWinner 芯片 BSP 驱动 |

## 许可证

- OpenWrt: GPL-2.0
- AllWinner BSP: 各组件遵循对应许可证
- 本项目配置: MIT

## 贡献

欢迎提交 Issue 和 Pull Request。请在提交前阅读 [OPENWRT_RADXA_CUBIE_A7Z.md](./OPENWRT_RADXA_CUBIE_A7Z.md)。

## 参考资源

- [OpenWrt 官网](https://openwrt.org)
- [Radxa 官网](https://radxa.com)
- [AllWinner Linux](https://github.com/chainsx/openwrt-sunxi-aiot)

---

**最后更新**: 2026-11-18
**维护者**: kaiter
