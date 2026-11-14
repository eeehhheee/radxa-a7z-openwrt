# Linux 6.18 内核迁移到 Radxa A7Z 方案

## 当前发现
- **OpenWrt 25.12** 尚未支持 Allwinner 目标（target/linux/allwinner/ 不存在）
- **OpenWrt 24.10**（已有）包含完整的 Allwinner AIoT 支持
- **Linux 6.18 A733 补丁**已准备完毕：28 个补丁（496KB）在 `Temp/a733-patches/`

## 推荐方案
### 方案 A：在 OpenWrt 24.10 基础上升级内核到 6.18
**优点：**
- 保持 Allwinner AIoT 支持的完整性
- 只需升级内核版本（6.6 → 6.18）
- 复用现有的 device tree 和驱动框架
- 较低的集成风险

**步骤：**
1. 在 `openwrt-sunxi-aiot/target/linux/allwinner/` 中创建 `patches-6.18/` 目录
2. 复制 A733 补丁到 patches-6.18
3. 创建 `config-6.18` 配置文件（Radxa A7Z 专用）
4. 集成 PCIe 支持（U-Boot + 内核）
5. 更新 GitHub Actions 工作流

### 方案 B：等待 OpenWrt 25.12 Allwinner 支持成熟
**风险：**
- 时间成本不明确
- 仍需手动集成 A733 支持

## 关键补丁映射

| 类别 | 补丁文件 | 功能 |
|------|--------|------|
| 内核主补丁 | `0001-allwinner-a733-orangepi-4-pro-6.18-mainline.patch` (282KB) | A733 完整支持 |
| VPU | `0003-allwinner-a733-cedrus-vpu-support.patch` | Cedar 视频编解码 |
| PCIe (U-Boot) | `0100-uboot-sun60iw2-a733-pcie-nvme-boot-support.patch` | PCIe/NVME 启动 |
| PCIe (U-Boot Config) | `0002-configs-sun60iw2p1-a733-enable-pcie-nvme.patch` | PCIe 配置启用 |
| DisplayPort | `010x-dp-*.patch` (11个) | USB-C/eDP 支持 |
| 网络 | `0210-a733-orangepi-4-pro-rgmii-delay.patch` | RGMII 延迟调整 |

## 建议行动
**立即执行方案 A：**
1. 基于现有的 `openwrt-sunxi-aiot` 创建 6.18 内核配置
2. 集成 A733 补丁
3. 添加 Radxa A7Z 设备配置
4. 本地验证构建
5. 推送到 GitHub

**预期工作量：** 2-3 小时内可完成
**完成后：** 可自动构建 Linux 6.18 固件并上传到 GitHub Actions
