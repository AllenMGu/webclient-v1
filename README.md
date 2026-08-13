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

Dockerfile 会校验重新生成的 Dart 主程序哈希为：

```text
dc012d2e7a91c43eb753aa982a8a78f1c02dd86ca9bcf9258091dc67bcaccb5f
```

这与仓库现有 V1 产物及 2023 年的参考镜像完全一致。该结论已在 Linux amd64
环境中从完整源码实际重建并通过逐字节比较，不是只依据版本号推测。构建基础
镜像、Flutter/Engine 提交、依赖锁文件和 `SOURCE_DATE_EPOCH` 均已固定；构建后
处理还会把 Flutter 随机生成的 Service Worker 版本改为内容哈希。CI 会执行两次
独立构建并比较输出树。

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
