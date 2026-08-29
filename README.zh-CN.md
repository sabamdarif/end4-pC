



<div align="center">

# 💠 end4-pC

**[illogical-impulse](https://github.com/end-4/dots-hyprland)（作者：[@end-4](https://github.com/end-4)）的个人分支**
由 **pctrade** 定制并维护

[English](README.md) | [简体中文](README.zh-CN.md) | [日本語](README.ja.md)

</div>

---

## 🎬 展示

<p align="center">
  <a href="https://www.youtube.com/watch?v=o0Vsh7eVchs">
    <img src="https://img.youtube.com/vi/o0Vsh7eVchs/maxresdefault.jpg" alt="Material 3 Expressive x Linux" width="85%" style="border-radius: 12px; box-shadow: 0px 10px 30px rgba(0,0,0,0.5);"/>
  </a>
</p>

</div>

---

## 📸 截图
<div align="center">

| 🎵 歌词 | 🖼️ 在线壁纸 |
|:---:|:---:|
| ![截图 1](screenshots/1.png) | ![截图 2](screenshots/2.png) |
| 🪟 桌面小组件 | 🔧 Niri 配置 |
| ![截图 5](screenshots/5.png) | ![截图 6](screenshots/6.png) |
| ⚙️ 可配置的状态栏 | ✨ 以及更多功能 |
| ![截图 3](screenshots/3.png) | ![截图 4](screenshots/4.png) |

</div>

---

## ⚡ 安装

> [!NOTE]
> 此分支仅支持 [niri](https://github.com/YaLTeR/niri)。它会独立管理自己的配置文件夹，**不会**覆盖或修改任何现有设置。

```bash
cd ~/.config/quickshell/
git clone https://github.com/pctrade/end4-pC.git
killall qs 2>/dev/null; qs -c end4-pC > /dev/null 2>&1 & disown
```

### 🔧 随 niri 启动（可选）

若希望登录时自动加载，请将以下内容添加到 `~/.config/niri/config.kdl`：

```kdl
spawn-at-startup "qs" "-c" "end4-pC"
```

> [!TIP]
> niri 会在保存时自动重载配置，因此只需重启 shell 本身：`killall qs; qs -c end4-pC & disown`。

---

### ⚙️ 设置快捷键

本 shell 不注册自己的全局快捷键，按键由 niri 管理，并通过 IPC 驱动 shell。要打开设置面板，请将以下内容添加到 niri 的按键绑定中：

```kdl
Mod+Escape { spawn "qs" "-c" "end4-pC" "ipc" "call" "settings" "toggle"; }
```

> **注意：** 设置是一个覆盖面板，而不是普通窗口，因此 `Mod + Q` 无法将其关闭。请使用同一个快捷键进行切换，或按 `Escape`。

## 🙏 致谢

衷心感谢促成此项目的人们：

- **[@end-4](https://github.com/end-4)** — 创建了原始的 [dots-hyprland](https://github.com/end-4/dots-hyprland) / illogical-impulse shell。这个 dotfiles 项目堪称杰作 🫡
- **[@gh0stzk](https://github.com/gh0stzk)** — 提供了天气 API 集成，让天气小组件得以实现 🙌
- **[@StarS2112](https://github.com/StarS2112)** — 展示了此分支 🙌

---

<div align="center">

用 ❤️ 制作——欢迎自由分支并打造属于你自己的版本

</div>
