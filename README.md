# 手机音频控制面板

一个 Windows 小面板：把 Android 手机音频通过 [scrcpy](https://github.com/Genymobile/scrcpy) 无线推到电脑播放，同时显示连接状态、提供播放/暂停按钮。

## 依赖

- Windows
- [scrcpy](https://github.com/Genymobile/scrcpy)（需自带 `adb.exe` 和 `scrcpy-noconsole.vbs`）
- Android 手机已开启无线 ADB，并和电脑在同一个 Wi-Fi / 热点网络

## 使用

1. 修改脚本开头两个参数：
   - `PhoneIp`：手机在热点网络里的 IP
   - `ScrcpyDir`：scrcpy 安装目录
2. 创建快捷方式，目标填：

   ```bat
   powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File C:\路径\control-button.ps1
   ```

3. 双击快捷方式：
   - 顶部显示 `Connected` / `Disconnected`
   - 点 `Play/Pause` 切换手机播放状态
   - 拖动顶部状态文字可移动面板
   - 点 `X` 关闭面板并停止音频传输

## 说明

- 本项目只是 scrcpy 的外部控制面板，不包含 scrcpy 本体。
- scrcpy 是 Genymobile 的开源项目，基于 Apache License 2.0。
- 手机重启后需要重新开启一次无线 ADB。
