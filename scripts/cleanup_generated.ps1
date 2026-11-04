param([switch]$Apply)
# Remove only ignored compiler caches. Run after simulations/builds finish.
# Source, projects, reports, bitstreams, checkpoints and waveforms are protected.
$root = [IO.Path]::GetFullPath((Split-Path $PSScriptRoot -Parent)).TrimEnd('\','/')
$prefix = $root + [IO.Path]::DirectorySeparatorChar
$candidates = [System.Collections.Generic.List[object]]::new()
$protectedExtensions = @('.bit','.wdb','.wcfg','.dcp','.rpt')
$tracked = @(& git -c "safe.directory=$root" -C $root ls-files)
if ($LASTEXITCODE -ne 0) { throw 'Could not enumerate tracked files' }
foreach ($tree in @('build','vivado')) {
    $base = Join-Path $root $tree
    $dirs = Get-ChildItem -LiteralPath $base -Directory -Recurse -Force |
        Where-Object { $_.Name -in @('xsim.dir','.Xil','__pycache__') -or $_.Name.EndsWith('.cache') } |
        Sort-Object { $_.FullName.Length }
    foreach ($dir in $dirs) {
        $full = [IO.Path]::GetFullPath($dir.FullName)
        if (!$full.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or
            !$full.StartsWith($base+'\',[StringComparison]::OrdinalIgnoreCase)) { throw "Unsafe target: $full" }
        if (@($candidates | Where-Object { $full.StartsWith($_.path+'\',[StringComparison]::OrdinalIgnoreCase) }).Count) { continue }
        $node=$dir;$junction=$false
        while ($node -and $node.FullName -ne $root) {
            if ($node.Attributes -band [IO.FileAttributes]::ReparsePoint) { $junction=$true;break }
            $node=$node.Parent
        }
        if ($junction) { continue }
        $relative=$full.Substring($prefix.Length).Replace('\','/')
        if (@($tracked | Where-Object { $_.StartsWith($relative+'/') }).Count) { continue }
        & git -c "safe.directory=$root" -C $root check-ignore -q -- $relative
        if ($LASTEXITCODE -ne 0) { continue }
        $items=@(Get-ChildItem -LiteralPath $full -Recurse -Force)
        if (@($items | Where-Object { ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -or $_.Extension -in $protectedExtensions }).Count) { continue }
        $files=@($items | Where-Object { !$_.PSIsContainer })
        $bytes=($files | Measure-Object -Property Length -Sum).Sum
        $candidates.Add([pscustomobject]@{path=$full;relative=$relative;files=$files.Count;bytes=[long]$bytes})
    }
}
$record=[ordered]@{applied=[bool]$Apply;directories=$candidates.Count;bytes=[long](($candidates | Measure-Object -Property bytes -Sum).Sum);targets=$candidates}
$record | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $root 'build/cleanup_2026-11-05.json')
if ($Apply) {
    foreach ($item in $candidates) {
        # Every exact absolute target was checked above; no other shell is used.
        Remove-Item -LiteralPath $item.path -Recurse -Force -ErrorAction Stop
    }
}
Write-Output "Cleanup applied=$Apply directories=$($record.directories) bytes=$($record.bytes)"
