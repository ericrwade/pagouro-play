# Run the jigsaw self-test with a memory guard: kill it if it passes 2.5 GB or 6 minutes (after the 2026-10-06 freeze).
$root = 'C:\Users\Eric Wade\PAGOURO_PLAY'
$exe = "$root\tools\godot\Godot_v4.7.2-stable_win64_console.exe"
$out = "$env:TEMP\jigsaw_selftest_out.txt"
$p = Start-Process -FilePath $exe -ArgumentList '--path', 'jigsaw', '--audio-driver', 'Dummy', '--position', '-4000,-4000', '--', '--selftest' `
     -WorkingDirectory $root -RedirectStandardOutput $out -RedirectStandardError "$out.err" -PassThru -WindowStyle Hidden
$peak = 0
$start = Get-Date
while (-not $p.HasExited) {
    Start-Sleep -Milliseconds 500
    $mb = [int](((Get-Process -Name "Godot_v4.7.2-stable_win64*" -ErrorAction SilentlyContinue | Measure-Object WorkingSet64 -Sum).Sum) / 1MB)
    if ($mb -gt $peak) { $peak = $mb }
    if ($mb -gt 2500 -or ((Get-Date) - $start).TotalSeconds -gt 360) {
        Get-Process -Name "Godot_v4.7.2-stable_win64*" -ErrorAction SilentlyContinue | Stop-Process -Force
        "KILLED by guard at $mb MB after $([int]((Get-Date) - $start).TotalSeconds) s"
        break
    }
}
"peak memory $peak MB, $([int]((Get-Date) - $start).TotalSeconds) s"
Get-Content $out | Select-String 'SELFTEST' | ForEach-Object { $_.Line -split ' \| ' } | Select-String -Pattern 'share|calendar|new picture|daily at 100|tray glide|clock:|restore:|daily index|snap:'
Get-Content $out, "$out.err" | Select-String -Pattern 'SCRIPT ERROR|Parse Error' | Select-Object -First 5
