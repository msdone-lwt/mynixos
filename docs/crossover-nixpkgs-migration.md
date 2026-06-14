# CrossOver - nixpkgs 迁移指南

## 当前状态

- ✅ Derivation 已完成并通过所有测试
- ✅ 代码格式符合 nixpkgs 标准
- ✅ 使用 finalAttrs 模式
- ✅ Meta 信息完整
- ✅ 桌面集成正常
- ✅ 用户配置文件安装测试通过

## Derivation 审查结果

### 符合 nixpkgs 规范的点

1. **许可证**: 正确使用 `lib.licenses.unfree` (FSL-1.1-MIT 许可证)
2. **finalAttrs 模式**: 正确使用，版本引用一致
3. **Meta 字段**: 完整且符合规范
   - description: ✓
   - homepage: ✓
   - changelog: ✓
   - license: ✓
   - maintainers: ✓
   - mainProgram: ✓
   - platforms: ✓
   - sourceProvenance: ✓
4. **无硬编码路径**: 所有路径使用 Nix 变量
5. **桌面集成**: 使用 copyDesktopItems 和 makeDesktopItem
6. **图标安装**: 遵循 FreeDesktop 标准

### 需要注意的点

1. **maintainer**: 需要在 nixpkgs 的 `maintainers-list.nix` 中添加你的信息：
   ```nix
   msdone = {
     name = "Your Name";
     email = "your-email@example.com";
     github = "msdone-lwt";
     githubId = your-github-id;
   };
   ```

2. **by-name 结构**: nixpkgs 现在使用 by-name 目录结构，包需要移到：
   `pkgs/by-name/cr/crossover/package.nix`

## 迁移步骤

### 1. 准备 nixpkgs fork

```bash
# 如果还没有 fork，访问 https://github.com/nixos/nixpkgs 并 fork

# 克隆你的 fork（如果还没有克隆）
cd ~/code
git clone git@github.com:msdone-lwt/nixpkgs.git
cd nixpkgs

# 添加上游仓库
git remote add upstream https://github.com/nixos/nixpkgs.git

# 更新到最新
git fetch upstream
git checkout master
git merge upstream/master
```

### 2. 创建 by-name 目录结构

```bash
cd ~/code/nixpkgs

# 创建目录
mkdir -p pkgs/by-name/cr/crossover

# 复制文件
cp ~/mynixos/pkgs/cross-over/default.nix pkgs/by-name/cr/crossover/package.nix
cp ~/mynixos/pkgs/cross-over/package-lock.json pkgs/by-name/cr/crossover/package-lock.json
```

### 3. 添加 maintainer 信息

编辑 `maintainers/maintainer-list.nix`:

```nix
msdone = {
  name = "Your Name";
  email = "your-email@example.com";
  github = "msdone-lwt";
  githubId = your-github-id;  # 从 https://api.github.com/users/msdone-lwt 获取
};
```

### 4. 测试构建

```bash
cd ~/code/nixpkgs

# 测试构建
nix-build -A crossover

# 测试安装
NIXPKGS_ALLOW_UNFREE=1 nix-env -f . -iA crossover

# 测试运行
crossover --version  # 或直接运行 crossover

# 清理
nix-env -e crossover
```

### 5. 创建提交和分支

```bash
cd ~/code/nixpkgs

# 创建新分支
git checkout -b crossover-init

# 添加更改
git add pkgs/by-name/cr/crossover/
git add maintainers/maintainer-list.nix  # 如果添加了 maintainer

# 提交（注意：不要添加 Co-Authored-By）
git commit -m "crossover: init at 3.4.2

CrossOver is a crosshair overlay application for gaming and screen work.
It provides customizable crosshairs that overlay on any application.

The application is built using Electron and distributed under FSL-1.1-MIT
license, which is unfree."
```

### 6. 推送并创建 PR

```bash
# 推送到你的 fork
git push -u origin crossover-init

# 使用 gh CLI 创建 PR
gh pr create --repo nixos/nixpkgs \
  --title "crossover: init at 3.4.2" \
  --body "## Description

Adds CrossOver, a crosshair overlay application for gaming and screen work.

**Package details:**
- Version: 3.4.2
- License: FSL-1.1-MIT (unfree)
- Platforms: x86_64-linux
- Uses: Electron + Node.js

**Features:**
- Customizable crosshairs
- Overlay on any application
- Desktop integration
- Wayland support

**Testing:**
- [x] Built successfully with \`nix-build -A crossover\`
- [x] Installed with \`nix-env -f . -iA crossover\`
- [x] Application launches and runs correctly
- [x] Desktop file appears in application menu
- [x] Icons installed correctly

## Checklist

- [x] Package builds on x86_64-linux
- [x] Added package to pkgs/by-name/cr/crossover/
- [x] Follows nixpkgs packaging guidelines
- [x] Uses finalAttrs pattern
- [x] Meta information complete
- [x] Desktop integration working
- [x] Auto-update disabled (patched out)

Fixes: (leave blank if not applicable)"
```

## PR 标题和描述指南

### PR 标题格式
```
crossover: init at 3.4.2
```

格式：`<package-name>: <action> [at <version>]`

常见 actions:
- `init`: 新包
- `update`: 版本更新
- `fix`: 修复问题
- `refactor`: 重构

### PR 描述要点

1. **简要说明**: 包是什么，做什么用
2. **技术细节**: 许可证、平台、依赖
3. **测试结果**: 构建、安装、运行测试
4. **Checklist**: nixpkgs PR 模板要求的检查项

## nixpkgs 维护者可能的反馈

准备好回答这些常见问题：

1. **许可证**: FSL-1.1-MIT 是 unfree 许可证，确保你已标记为 unfree
2. **构建确定性**: electron-builder 可能有非确定性问题
3. **依赖版本**: 确保使用固定的 npm 依赖（已通过 fetchNpmDeps 处理）
4. **自动更新**: 已禁用（通过 postPatch 补丁）
5. **平台支持**: 当前仅 x86_64-linux，是否支持其他平台？

## 后续维护

一旦 PR 合并：

1. **更新检查**: 定期检查上游更新
2. **问题跟踪**: 关注 nixpkgs issues 中关于 crossover 的报告
3. **版本更新**: 使用标准的 nixpkgs 更新流程
4. **与上游协作**: 如有构建问题，考虑向上游报告

## 有用的命令

```bash
# 检查包元数据
nix eval .#crossover.meta --json | jq

# 检查包大小
nix path-info -S .#crossover

# 检查依赖
nix-store -q --tree $(nix-build -A crossover --no-out-link)

# 运行 nixpkgs-review（可选，需要安装 nixpkgs-review）
nixpkgs-review pr --post-result <PR-number>
```

## 参考资源

- [Nixpkgs Manual - Adding Packages](https://nixos.org/manual/nixpkgs/stable/#chap-quick-start)
- [by-name Structure](https://github.com/nixos/nixpkgs/blob/master/pkgs/by-name/README.md)
- [Nixpkgs Contributing Guide](https://github.com/nixos/nixpkgs/blob/master/CONTRIBUTING.md)
- [Electron Packaging in nixpkgs](https://nixos.org/manual/nixpkgs/stable/#electron)

## 联系方式

如果需要帮助：
- nixpkgs Matrix: #nixpkgs:nixos.org
- nixpkgs Discourse: https://discourse.nixos.org/c/dev/nixpkgs/

---

**注意**: 这是从本地 NixOS 配置迁移到 nixpkgs 的指南。当前的包定义已经完全可用，
你可以继续在本地使用它，同时准备提交到 nixpkgs。
