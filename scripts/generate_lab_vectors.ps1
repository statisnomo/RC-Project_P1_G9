# Maintainer helper: independent .NET AES oracle, no RTL-derived expected data.
$root = Split-Path $PSScriptRoot -Parent
$keyText = '000102030405060708090A0B0C0D0E0F'
function HexBytes([string]$s) {
    [byte[]]$bytes = for ($i=0; $i -lt $s.Length; $i+=2) { [Convert]::ToByte($s.Substring($i,2),16) }
    return ,$bytes
}
$inputs = @('00112233445566778899AABBCCDDEEFF', '00000000000000000000000000000000',
    'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF', '0123456789ABCDEF0123456789ABCDEF',
    '000102030405060708090A0B0C0D0E0F', 'FEDCBA9876543210FEDCBA9876543210',
    '11111111111111111111111111111111', 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
    '55555555555555555555555555555555', '80000000000000000000000000000000')
$aes = [System.Security.Cryptography.Aes]::Create()
try {
    $aes.Mode = [System.Security.Cryptography.CipherMode]::ECB
    $aes.Padding = [System.Security.Cryptography.PaddingMode]::None
    $aes.Key = HexBytes $keyText
    $records = for ($i=0; $i -lt $inputs.Count; $i++) {
        $encryptor = $aes.CreateEncryptor()
        try { $cipher = $encryptor.TransformFinalBlock((HexBytes $inputs[$i]),0,16) }
        finally { $encryptor.Dispose() }
        [pscustomobject]@{ trial=$i+1; plaintext=$inputs[$i]; ciphertext=([BitConverter]::ToString($cipher)).Replace('-','') }
    }
} finally { $aes.Dispose() }
if ($records[0].ciphertext -ne '69C4E0D86A7B0430D8CDB78070B4C55A' -or
    $records[1].ciphertext -ne 'C6A13B37878F5B826F4F8162A1C8D879') { throw 'Independent oracle sanity check failed' }
$mem = ($records | ForEach-Object { $_.plaintext + $_.ciphertext }) -join "`n"
[IO.File]::WriteAllText((Join-Path $root 'tb/internal/display_lab_vectors.mem'),$mem+"`n")
$json = @{ key=$keyText; oracle='.NET System.Security.Cryptography.Aes, ECB, no padding'; vectors=$records } | ConvertTo-Json -Depth 4
[IO.File]::WriteAllText((Join-Path $root 'docs/display_lab_vectors.json'),$json+"`n")
Write-Output 'Generated 10 independently calculated lab vectors; FIPS and zero-block sanity checks passed.'
