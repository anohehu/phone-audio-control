param(
    [string[]]$PhoneIps = @("10.94.18.52"),
    [string]$ScrcpyDir = "C:\Users\Administrator\AppData\Local\Microsoft\WinGet\Packages\Genymobile.scrcpy_Microsoft.Winget.Source_8wekyb3d8bbwe\scrcpy-win64-v4.1"
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Add-Type @"
using System.Runtime.InteropServices;
public class DragForm {
    [DllImport("user32.dll")] public static extern bool ReleaseCapture();
    [DllImport("user32.dll")] public static extern int SendMessage(System.IntPtr hWnd, int msg, int wParam, int lParam);
}
"@

$dir = $ScrcpyDir
$adb = Join-Path $dir "adb.exe"
$script:OpenPanels = 0

function Test-Connected([string]$ip) {
    $out = & $adb -s "${ip}:5555" get-state 2>$null
    return ($out -match "device")
}

function Get-DeviceProcesses([string]$ip) {
    Get-CimInstance Win32_Process -Filter "Name='scrcpy.exe'" | Where-Object { $_.CommandLine -like "*${ip}:5555*" }
}

function Start-Audio([string]$ip) {
    & $adb connect "${ip}:5555" | Out-Null
    if (-not (Get-DeviceProcesses $ip)) {
        $launcher = Join-Path $dir "scrcpy-noconsole.vbs"
        Start-Process -FilePath "wscript.exe" -ArgumentList @("`"$launcher`"", "-s", "${ip}:5555", "--no-window", "--no-video", "--no-control") -WorkingDirectory $dir | Out-Null
    }
}

function Stop-Audio([string]$ip) {
    Get-DeviceProcesses $ip | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}

function Update-Status([string]$ip, $statusLabel) {
    if (Test-Connected $ip) {
        $statusLabel.Text = "$ip OK"
        $statusLabel.ForeColor = [System.Drawing.Color]::Green
    } else {
        $statusLabel.Text = "$ip NO"
        $statusLabel.ForeColor = [System.Drawing.Color]::Red
    }
}

function Toggle-Play([string]$ip) {
    & $adb -s "${ip}:5555" shell input keyevent 85 | Out-Null
}

function New-Panel([string]$deviceIp, [int]$index) {
    $play = New-Object System.Windows.Forms.Button
    $play.Text = "Play/Pause"
    $play.Location = New-Object System.Drawing.Point(0, 24)
    $play.Size = New-Object System.Drawing.Size(170, 54)
    $play.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $play.FlatAppearance.BorderSize = 0
    $play.Add_Click({ Toggle-Play $deviceIp })

    $status = New-Object System.Windows.Forms.Label
    $status.Text = "Connecting..."
    $status.Location = New-Object System.Drawing.Point(4, 4)
    $status.Size = New-Object System.Drawing.Size(144, 18)
    $status.ForeColor = [System.Drawing.Color]::Gray

    $close = New-Object System.Windows.Forms.Button
    $close.Text = "X"
    $close.Location = New-Object System.Drawing.Point(152, 0)
    $close.Size = New-Object System.Drawing.Size(18, 22)
    $close.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $close.FlatAppearance.BorderSize = 0
    $close.Add_Click({ $form.Close() })

    $form = New-Object System.Windows.Forms.Form
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
    $form.TopMost = $true
    $form.ShowInTaskbar = $false
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual
    $form.Location = New-Object System.Drawing.Point((100 + 130 * $index), 100)
    $form.Size = New-Object System.Drawing.Size(170, 78)
    $form.Controls.Add($play)
    $form.Controls.Add($status)
    $form.Controls.Add($close)

    $script:OpenPanels++
    $form.Add_FormClosing({
        Stop-Audio $deviceIp
        $script:OpenPanels--
        if ($script:OpenPanels -eq 0) {
            [System.Windows.Forms.Application]::Exit()
        }
    })

    $form.Add_MouseDown({
        [DragForm]::ReleaseCapture() | Out-Null
        [DragForm]::SendMessage($form.Handle, 0xA1, 2, 0) | Out-Null
    })
    $status.Add_MouseDown({
        [DragForm]::ReleaseCapture() | Out-Null
        [DragForm]::SendMessage($form.Handle, 0xA1, 2, 0) | Out-Null
    })

    Start-Audio $deviceIp
    Update-Status $deviceIp $status

    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 2000
    $timer.Add_Tick({ Update-Status $deviceIp $status })
    $timer.Start()

    return $form
}

$forms = @()
for ($i = 0; $i -lt $PhoneIps.Count; $i++) {
    $forms += New-Panel $PhoneIps[$i] $i
}
$forms | ForEach-Object { $_.Show() }
[System.Windows.Forms.Application]::Run()
