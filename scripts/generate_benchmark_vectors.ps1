# Published NIST KATs plus independent .NET avalanche answers.
$root=Split-Path $PSScriptRoot -Parent
$key=[Convert]::FromHexString('000102030405060708090A0B0C0D0E0F')
$plain=[Convert]::FromHexString('00112233445566778899AABBCCDDEEFF')
$records=[Collections.Generic.List[string]]::new()
$nist=Get-Content (Join-Path $root 'tb/crypto/vectors/aes128_kat.mem')
foreach($line in $nist) { if($line -match '^[0-9a-fA-F]{96}$') { $records.Add($line) } }
if($records.Count -ne 284) { throw 'Expected 284 published NIST vectors' }
$aes=[Security.Cryptography.Aes]::Create()
try {
    $aes.Mode=[Security.Cryptography.CipherMode]::ECB
    $aes.Padding=[Security.Cryptography.PaddingMode]::None
    $aes.Key=$key
    # Baseline followed by each of the 128 possible single-bit changes.
    for($trial=-1;$trial -lt 128;$trial++) {
        $inputBlock=[byte[]]$plain.Clone()
        if($trial -ge 0) {
            $index=[int][Math]::Floor($trial/8)
            $inputBlock[$index]=$inputBlock[$index] -bxor (1 -shl ($trial%8))
        }
        $enc=$aes.CreateEncryptor()
        try { $cipher=$enc.TransformFinalBlock($inputBlock,0,16) } finally { $enc.Dispose() }
        if($trial -eq -1 -and [Convert]::ToHexString($cipher) -ne '69C4E0D86A7B0430D8CDB78070B4C55A') { throw 'Oracle FIPS check failed' }
        $records.Add([Convert]::ToHexString($key)+[Convert]::ToHexString($inputBlock)+[Convert]::ToHexString($cipher))
    }
} finally { $aes.Dispose() }
[IO.File]::WriteAllText((Join-Path $root 'tb/internal/benchmark_vectors.mem'),($records -join "`n")+"`n")
Write-Output '413 vectors: 284 published NIST + one FIPS baseline + 128 independent .NET single-bit flips.'
