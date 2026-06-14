# CrossOver Nix Derivation 设计文档

**日期**: 2026-06-14  
**项目**: CrossOver 准星叠加工具  
**目标**: 为 CrossOver 编写符合 nixpkgs 规范的 derivation，用于提交到 nixpkgs

## 项目概述

CrossOver 是一个基于 Electron 的跨平台准星叠加工具，可以在任何应用程序窗口上方显示可自定义的准星叠加层。项目由 Lacy Morrow 开发，托管在 GitHub (lacymorrow/crossover)。

- **当前版本**: 3.4.2
- **上游 Electron 版本**: ^14.0.0
- **构建系统**: npm + electron-builder
- **许可证**: MIT (待验证)
- **类别**: 游戏工具/实用程序

## 设计决策

### 1. 包结构和位置

**决策**: 使用 nixpkgs 新的 `by-name` 结构

**位置**: `pkgs/cross-over/default.nix` (本地测试) → `pkgs/by-name/cr/crossover/package.nix` (提交到 nixpkgs)

**理由**:
- `by-name` 是 nixpkgs 当前推荐的组织方式
- 更容易维护和查找
- 不需要在 `all-packages.nix` 中手动注册

### 2. 打包方案

**决策**: 从源码构建 (方案 A)

使用以下技术栈：
- `fetchFromGitHub` - 获取源代码
- `fetchNpmDeps` - 锁定 npm 依赖
- `npmHooks.npmConfigHook` - 自动配置 npm 环境
- `electron-builder --dir` - 构建应用

**理由**:
- 完全透明，符合开源精神
- 与 nixpkgs 中其他 Electron 应用一致 (whatsapp-electron)
- npm 支持在 nixpkgs 中最成熟
- 依赖锁定更可靠

**备选方案 (已拒绝)**:
- 方案 B (pnpm): crossover 主要使用 npm，不需要增加复杂度
- 方案 C (bun): nixpkgs 中 bun 支持不够成熟
- 预编译二进制: 不够透明，不符合从源码构建的原则

### 3. 依赖管理

**Electron 版本选择**:
- 上游要求: `^14.0.0`
- nixpkgs 选择: 使用 `electron_14` 或更新的稳定版本
- 通过 `ELECTRON_SKIP_BINARY_DOWNLOAD=1` 避免下载预编译二进制

**npm 依赖**:
- 使用 `fetchNpmDeps` 锁定所有依赖
- hash 需要通过实际构建获取
- 依赖项包括: electron-debug, electron-util, uiohook-napi 等

### 4. 构建流程

**nativeBuildInputs**:
- `makeWrapper` - 创建可执行文件 wrapper
- `nodejs` - npm 构建环境
- `npmHooks.npmConfigHook` - npm 配置
- `copyDesktopItems` - 桌面文件集成 (Linux)

**环境变量**:
```nix
env.ELECTRON_SKIP_BINARY_DOWNLOAD = 1;
```

**构建命令**:
```bash
npm install  # 由 npmConfigHook 处理
electron-builder --dir \
  -c.electronDist=${electron.dist} \
  -c.electronVersion=${electron.version}
```

**可能需要的 patches**:
1. 禁用自动更新检查
2. 修复 Git 相关构建脚本（如果有）
3. 禁用代码签名验证

### 5. 安装阶段

**文件组织**:
```
$out/
├── bin/
│   └── crossover              # wrapper 脚本
├── share/
│   ├── crossover/
│   │   ├── resources/
│   │   │   └── app.asar      # 主应用
│   │   ├── locales/           # 本地化文件
│   │   └── resources.pak      # 资源包
│   ├── applications/
│   │   └── crossover.desktop
│   └── icons/
│       └── hicolor/
│           └── */apps/crossover.png
```

**安装步骤**:
1. 从 `dist/*-unpacked/` 复制构建产物
2. 删除 `app-update.yml` (禁用自动更新)
3. 提取并安装图标文件
4. 创建 wrapper 脚本

