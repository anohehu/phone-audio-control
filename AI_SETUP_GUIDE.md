# AI 配置指南

把本仓库链接发给任意 AI 时，让 AI 按下面的流程帮助用户完成配置。

## 环境前提

- Windows 电脑
- Android 手机，和电脑处于同一个 Wi-Fi 或热点网络
- 一根 USB 数据线（仅在首次开启无线调试时使用）

## 配置步骤

1. 安装 scrcpy
   - 打开终端，运行：
     `winget install --id Genymobile.scrcpy --accept-source-agreements --accept-package-agreements`
   - 如果 winget 不可用，从 <https://github.com/Genymobile/scrcpy/releases> 下载 win64 版本并解压
   - 找到 `scrcpy.exe` 所在目录，记下完整路径，例如 `C:\scrcpy`

2. 手机开启 USB 调试
   - 通用路径：设置 → 关于手机 → 连点“版本号”7 次，直到提示“已进入开发者模式”
   - 小米：设置 → 我的设备 → 全部参数与信息 → 连点“MIUI 版本”
   - 华为 / 荣耀：设置 → 关于手机 → 连点“版本号”
   - 设置 → 系统（或更多设置）→ 开发者选项 → 打开“USB 调试”
   - 用数据线连接电脑，USB 用途选“传输文件”
   - 手机弹窗勾选“一律允许使用这台计算机进行调试”，点“允许”
   - 验证：电脑终端运行 `adb devices`，显示 `device` 即成功；显示 `unauthorized` 表示还没在手机上点允许

3. 开启无线 ADB
   - 终端运行：`adb tcpip 5555`
   - 拔掉 USB 线
   - 查看手机 IP：设置 → WLAN/热点 → 当前网络详情
   - 运行：`adb connect 手机IP:5555`
   - 返回 `device` 即连接成功

4. 修改本仓库脚本参数
   - 编辑 `control-button.ps1` 开头两行：
     - `PhoneIps` 改成手机 IP 列表。单台：`@("10.94.18.52")`；多台：`@("10.94.18.52", "10.94.18.53")`
     - `ScrcpyDir` 改成 scrcpy 所在目录
   - 也可以不修改文件，运行时用参数传入

5. 创建桌面快捷方式
   - 新建快捷方式，目标填：
     `powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "完整路径\control-button.ps1"`
   - 保存到桌面，名称可以叫“手机音频”

6. 验证
   - 双击快捷方式，所有手机会显示在同一个面板里，每台一行
   - 每行应显示 `手机名称 OK` / `手机名称 NO`，默认读取手机型号名
   - 点 `Rename` 可以改名，名称会保存到 `devices.json`
   - 在手机上播放音频，声音应从电脑默认播放设备出来
   - 点对应行的 `Play/Pause` 能切换那台手机的播放状态
   - 把面板拖到屏幕上边缘会自动收起，鼠标移上去再展开

## 常见问题

- `scrcpy` 不是内部或外部命令：安装后需要重新打开终端，或者使用完整路径
- 显示 `Disconnected`：检查手机和电脑是否在同一个网络、手机 IP 是否变化、是否重新执行过 `adb connect`
- 手机重启后连不上：需要重新插线执行 `adb tcpip 5555`
- 声音没出来：确认电脑默认播放设备是有线耳机
- 出现多余窗口：确认 scrcpy 启动参数包含 `--no-window --no-video --no-control`
- 手机开热点：手机 IP 通常是热点网关，一般比较稳定，变化时改 `PhoneIps` 即可
- 多台手机同时连接：确认每个手机 IP 都填进了 `PhoneIps`，并且都已开启无线 ADB
- 播放优先级：面板上的 `Play/Pause` 会先暂停其他手机，最后操作的那台优先；手机本机开始播放时不会自动触发
