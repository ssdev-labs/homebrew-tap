# Homebrew Tap

用于发布 `ssdev-labs` 软件包的公开 Homebrew cask 和发行文件。

## SSDEV 临时协助

### macOS

```sh
brew install --cask ssdev-labs/tap/ssdev-wecanfixeverything
```

使用完整的 cask 名称会自动添加此 tap，并且只信任指定的软件包。

当前 macOS 包使用临时签名。如果首次启动被 Gatekeeper 阻止，只移除这个 App 的隔离标记后再打开：

```sh
sudo /usr/bin/xattr -dr com.apple.quarantine "/Applications/WeCanFixEverything.app"
open "/Applications/WeCanFixEverything.app"
```

不要全局关闭 Gatekeeper。Homebrew 会在安装前按 Cask 中固定的 SHA-256 校验下载文件。

升级和卸载：

```sh
brew upgrade --cask ssdev-wecanfixeverything
brew uninstall --cask ssdev-wecanfixeverything
```

### Windows

在 Windows 10/11 x64 的 PowerShell 中运行：

```powershell
irm https://raw.githubusercontent.com/ssdev-labs/homebrew-tap/master/installers/ssdev-wecanfixeverything.ps1 | iex
```

脚本固定到已发布版本，校验安装器 SHA-256 后静默安装到
`C:\Program Files\WeCanFixEverything`。安装器需要管理员权限，Windows 可能显示 UAC 或 SmartScreen 提示；重复运行同一命令即可升级。

卸载：

```powershell
$installer = irm https://raw.githubusercontent.com/ssdev-labs/homebrew-tap/master/installers/ssdev-wecanfixeverything.ps1
& ([ScriptBlock]::Create($installer)) -Uninstall
```

## ssdev-cairn

### macOS

```sh
brew install --cask ssdev-labs/tap/ssdev-cairn
```

使用完整的 cask 名称会自动添加此 tap，并且只信任指定的软件包。

### Linux

先安装 Git、`curl`、`tar` 和 `sha256sum`，然后运行：

```sh
curl -fsSL https://raw.githubusercontent.com/ssdev-labs/homebrew-tap/master/install.sh | sh
```

公开安装脚本会锁定至最新发布的 ssdev-cairn 版本，识别 amd64/arm64，使用
`checksums.txt` 校验 Linux 压缩包，并幂等安装到 `~/.local/bin`。如果该目录尚未
加入 `PATH`，脚本会输出需要执行的命令。重新运行同一条命令即可升级。

### Windows

先安装 Git for Windows，然后在 PowerShell 中运行以下命令：

```powershell
irm https://raw.githubusercontent.com/ssdev-labs/homebrew-tap/master/install.ps1 | iex
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

### Linux 完整卸载

先清理全部集成，再删除安装器写入的二进制：

```sh
git cairn uninstall --all
rm "$HOME/.local/bin/git-cairn"
```

### Windows 完整卸载

使用公开安装脚本的 `-Uninstall` 参数：

```powershell
$installer = irm https://raw.githubusercontent.com/ssdev-labs/homebrew-tap/master/install.ps1
& ([ScriptBlock]::Create($installer)) -Uninstall
```

脚本会先执行全局集成清理，再删除安装目录和用户 `PATH` 中对应的安装项。

## 软件包

| 软件包 | 说明 |
| --- | --- |
| `ssdev-wecanfixeverything` | 临时、定向、自动过期的远程排查通道。 |
| `ssdev-cairn` | 为 Git 提交信息添加本地 AI 编程上下文。 |

发行标签带有产品前缀，因此该仓库可以分发多个独立版本管理的软件包。每个可下载的分发物都在对应发行版本的校验文件中有一条记录。
