# Radxa Cubie-A7Z OpenWrt Porting Project

这是针对 Radxa Cubie-A7Z 开发板的 OpenWrt 完整移植项目，包含自动化构建流水线。

## 项目概述

- **目标设备**: Radxa Cubie-A7Z (Allwinner A733 SoC)
- **OpenWrt 版本**: openwrt-24.10 (基于 openwrt-sunxi-aiot)
- **内核版本**: Linux 6.6
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
cd openwrt-sunxi-aiot

# 更新 feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 配置构建
make menuconfig
# 选择: Target System → Allwinner AIoT
# 选择: Target Profile → Radxa Cubie-A7Z

# 编译启动包
make package/boot/uboot-allwinner/compile V=s

# 编译完整固件
make -j$(nproc) V=s
```

编译输出在 `bin/targets/allwinner/aiot/` 目录下。

### 支持的启动介质

项目支持三种启动方式：

- **SD Card** (`boot0_sdcard.bin`)
- **SPI NOR Flash** (`boot0_spinor.bin`)
- **UFS** (`boot0_ufs.bin`)

启动文件位置: `openwrt-sunxi-aiot/package/boot/uboot-allwinner/files/radxa-cubie-a7z/`

## 硬件支持

### 已验证功能

- ✅ 启动 (SD/eMMC/SPI NOR/UFS)
- ✅ 网络接口
- ✅ USB 接口
- ✅ PCIe
- ✅ SD 卡扩展
- ✅ GPIO/LED
- 🔲 待验证其他功能

### 已知问题

- 详见 [OPENWRT_RADXA_CUBIE_A7Z.md](./OPENWRT_RADXA_CUBIE_A7Z.md) 第 5-6 节

## 构建流水线

### GitHub Actions

此仓库已配置自动构建流水线:

- **触发方式**: 
  - Push 到 `main` 或 `develop` 分支
  - Pull Request 到 `main` 分支
  - 手动触发 (workflow_dispatch)

- **产物**: 
  - 固件镜像 (artifacts: `openwrt-firmware-a7z`)
  - 构建日志 (失败时保留 7 天)

- **环境**: Ubuntu latest + 所有必需的 OpenWrt 构建依赖

查看构建历史: [Actions 标签](../../actions)

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

**最后更新**: 2026-11-14
**维护者**: kaiter