### 6. 可执行文件 Wrapper

使用 `makeWrapper` 创建启动脚本：

```bash
makeWrapper ${electron}/bin/electron $out/bin/crossover \
  --add-flags $out/share/crossover/resources/app.asar \
  --add-flags "${NIXOS_OZONE_WL:+${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}" \
  --set-default ELECTRON_FORCE_IS_PACKAGED 1 \
  --set-default ELECTRON_IS_DEV 0 \
  --inherit-argv0
```

**功能**:
- 调用 nixpkgs electron + app.asar
- Wayland 支持 (通过 NIXOS_OZONE_WL 环境变量)
- 设置正确的 Electron 环境变量

### 7. 桌面集成

**Desktop Entry**:
- Name: CrossOver
- Categories: `Game`, `Utility`
- Icon: crossover
- Exec: crossover %u
- StartupWMClass: crossover

**图标安装**:
- 从源码提取图标 (通常在 `assets/` 或 `resources/icons/`)
- 安装到 `$out/share/icons/hicolor/*/apps/`
- 支持多种分辨率 (256x256, 512x512 等)

### 8. Meta 信息

```nix
meta = {
  description = "Crosshair overlay for any screen";
  homepage = "https://github.com/lacymorrow/crossover";
  changelog = "https://github.com/lacymorrow/crossover/releases/tag/v${version}";
  license = lib.licenses.mit;  # 需验证
  maintainers = with lib.maintainers; [ msdone ];
  mainProgram = "crossover";
  platforms = [ "x86_64-linux" ];
  sourceProvenance = with lib.sourceTypes; [ fromSource ];
};
```

## 实现计划

实现将分为以下步骤：

1. **编写基础 derivation** - 定义包结构和依赖
2. **本地构建测试** - 使用 `nix-build` 或 `nix build` 测试
3. **处理构建错误** - 根据错误日志添加 patches 和修复
4. **验证运行时行为** - 测试应用是否正常启动和运行
5. **代码规范检查** - 确保符合 nixpkgs 代码规范
6. **准备提交** - 用户将代码迁移到 nixpkgs fork 并提交 PR

## 验证标准

构建成功的标准：
- ✅ `nix-build` 或 `nix build` 无错误完成
- ✅ 可执行文件 `crossover` 存在且可执行
- ✅ 应用能正常启动（不崩溃）
- ✅ 图标和桌面文件正确安装
- ✅ 符合 nixpkgs 代码规范（通过 `nixpkgs-fmt` 检查）

运行时验证：
- ✅ 准星叠加层正常显示
- ✅ 可以自定义准星样式
- ✅ 在 Wayland 和 X11 下都能工作

## 潜在问题和解决方案

### 问题 1: 缺少 package-lock.json
**症状**: fetchNpmDeps 失败
**解决**: 在本地生成 package-lock.json 并建议上游添加

### 问题 2: electron-builder 构建失败
**症状**: 找不到 electron 或构建配置错误
**解决**: 添加 patch 修改 electron-builder 配置

### 问题 3: 运行时依赖缺失
**症状**: 应用启动失败或功能异常
**解决**: 使用 `autoPatchelfHook` 或添加缺失的库到 `buildInputs`

### 问题 4: Wayland 支持问题
**症状**: 在 Wayland 下窗口显示异常
**解决**: 添加正确的 Wayland flags 和环境变量

### 问题 5: uiohook-napi 原生模块
**症状**: 原生模块加载失败
**解决**: 可能需要额外的构建依赖或 patchelf

## 参考资料

- CrossOver GitHub: https://github.com/lacymorrow/crossover
- nixpkgs Electron 应用示例: whatsapp-electron, any-listen
- nixpkgs 贡献指南: ~/code/nixpkgs/CONTRIBUTING.md
- nixpkgs by-name 结构: https://github.com/NixOS/nixpkgs/tree/master/pkgs/by-name
