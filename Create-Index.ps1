param(
    [Parameter(Mandatory = $true)]
    [string]$RootPath
)

$RootPath  = Resolve-Path $RootPath
$indexFile = Join-Path $RootPath ("Aufgaben.md")
$indexDir  = Split-Path $indexFile -Parent

#
#  Aufruf: .\Create-Index.ps1 '.\1st year\'
#

# Header
$header = @"
---
hide:   
  - toc
---

# Aufgaben&uuml;bersicht

| Name | Aufgabe | Lernziele und Kompetenzen |
|------|---------|---------------------------|
"@

Set-Content -Path $indexFile -Value $header -Encoding UTF8

Get-ChildItem -Path $RootPath -Recurse -Filter "TASK*.md" | ForEach-Object {

    $taskFile = $_
    $content  = Get-Content $taskFile.FullName -Encoding UTF8

    # ---------- relativer Pfad zur INDEX.md ----------
    $uriIndex = New-Object System.Uri("$indexDir\")
    $uriTask  = New-Object System.Uri($taskFile.FullName)
    $relativePath = $uriIndex.MakeRelativeUri($uriTask).ToString()
    $relativePath = [System.Uri]::UnescapeDataString($relativePath)

    # ---------- Aufgabe aus erster # Überschrift ----------
    $aufgabe = $null
    foreach ($line in $content) {
        if ($line -match '^#\s+(.+)$') {
            $aufgabe = $Matches[1]
            break
        }
    }
    if (-not $aufgabe) {
        $aufgabe = '_Keine Überschrift_'
    }

    # ---------- Lernziele ----------
    $zielZeilen = @()
    $capture = $false


	foreach ($line in $content) {
		if ($line -match '^##\s*(Lernziele und Kompetenzen|Ziele)') {
			$capture = $true
			continue
		}
		if ($capture -and $line -match '^##\s+') { break }
		if ($capture -and $line.Trim()) {
			$zielZeilen += $line
		}
	}


    if ($zielZeilen.Count -eq 0) {
        $zielZeilen = @('_Keine Lernziele angegeben_')
    }

    $zielText = $zielZeilen -join '<br>'
    $zielText = $zielText -replace '^(&lt;br&gt;\s*)+', ''

    # ✅ Name als Markdown‑Link
    $nameLink = "[$($taskFile.BaseName)]($relativePath)"

    Add-Content -Path $indexFile `
        -Value "| $nameLink | $aufgabe | $zielText |" `
        -Encoding UTF8
}

Write-Host "INDEX.md wurde erstellt:"
Write-Host $indexFile