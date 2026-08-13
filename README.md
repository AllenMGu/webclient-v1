# RustDesk Web Client V1：完整对应源码与构建

本仓库是 `AllenMGu/rustdesk-api` 所使用的 Web Client V1 独立源码仓库，
并以 Git 子模块固定到 API 仓库。它不是只有编译后的 `main.dart.js`，而是包含
Web Client V1 的完整 RustDesk 源码快照、许可证、版权声明、来源取证记录、
集成修改源码，以及固定工具链的构建入口。

## 固定版本

- RustDesk 源码：[`JelleBuning/rustdesk@47a7b7313bb906ebdae36bd16838bdefa8853639`](https://github.com/JelleBuning/rustdesk/commit/47a7b7313bb906ebdae36bd16838bdefa8853639)
- 源码日期：2023-04-26 13:44:52 +02:00
- 完整源码包：[`rustdesk-source-47a7b7313bb906ebdae36bd16838bdefa8853639.tar`](rustdesk-source-47a7b7313bb906ebdae36bd16838bdefa8853639.tar)
- 许可证：[`LICENCE`](LICENCE)，GNU AGPL v3
- Flutter：`3.7.12`，官方提交
  `4d9e56e694b656610ab87fcf2efbcd226e0ed8cf`
- Flutter Engine：`1a65d409c7a1438a34d21b60bf30a6fd5db59314`
- Dart：`2.19.6`
- Node 构建基础：`node:16.20.2-bullseye-slim`，按 amd64 manifest digest 固定
- JS 依赖：`resources/web/js/yarn.lock`
- Dart/Flutter 依赖：完整源码包中的 `flutter/pubspec.lock`

上述 tar 包是该提交的规范 `git archive`，内含完整 478 个文件，
不是从产物反编译或只抽取 `flutter/lib` 得到的残缺源码。之所以使用
完整归档，是为了避免上游多层 `.gitignore` 在再提交时漏掉 57 个图标与资源文件。
可随时运行 `./extract-source.sh` 展开为可浏览的 `source/`。

本项目对 Web Client 的 API、分享链接和
WebSocket 适配源码保留在
[`integration/resources-web-js/`](integration/resources-web-js/)，并由校验脚本
保证它与运行时的 `resources/web/js/` 一致；构建时会覆盖到上游快照的对应 JS
目录后重新编译。

## 1.4.9 风格界面更新

当前版本在不更换 V1 连接协议、WebSocket 桥接和 API 集成的前提下，参考
RustDesk `1.4.9` 客户端的 Flutter 视觉语言更新了 Web 界面，包括：

- 更紧凑的品牌顶栏和账户/服务器菜单；
- 现代化远程 ID 连接卡片，支持回车连接和窄屏响应式排列；
- 参考 Web Client V2 的最近连接、收藏、API 地址簿和账号设备四个分类；
- 按 ID、别名、主机名、用户名、平台和标签搜索；
- 批量收藏/取消收藏、清理最近连接，以及网格/列表视图切换；
- 地址簿别名、标签、设备在线状态和最后在线时间；
- 与现行客户端一致的蓝色强调色、灰色工作区、圆角、边框和控件层级。

浏览器无法使用桌面客户端的 UDP 局域网发现协议，因此“设备”分类读取 API 中当前
账号已登记的设备，并显示服务器心跳产生的在线状态；不会用不可靠的浏览器扫描来
冒充局域网发现。收藏和视图偏好保存在浏览器本地，地址簿与设备数据由登录后的 API
自动同步。

界面修改的完整 Dart 源码位于
[`overrides/flutter/`](overrides/flutter/)。Dockerfile 先展开固定的原始 V1
完整源码，再应用该公开覆盖层并从 Dart 源码编译。因此，上游原始快照保持不变，
修改内容又能被逐文件审阅、重建和再分发。视觉参考版本固定为
[`rustdesk/rustdesk@6c578292e8ebbbec708b76986ba8c4bc7c509747`](https://github.com/rustdesk/rustdesk/tree/6c578292e8ebbbec708b76986ba8c4bc7c509747)；
这不是把 1.4.9 尚未完整支持 Web 的传输核心混入 V1。

更完整的证据链和哈希见 [`PROVENANCE.md`](PROVENANCE.md)。

## 可复现构建

要求：Linux amd64，以及 Docker BuildKit 或 Podman/Buildah。构建不读取现有
`resources/web/main.dart.js`；Dockerfile 会删除任何预编译的 JS `dist/`，再从
Dart 和 TypeScript 源码重新生成产物。

在本仓库根目录运行：

```bash
./verify-source.sh
./build.sh /tmp/rustdesk-webclient-v1
```

也可以直接运行：

```bash
docker build --platform linux/amd64 \
  --file Dockerfile \
  --output type=local,dest=/tmp/rustdesk-webclient-v1 \
  .
```

输出目录包含：

- 从源码生成的 `main.dart.js` 和 `js/dist/`；
- `SOURCE.html`、AGPL 许可证及版权说明；
- `corresponding-source/`，即随产物提供的完整对应源码与构建材料。

原始 V1 基线的 `main.dart.js` 哈希与 2023 年参考镜像逐字节一致，来源取证见
`PROVENANCE.md`。当前产物包含公开的界面修改，因此主程序哈希会与原始基线不同。
更新后从完整源码生成的 `main.dart.js` SHA-256 固定为：

```text
82dcac8f2d4c36327c9d56a0fef492f4e4db92d1960277318014e5b7f06fda85
```

构建基础镜像、Flutter/Engine 提交、依赖锁文件和 `SOURCE_DATE_EPOCH` 均已固定；
构建后处理还会把 Flutter 随机生成的 Service Worker 版本改为内容哈希。CI 会执行
两次独立构建并逐字节比较完整输出树，以验证修改后的产物仍然可复现。

## 在 rustdesk-api 中使用

API 仓库通过 `webclient-v1` Git 子模块固定本仓库的精确提交。克隆或更新 API
仓库时必须初始化子模块：

```bash
git clone --recurse-submodules https://github.com/AllenMGu/rustdesk-api.git
cd rustdesk-api
git submodule update --init --recursive
```

API 的发布工作流会把该固定提交的完整内容复制进发行包、Debian 包和容器镜像；
运行时还通过 `/webclient-source/` 提供对应源码与构建材料。

## 许可证边界

`AllenMGu/rustdesk-api` 根目录的 MIT 许可证不覆盖本仓库、API 仓库中的
`resources/web/` 或其衍生构建。Web Client 及本项目对它的修改依照 GNU AGPL
v3 提供。所有上游版权声明和第三方许可证文件均原样保留在完整源码包中；
不得在再分发时删除。
