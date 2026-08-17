# YGOPro (Server)

[![GitHub Actions](https://github.com/mycard/ygopro/actions/workflows/server.yml/badge.svg?branch=server)](https://github.com/mycard/ygopro/actions/workflows/server.yml)

YGOPro 的一个服务端版本。程序启动后会自动建立主机并监听端口，供 YGOPro 客户端连接；现用于 [SRVPro](https://github.com/mycard/srvpro) 和[萌卡](https://mycard.world/)等项目。

## 获取开发版

Windows x64 开发版由 GitHub Actions 自动构建并发布到 [`server-latest`](https://github.com/mycard/ygopro/releases/tag/server-latest)。其中 `ygopro.exe` 为默认服务端程序，`AI.Server.exe` 为 YGOPro 2 人机模式专用。

## 编译

_依赖版本、下载地址及完整准备过程以 [`.github/workflows/server.yml`](https://github.com/mycard/ygopro/blob/server/.github/workflows/server.yml) 为准。_

使用 [Premake](https://premake.github.io/) 生成 Makefile 或 Visual Studio 解决方案后，即可使用对应的构建工具进行编译。

克隆源码时需要初始化 `ocgcore` 和 `script` 子模块：

```sh
git clone --branch server --recursive https://github.com/mycard/ygopro.git
cd ygopro
```

构建前，将各依赖源码解压到项目根目录下对应的固定目录，并复制项目提供的 Premake 文件：

```sh
cp -r premake/* .
cp -r resource/* .
```

默认服务端构建需要 Lua、libevent、SQLite 和 liblzma。启用 `--server-zip-support` 时还需要本项目使用的 Irrlicht 分支和 zlib。Lua 默认从源码以 C++ 方式构建，不能直接使用大多数包管理器提供的 C 版本 Lua。

### Linux

GitHub Actions 当前在 Ubuntu 22.04 和 24.04 上验证构建。动态链接构建需要 C/C++ 工具链、libevent、SQLite 和 liblzma 的开发包，以及放在 `lua/` 下的 Lua 源码：

```sh
sudo apt-get update
sudo apt-get install -y build-essential libevent-dev libsqlite3-dev liblzma-dev
premake5 gmake
make -C build -j4 config=release
```

产物位于 `bin/release/ygopro`。也可以使用 `--build-sqlite --build-event --build-lzma` 从源码静态构建这些依赖。

### Windows

GitHub Actions 当前使用 Visual Studio 2022。准备好依赖源码后，在 Developer Command Prompt 中复制 Premake 文件和 libevent 的 Windows 配置头，再生成解决方案：

```bat
xcopy /E /Y premake\* .
xcopy /E /Y resource\* .
copy /Y premake\event\msvc-event-config.h event\include\event2\event-config.h
copy /Y event\WIN32-Code\nmake\evconfig-private.h event\include\evconfig-private.h
premake5.exe vs2022
MSBuild.exe build\YGOPro.sln /m /p:Configuration=Release /p:Platform=x64
```

产物位于 `bin/release/x64/ygopro.exe`。需要 YGOPro 2 人机模式兼容支持时，可在生成解决方案时添加 `--server-pro2-support`。

### macOS

macOS 使用 Clang，准备 Lua 源码并安装 libevent、SQLite 和 liblzma 后，同样通过 `premake5 gmake` 和 `make -C build config=release` 构建。Premake 找不到 Homebrew 依赖时，可设置 `DYLD_LIBRARY_PATH="$(brew --prefix)/lib"`，或通过 `--*-include-dir`、`--*-lib-dir` 参数显式指定路径。macOS 当前未包含在 GitHub Actions 的服务端构建矩阵中。

## 运行

推荐使用 [SRVPro](https://github.com/mycard/srvpro) 管理服务端进程。

直接运行时也可以不传参数，以默认配置快速测试，程序在此时默认监听 7911 端口并将端口号输出到 `stdout`，可以使用 YGOPro 客户端连接。

**在 Windows 上直接运行 `ygopro.exe` 时，因程序被编译为窗口程序但不创建窗口，不会看到任何输出，也不会附加控制台。** 应通过其他方式读取 `stdout` 输出，例如使用 PowerShell：

```powershell
.\ygopro.exe 2>&1 | Out-Host
```

程序将持续运行，直到完成决斗，或最后一名玩家在开始决斗前退出。

运行的完整参数为：

```text
./ygopro <端口> <禁卡表编号> <卡片允许范围> <决斗模式> <大师规则> <不检查卡组> <不洗切卡组> <初始LP> <初始手牌> <每回合抽卡> <回合时间> <录像选项> [随机种子...]
```

示例：

```sh
./ygopro 0 0 0 1 F F F 8000 5 1 180 0
```

- 端口为 `0` 时由系统随机分配，程序会将实际端口输出到标准输出。
- 卡片允许范围：`0` 为 OCG，`1` 为 TCG，`2` 为简中，`3` 为仅DIY卡片，`4` 为不允许 OCG/TCG 独有卡，`5` 为全部允许。
- 决斗模式：`0` 为单局，`1` 为 BO3，`2` 为双打。
- 大师规则可输入规则编号；此外，`T` 表示默认规则的前一版，`F` 或 `0` 表示默认规则。
- “不检查卡组”和“不洗切卡组”使用 `T`/`F`。
- 录像选项按位组合：`0x1` 保存录像到 `./replay`，`0x2` 不向观战者发送录像，`0x4` 在录像中包含聊天记录。实际参数使用纯数字，不包括前缀 `0x`。
- 最多可追加 3 个 Base64 编码的随机种子，依次用于 BO3 中的各局决斗。
