# CrossOver nixpkgs 提交检查清单

## 当前状态：准备就绪 ✅

所有开发和测试已完成，包可以提交到 nixpkgs。

## 提交前检查清单

### 1. Derivation 质量检查 ✅

- [x] 使用 finalAttrs 模式
- [x] 许可证正确标记为 unfree
- [x] Meta 信息完整（description, homepage, changelog, license, maintainers, mainProgram, platforms, sourceProvenance）
- [x] 无硬编码路径
- [x] 构建成功
- [x] 运行时测试通过
- [x] 桌面集成正常（desktop file, icons）
- [x] 代码格式符合 nixpkgs 标准

### 2. nixpkgs 仓库准备

- [ ] Fork nixpkgs 仓库（如果还没有）
  - URL: https://github.com/nixos/nixpkgs
  - Fork 到: https://github.com/msdone-lwt/nixpkgs

- [ ] 克隆并更新 fork
  ```bash
  cd ~/code
  git clone git@github.com:msdone-lwt/nixpkgs.git
  cd nixpkgs
  git remote add upstream https://github.com/nixos/nixpkgs.git
  git fetch upstream
  git checkout master
  git merge upstream/master
  ```

### 3. 添加 maintainer 信息

- [ ] 获取你的 GitHub ID
  ```bash
  curl https://api.github.com/users/msdone-lwt | jq .id
  ```

- [ ] 编辑 `maintainers/maintainer-list.nix`，添加：
  ```nix
  msdone = {
    name = "Your Name";
    email = "your-email@example.com";
    github = "msdone-lwt";
    githubId = YOUR_GITHUB_ID;
  };
  ```

### 4. 创建 by-name 目录结构

- [ ] 创建目录并复制文件
  ```bash
  cd ~/code/nixpkgs
  mkdir -p pkgs/by-name/cr/crossover
  cp ~/mynixos/pkgs/cross-over/default.nix pkgs/by-name/cr/crossover/package.nix
  cp ~/mynixos/pkgs/cross-over/package-lock.json pkgs/by-name/cr/crossover/package-lock.json
  ```

### 5. 在 nixpkgs 中测试

- [ ] 构建测试
  ```bash
  cd ~/code/nixpkgs
  nix-build -A crossover
  ```

- [ ] 安装测试
  ```bash
  NIXPKGS_ALLOW_UNFREE=1 nix-env -f . -iA crossover
  ```

- [ ] 运行测试
  ```bash
  crossover  # 启动应用，验证正常工作
  ```

- [ ] 清理
  ```bash
  nix-env -e crossover
  rm result
  ```

### 6. 创建 Git 提交

- [ ] 创建分支
  ```bash
  git checkout -b crossover-init
  ```

- [ ] 添加文件
  ```bash
  git add pkgs/by-name/cr/crossover/
  git add maintainers/maintainer-list.nix  # 如果添加了 maintainer
  ```

- [ ] 提交（不要添加 Co-Authored-By）
  ```bash
  git commit -m "crossover: init at 3.4.2

  CrossOver is a crosshair overlay application for gaming and screen work.
  It provides customizable crosshairs that overlay on any application.

  The application is built using Electron and distributed under FSL-1.1-MIT
  license, which is unfree."
  ```

### 7. 创建 Pull Request

- [ ] 推送分支
  ```bash
  git push -u origin crossover-init
  ```

- [ ] 使用 gh CLI 创建 PR（或通过 GitHub web 界面）
  ```bash
  gh pr create --repo nixos/nixpkgs \
    --title "crossover: init at 3.4.2" \
    --body-file ~/mynixos/docs/pr-description.txt
  ```

### 8. PR 描述要点

PR 描述应包含：

```markdown
## Description

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
- [x] Built successfully with `nix-build -A crossover`
- [x] Installed with `nix-env -f . -iA crossover`
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
```

## 预期的审查反馈

准备好回答：

1. **为什么是 unfree？** - FSL-1.1-MIT 许可证限制商业使用
2. **是否支持其他平台？** - 当前仅 x86_64-linux 测试通过
3. **自动更新如何处理？** - 已在 postPatch 中禁用
4. **构建是否确定性？** - 使用 fetchNpmDeps 固定依赖

## 文件位置参考

- 源文件: `/home/msdone/mynixos/pkgs/cross-over/default.nix`
- 目标位置: `pkgs/by-name/cr/crossover/package.nix` (在 nixpkgs 中)
- 完整迁移指南: `/home/msdone/mynixos/docs/crossover-nixpkgs-migration.md`

## 有用的命令

```bash
# 检查包元数据
nix eval .#crossover.meta --json | jq

# 检查构建日志
nix log .#crossover

# 检查运行时依赖
nix-store -q --references $(nix-build -A crossover --no-out-link)

# 检查包大小
nix path-info -S .#crossover
```

## 完成标准

- [ ] PR 已创建
- [ ] CI 检查通过
- [ ] 至少一个 maintainer approve
- [ ] 合并到 master

---

**准备好了吗？** 按照上面的步骤，你可以开始提交过程。如有问题，参考完整的迁移指南。
