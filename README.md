# 手机音频控制面板

一个 Windows 小面板：把 Android 手机音频通过 [scrcpy](https://github.com/Genymobile/scrcpy) 无线推到电脑播放，同时显示连接状态、提供播放/暂停按钮。实现类似蓝牙耳机在不同设备间音频流转的功能。

## 解决什么问题

常见场景：电脑插着有线耳机，手机看视频或听歌时，声音只能在手机扬声器或手机自己的耳机里出来，电脑上的有线耳机用不上；来回拔插耳机又很麻烦。

这个项目把 Android 手机音频通过 Wi-Fi / 热点无线推到电脑，再交给电脑当前的默认播放设备（比如你插在电脑上的有线耳机），这样：

- 不用拔插耳机，手机和电脑可以同时使用同一副耳机
- 不用镜像手机屏幕，只传声音
- 打开小面板就能看到连接是否成功
- 在电脑上点一下就能播放 / 暂停手机上的内容

## 适用条件

- Windows 电脑
- Android 手机，和电脑在同一个 Wi-Fi 或热点网络
- 手机上开启无线 ADB（首次配置需要 USB 线）

## 依赖

- Windows
- [scrcpy](https://github.com/Genymobile/scrcpy)（需自带 `adb.exe` 和 `scrcpy-noconsole.vbs`）
- Android 手机已开启无线 ADB，并和电脑在同一个 Wi-Fi / 热点网络

## 不会配置？

把本仓库链接发给任意 AI，让它按 [AI_SETUP_GUIDE.md](AI_SETUP_GUIDE.md) 帮你配置。

## 手机配置（首次）

1. 打开开发者选项
   - 通用路径：设置 → 关于手机 → 连点“版本号”7 次，直到提示“已进入开发者模式”
   - 小米：设置 → 我的设备 → 全部参数与信息 → 连点“MIUI 版本”
   - 华为 / 荣耀：设置 → 关于手机 → 连点“版本号”
2. 打开 USB 调试
   - 设置 → 系统（或更多设置）→ 开发者选项 → 打开“USB 调试”
   - 如果弹窗询问是否允许，点“允许”或“确定”
3. 连接电脑
   - 用数据线连接手机和电脑
   - 如果手机询问 USB 用途，选择“传输文件”（不要只选“仅充电”）
   - 手机弹出“允许 USB 调试吗？”时，勾选“一律允许使用这台计算机进行调试”，然后点“允许”
4. 验证连接
   - 电脑终端运行 `adb devices`
   - 显示 `device` 即连接成功
   - 显示 `unauthorized` 表示还没在手机上点“允许”
5. 开启无线 ADB
   - 电脑终端运行 `adb tcpip 5555`
   - 拔掉 USB 线
   - 查看手机 IP：设置 → WLAN / 热点 → 当前网络详情
   - 运行 `adb connect 手机IP:5555`
   - 显示 `connected` 即无线连接成功，IP 会用在下面第 1 步里

## 使用

1. 修改脚本开头两个参数：
   - `PhoneIp`：上一步查到的手机 IP
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
