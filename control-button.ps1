param(
    [string[]]$PhoneIps = @("10.94.18.52", "10.94.18.84"),
    [string]$ScrcpyDir = "C:\Users\Administrator\AppData\Local\Microsoft\WinGet\Packages\Genymobile.scrcpy_Microsoft.Winget.Source_8wekyb3d8bbwe\scrcpy-win64-v4.1"
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic

Add-Type @"
using System.Runtime.InteropServices;
public class DragForm {
    [DllImport("user32.dll")] public static extern bool ReleaseCapture();
    [DllImport("user32.dll")] public static extern int SendMessage(System.IntPtr hWnd, int msg, int wParam, int lParam);
}
"@

$dir = $ScrcpyDir
$adb = Join-Path $dir "adb.exe"
$script:DeviceIps = @($PhoneIps)
$script:StatusLabels = @()
$script:DeviceNames = @()
$script:Names = @{}
$script:StreamStates = @()
$script:Docked = $false
$script:Collapsed = $false
$script:ExpandedHeight = 30 + 32 * $script:DeviceIps.Count
$configPath = Join-Path $PSScriptRoot "devices.json"

if (Test-Path $configPath) {
    try {
        $loaded = [System.IO.File]::ReadAllText($configPath) | ConvertFrom-Json
        foreach ($p in $loaded.PSObject.Properties) {
            $script:Names[$p.Name] = [string]$p.Value
        }
    } catch {}
}

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

function Stop-All-Audio {
    foreach ($ip in $script:DeviceIps) {
        Stop-Audio $ip
    }
}

function Update-Status {
    for ($i = 0; $i -lt $script:DeviceIps.Count; $i++) {
        $ip = $script:DeviceIps[$i]
        $name = $script:DeviceNames[$i]
        $label = $script:StatusLabels[$i]
        if (Test-Connected $ip) {
            $label.Text = "$name OK"
            $label.ForeColor = [System.Drawing.Color]::Green
        } else {
            $label.Text = "$name NO"
            $label.ForeColor = [System.Drawing.Color]::Red
        }
    }
}

function Get-DeviceName([string]$ip) {
    if ($script:Names.ContainsKey($ip)) {
        return $script:Names[$ip]
    }
    $model = (& $adb -s "${ip}:5555" shell getprop ro.product.marketname 2>$null | Out-String).Trim()
    if (-not $model) {
        $model = (& $adb -s "${ip}:5555" shell getprop ro.product.model 2>$null | Out-String).Trim()
    }
    if (-not $model) {
        return $ip
    }
    return $model
}

function Save-Names {
    $json = $script:Names | ConvertTo-Json
    [System.IO.File]::WriteAllText($configPath, $json, (New-Object System.Text.UTF8Encoding($false)))
}

function Toggle-Play([string]$ip) {
    foreach ($other in $script:DeviceIps) {
        if ($other -ne $ip) {
            & $adb -s "${other}:5555" shell input keyevent 127 | Out-Null
        }
    }
    & $adb -s "${ip}:5555" shell input keyevent 85 | Out-Null
}

foreach ($ip in $script:DeviceIps) {
    $script:DeviceNames += Get-DeviceName $ip
    $script:StreamStates += $true
}

$form = New-Object System.Windows.Forms.Form
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$form.TopMost = $true
$form.ShowInTaskbar = $false
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual
$form.Location = New-Object System.Drawing.Point(100, 100)
$form.Size = New-Object System.Drawing.Size(390, (30 + 32 * $script:DeviceIps.Count))

$close = New-Object System.Windows.Forms.Button
$close.Text = "X"
$close.Location = New-Object System.Drawing.Point(368, 0)
$close.Size = New-Object System.Drawing.Size(22, 26)
$close.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$close.FlatAppearance.BorderSize = 0
$close.Add_Click({ $form.Close() })
$form.Controls.Add($close)
$script:CloseButton = $close

$dockHint = New-Object System.Windows.Forms.Label
$dockHint.Text = "..."
$dockHint.Location = New-Object System.Drawing.Point(138, 0)
$dockHint.Size = New-Object System.Drawing.Size(24, 10)
$dockHint.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$dockHint.Visible = $false
$form.Controls.Add($dockHint)
$script:DockHint = $dockHint

$y = 28
for ($i = 0; $i -lt $script:DeviceIps.Count; $i++) {
    $ip = $script:DeviceIps[$i]

    $status = New-Object System.Windows.Forms.Label
    $status.Text = "$($script:DeviceNames[$i]) Connecting..."
    $status.Location = New-Object System.Drawing.Point(4, $y)
    $status.Size = New-Object System.Drawing.Size(140, 28)
    $status.ForeColor = [System.Drawing.Color]::Gray
    $status.Add_MouseDown({
        [DragForm]::ReleaseCapture() | Out-Null
        [DragForm]::SendMessage($form.Handle, 0xA1, 2, 0) | Out-Null
    })
    $form.Controls.Add($status)
    $script:StatusLabels += $status

    $rename = New-Object System.Windows.Forms.Button
    $rename.Text = "Rename"
    $rename.Tag = $i
    $rename.Location = New-Object System.Drawing.Point(148, $y)
    $rename.Size = New-Object System.Drawing.Size(58, 28)
    $rename.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $rename.FlatAppearance.BorderSize = 0
    $rename.Add_Click({
        $idx = $this.Tag
        $deviceIp = $script:DeviceIps[$idx]
        $newName = [Microsoft.VisualBasic.Interaction]::InputBox("New name", "Rename device", $script:DeviceNames[$idx])
        if (-not [string]::IsNullOrWhiteSpace($newName)) {
            $script:Names[$deviceIp] = $newName
            $script:DeviceNames[$idx] = $newName
            Save-Names
            Update-Status
        }
    })
    $form.Controls.Add($rename)

    $switch = New-Object System.Windows.Forms.Button
    $switch.Text = "PC On"
    $switch.Tag = $i
    $switch.Location = New-Object System.Drawing.Point(206, $y)
    $switch.Size = New-Object System.Drawing.Size(64, 28)
    $switch.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $switch.FlatAppearance.BorderSize = 0
    $switch.Add_Click({
        $idx = $this.Tag
        $deviceIp = $script:DeviceIps[$idx]
        $script:StreamStates[$idx] = -not $script:StreamStates[$idx]
        if ($script:StreamStates[$idx]) {
            Start-Audio $deviceIp
            $this.Text = "PC On"
        } else {
            Stop-Audio $deviceIp
            $this.Text = "PC Off"
        }
    })
    $form.Controls.Add($switch)

    $play = New-Object System.Windows.Forms.Button
    $play.Text = "Play/Pause"
    $play.Tag = $ip
    $play.Location = New-Object System.Drawing.Point(274, $y)
    $play.Size = New-Object System.Drawing.Size(80, 28)
    $play.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $play.FlatAppearance.BorderSize = 0
    $play.Add_Click({ Toggle-Play $this.Tag })
    $form.Controls.Add($play)

    $y += 32
    Start-Audio $ip
}

function Set-Collapsed([bool]$collapsed) {
    $script:Collapsed = $collapsed
    if ($collapsed) {
        $form.Height = 10
        foreach ($c in $form.Controls) {
            if ($c -ne $script:CloseButton -and $c -ne $script:DockHint) {
                $c.Visible = $false
            }
        }
        $script:DockHint.Visible = $true
    } else {
        $form.Height = $script:ExpandedHeight
        foreach ($c in $form.Controls) {
            if ($c -ne $script:DockHint) {
                $c.Visible = $true
            }
        }
        $script:DockHint.Visible = $false
    }
}

$form.Add_LocationChanged({
    if (-not $script:Docked -and $form.Top -le 0) {
        $form.Top = 0
        $script:Docked = $true
        Set-Collapsed $true
    } elseif ($script:Docked -and $form.Top -gt 0) {
        $script:Docked = $false
        Set-Collapsed $false
    }
})

$form.Add_FormClosing({
    Stop-All-Audio
    [System.Windows.Forms.Application]::Exit()
})
$form.Add_MouseDown({
    [DragForm]::ReleaseCapture() | Out-Null
    [DragForm]::SendMessage($form.Handle, 0xA1, 2, 0) | Out-Null
})

Update-Status

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 2000
$timer.Add_Tick({ Update-Status })
$timer.Start()

$hoverTimer = New-Object System.Windows.Forms.Timer
$hoverTimer.Interval = 300
$hoverTimer.Add_Tick({
    if ($script:Docked) {
        $r = New-Object System.Drawing.Rectangle($form.Location, $form.Size)
        if ($r.Contains([System.Windows.Forms.Cursor]::Position)) {
            if ($script:Collapsed) {
                Set-Collapsed $false
            }
        } else {
            if (-not $script:Collapsed) {
                Set-Collapsed $true
            }
        }
    }
})
$hoverTimer.Start()

$form.Show()
[System.Windows.Forms.Application]::Run()
