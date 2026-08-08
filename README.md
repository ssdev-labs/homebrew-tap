# Homebrew Tap

用于发布 `yahuo` 软件包的公开 Homebrew cask 和发行文件。

## 安装

### macOS

```sh
brew install --cask yahuo/tap/ssdev-cairn
```

使用完整的 cask 名称会自动添加此 tap，并且只信任指定的软件包。

### Windows

先安装 Git for Windows，然后在 PowerShell 中运行以下命令：

```powershell
irm https://raw.githubusercontent.com/yahuo/homebrew-tap/master/install.ps1 | iex
```

公开安装脚本会锁定至最新发布的 ssdev-cairn 版本，使用 `checksums.txt` 校验所选的 Windows 压缩包，并以幂等方式更新用户的 `PATH`。

## 卸载

### Project 卸载

只停用当前 Git 项目，保留全局 Agent 集成和 `git-cairn` 二进制：

```sh
git cairn uninit .
```

也可以指定项目路径：

```sh
git cairn uninit /path/to/repository
```

### 全局卸载

清理所有已登记项目和全局 Agent 集成，但保留 `git-cairn` 二进制：

```sh
git cairn uninstall --all
```

### macOS 完整卸载

通过 Homebrew 安装时，使用 `--zap` 清理全部集成并删除二进制：

```sh
brew uninstall --cask --zap ssdev-cairn
```

普通的 `brew uninstall --cask ssdev-cairn` 只删除二进制，不会清理已登记项目和全局 Agent 集成。

### Windows 完整卸载

使用公开安装脚本的 `-Uninstall` 参数：

```powershell
$installer = irm https://raw.githubusercontent.com/yahuo/homebrew-tap/master/install.ps1
& ([ScriptBlock]::Create($installer)) -Uninstall
```

脚本会先执行全局集成清理，再删除安装目录和用户 `PATH` 中对应的安装项。

## 软件包

| 软件包 | 说明 |
| --- | --- |
| `ssdev-cairn` | 为 Git 提交信息添加本地 AI 编程上下文。 |

发行标签带有产品前缀，因此该仓库可以分发多个独立版本管理的软件包。每个可下载的压缩包都在对应发行版本的 `checksums.txt` 中有一条记录。
