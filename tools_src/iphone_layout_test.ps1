# iPhone layout check on the desktop: a phone-shaped window (iPhone 15 Pro in points, 393x852) with a simulated
# notch (59 pt) and home bar (34 pt) that arrive after the first layout, as on a real iPhone (2026-10-12). Off-screen and silent like the self-test, with the same memory and time guard.
# Screenshots land in %APPDATA%\Godot\app_userdata\<project>\iphone_play.png and iphone_done.png.
$root = 'C:\Users\Eric Wade\PAGOURO_PLAY'
$exe = "$root\tools\godot\Godot_v4.7.2-stable_win64_console.exe"
$out = "$env:TEMP\jigsaw_iphone_out.txt"
$p = Start-Process -FilePath $exe -ArgumentList '--path', 'jigsaw', '--audio-driver', 'Dummy', '--position', '-4000,-4000', '--resolution', '393x852', '--', '--iphone', '--safe-late', '--sim-safe=59,34' `
     -WorkingDirectory $root -RedirectStandardOutput $out -RedirectStandardError "$out.err" -PassThru -WindowStyle Hidden
$start = Get-Date
while (-not $p.HasExited) {
    Start-Sleep -Milliseconds 500
    $mb = [int](((Get-Process -Name "Godot_v4.7.2-stable_win64*" -ErrorAction SilentlyContinue | Measure-Object WorkingSet64 -Sum).Sum) / 1MB)
    if ($mb -gt 2500 -or ((Get-Date) - $start).TotalSeconds -gt 120) {
        Get-Process -Name "Godot_v4.7.2-stable_win64*" -ErrorAction SilentlyContinue | Stop-Process -Force
        "KILLED by guard at $mb MB after $([int]((Get-Date) - $start).TotalSeconds) s"
        break
    }
}
Get-Content $out | Select-String 'IPHONE' | ForEach-Object { $_.Line -split ' \| ' }
Get-Content $out, "$out.err" | Select-String -Pattern 'SCRIPT ERROR|Parse Error' | Select-Object -First 5
