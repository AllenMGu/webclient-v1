# Web Client V1 来源取证记录

## 结论

现有 `resources/web/main.dart.js` 对应的 RustDesk V1 源码提交是：

```text
repository: https://github.com/JelleBuning/rustdesk.git
commit:     47a7b7313bb906ebdae36bd16838bdefa8853639
parent:     6069de9eb374a9f277c8fdb55c554c8eb53bd8f2
author:     Jelle Buning <jellebuning@outlook.com>
date:       2023-04-26T13:44:52+02:00
subject:    changed server back to default
```

该分支正是 RustDesk 当时的 Web 构建文档所指向的 `fix_build` 分支，而不是后来的
其他 Web 实现。

## 交叉验证

1. 2023-04-28 创建的参考镜像
   `keyurbhole/flutter_web_desk@sha256:0cadd567865d3550632515c0ab39ae6fe341079fc9d0c6c87a2d107358e34f5f`
   内含该提交的 Flutter 源码。
2. 镜像层中的 `flutter/web/js/src/connection.ts` 与本目录上游快照的文件哈希均为
   `a6f23c4c16d3a044712fef82eb08306873edd45e88d7d79690a6f539260abdd7`。
3. 镜像构建产物与 API 仓库导入的 V1 产物的以下 SHA-256
   完全一致：

   | 文件 | SHA-256 |
   |---|---|
   | `main.dart.js` | `dc012d2e7a91c43eb753aa982a8a78f1c02dd86ca9bcf9258091dc67bcaccb5f` |
   | `flutter_service_worker.js`（增加源码公开文件前） | `70f3413e7712cb778d292e0ece5b2e1aa52404b0802e653f40101fe7cbd429fd` |
   | `js/dist/vendor.js` | `bf769604079186d86e2f8f854da1642ae53fc7cdc7c9af91fdafab52ec8f42e5` |
   | `version.json` | `cb55e739e6f7455d2d9c240973478387d2c5d475eef6a7cf81211132ca9d4714` |

4. `version.json` 声明应用版本 `1.1.10-1`、构建号 `28`，与固定源码中的
   `flutter/pubspec.yaml` 一致。
5. `main.dart.js` 在 API 仓库提交
   `497a24ebd9098f0ec0efd0033e57eeb78cd22d51`（2024-09-13）首次导入，此后没有
   被替换。后续 API 集成只改动并重编译了 `resources/web/js/` 部分；其修改源码
   仍随仓库提供。

初次合规整理只向 `index.html` 和 Service Worker 增加了显著源码入口、
AGPL 文本、NOTICE 及对应缓存清单，当时没有替换 Dart 主程序。该基线的关键哈希为：

| 文件 | SHA-256 |
|---|---|
| `resources/web/main.dart.js` | `dc012d2e7a91c43eb753aa982a8a78f1c02dd86ca9bcf9258091dc67bcaccb5f` |
| `resources/web/js/dist/index.js` | `ce0fb61391e59833b16d80f0cef8cdfa90a7409f41f551afe3b57983595ce800` |
| `resources/web/js/dist/vendor.js` | `bf769604079186d86e2f8f854da1642ae53fc7cdc7c9af91fdafab52ec8f42e5` |
| `resources/web/AGPL-3.0.txt` | `8486a10c4393cee1c25392769ddd3b2d6c242d6ec7928e1414efff7dfb2f07ef` |

使用 Node 16.20.2、Yarn 1.22.19 与随附 Linux 锁文件重建
`integration/resources-web-js/` 后，`index.js` 和 `vendor.js` 均与上表按字节一致。

## 界面更新来源与边界

后续界面更新参考 RustDesk 官方 `1.4.9` 标签对应提交
`6c578292e8ebbbec708b76986ba8c4bc7c509747` 的 Flutter 主题、间距、卡片和工具栏
视觉语言。所有实际修改均以完整 Dart 源码保存在 `overrides/flutter/`，并在构建时
覆盖固定 V1 快照中的同名文件。

该更新只改变 Web 界面与主题，不替换 V1 的连接协议、TypeScript WebSocket 桥接、
远控会话实现或 API 登录/地址簿集成。RustDesk 1.4.9 的官方 Web 构建仍标记为预览，
其标签源码也不包含本项目 V1 所依赖的完整 `flutter/web/js` 桥接树，因此没有声称
当前产物是 1.4.9 核心的 Web 构建。当前产物哈希必须以修改后两次独立源码构建的
逐字节一致结果为准，而不能继续使用上表的原始 V1 基线哈希。Linux amd64 上两次
独立构建所得 `main.dart.js` SHA-256 均为：

```text
d92ca6461822b1d0013c4af9024e994f56914e2b8303b6555a5f9041138e971c
```

上游提交的规范 `git archive`（无路径前缀）SHA-256 为：

```text
f943ce011eb2f8dc3056326cfb265e4bcf3721daea5512e4b57181ffd46f3950
```

`verify-source.sh` 会从固定提交重新生成归档，同时核对 SHA-256
和字节内容，防止供应的完整源码包与声明提交不一致。

## 工具链取证

参考镜像中的 `app/.flutter-plugins-dependencies` 是 Flutter 在项目依赖解析时生成的
文件。它记录了 `date_created: 2023-04-28 17:31:23.304811` 和实际项目工具版本
`3.7.12`，文件 SHA-256 为：

```text
a58beebab9f136b926f542256b9a33131b6e22e92d5929ae633b630c2b246808
```

对应的官方 Flutter 和 Engine 提交为：

```text
Flutter 3.7.12: 4d9e56e694b656610ab87fcf2efbcd226e0ed8cf
Engine:         1a65d409c7a1438a34d21b60bf30a6fd5db59314
Dart:           2.19.6
```

参考容器底层的 `/usr/local/flutter` 后来已升级到 2023-04-27 的 master 提交
`55c988fb453eddd97cb2e4d6df9ec28d72e2e899`，但容器的 Dockerfile 明确把已经在
宿主机编译好的 `app/build/web` 复制进镜像，`flutter build web` 一行处于注释状态。
因此该底层 SDK 不能当作产物编译器；项目生成文件中的 `3.7.12` 才是直接证据。

`webclient-v1/Dockerfile` 固定 Flutter `3.7.12` 的完整提交及 Engine 提交，并通过
两份 lockfile 固定 TypeScript、Dart 和 Flutter 依赖。旧项目中的 `.metadata`
记录的是最初创建项目时的 Flutter 版本，也不是 2023 年产物的编译器版本。

在 Linux amd64 上以该工具链从随附完整源码重建后，`main.dart.js` 的 SHA-256
为 `dc012d2e7a91c43eb753aa982a8a78f1c02dd86ca9bcf9258091dc67bcaccb5f`，
文件长度为 3,002,922 字节；与现有 V1 产物的 `cmp` 逐字节比较通过。

## 许可证与版权

完整 GNU AGPL v3 文本位于 `LICENCE`，并在完整源码包中原样保留，
其 SHA-256 为：

```text
8486a10c4393cee1c25392769ddd3b2d6c242d6ec7928e1414efff7dfb2f07ef
```

源码中的原始声明均未改写或删除，包括但不限于：

- `Cargo.toml` 中的 `rustdesk <info@rustdesk.com>`；
- `Cargo.toml` 中的 `Copyright © 2022 Purslane, Inc.`；
- `src/ui/index.tis` 中 Purslane Ltd. 与 ZJUPI 的声明；
- `flutter/web/ogvjs-1.8.6/`、依赖通知及其他第三方许可证。
