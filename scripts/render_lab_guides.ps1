# Offline HTML companions for the lab PC; PowerShell 7 Markdown renderer.
$root=Split-Path $PSScriptRoot -Parent
$style='body{max-width:960px;margin:32px auto;padding:0 24px;font:17px/1.6 system-ui;color:#17202a}h1,h2{line-height:1.25}pre{background:#f1f4f7;padding:16px;overflow:auto}code{font-size:0.95em}li{margin:8px 0}a{color:#075cab}@media print{body{font-size:11pt;margin:0}h2{break-after:avoid}pre{white-space:pre-wrap}}'
foreach($stem in @('NEXT_LAB_COMBINED','LAB_UART_OPTIONAL','LAB_ONBOARD_OLED','docs/lab_ten_blocks')) {
    $html=(ConvertFrom-Markdown -LiteralPath (Join-Path $root ($stem+'.md'))).Html
    $html=$html.Replace('NEXT_LAB_COMBINED.md','NEXT_LAB_COMBINED.html').Replace('LAB_UART_OPTIONAL.md','LAB_UART_OPTIONAL.html').Replace('LAB_ONBOARD_OLED.md','LAB_ONBOARD_OLED.html').Replace('lab_ten_blocks.md','lab_ten_blocks.html')
    $title=[Net.WebUtility]::HtmlEncode(($stem.Split('/')[-1]).Replace('_',' '))
    $page='<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+$title+'</title><style>'+$style+'</style><body>'+$html+'</body></html>'
    [IO.File]::WriteAllText((Join-Path $root ($stem+'.html')),$page)
}
Write-Output 'Rendered four offline lab guides.'
