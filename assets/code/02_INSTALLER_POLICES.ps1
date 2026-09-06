# ============================================================
# 02_INSTALLER_POLICES.ps1
#
# Installation intelligente de polices Windows 10/11
#
# Formats :
#   .TTF
#   .OTF
#   .TTC
#
# Fonctionnement :
#   - Recherche récursive des polices
#   - Analyse Unicode
#   - Vérifie la présence de caractères latins
#   - Détecte arabe, CJK, japonais, coréen, cyrillique...
#   - Ignore les polices sans caractères latins
#   - Ignore les polices déjà installées
#   - Installe les polices compatibles
#   - Génère un rapport CSV
# ============================================================

$ErrorActionPreference = "Continue"

$Base = Split-Path -Parent $MyInvocation.MyCommand.Definition

$Rapport = Join-Path $Base "rapport_installation_polices.csv"

Write-Host ""
Write-Host "============================================================"
Write-Host "       INSTALLATION INTELLIGENTE DES POLICES"
Write-Host "============================================================"
Write-Host ""
Write-Host "Dossier analyse :"
Write-Host $Base
Write-Host ""

# ------------------------------------------------------------
# Chargement des API Windows/.NET permettant de lire les polices
# ------------------------------------------------------------

Add-Type -AssemblyName PresentationCore

# ------------------------------------------------------------
# Récupération des polices déjà installées
# ------------------------------------------------------------

$PolicesInstallees = @{}

foreach ($FontFamily in [System.Windows.Media.Fonts]::SystemFontFamilies) {

    try {

        $Nom = $FontFamily.FamilyNames.Values | Select-Object -First 1

        if ($Nom) {
            $PolicesInstallees[$Nom.ToLower()] = $true
        }

    }
    catch {
        # Ignore les familles impossibles à lire
    }
}

# ------------------------------------------------------------
# Caractères représentatifs du Latin
# ------------------------------------------------------------

$LatinChars = @(
    # Alphabet latin de base
    0x0041..0x005A
    0x0061..0x007A

    # Latin-1 Supplement
    0x00C0..0x00FF

    # Latin Extended-A
    0x0100..0x017F

    # Latin Extended-B
    0x0180..0x024F
)

# ------------------------------------------------------------
# Fonctions
# ------------------------------------------------------------

function Test-Character {

    param(
        [System.Windows.Media.GlyphTypeface]$Typeface,
        [int]$Code
    )

    try {

        $Char = [char]::ConvertFromUtf32($Code)

        return $Typeface.CharacterToGlyphMap.ContainsKey(
            $Char[0]
        )

    }
    catch {

        return $false
    }
}

function Get-FontLanguageInfo {

    param(
        [string]$Path
    )

    $Result = [ordered]@{

        Latin       = $false
        Arabe       = $false
        CJK         = $false
        Japonais    = $false
        Coreen      = $false
        Cyrillique  = $false
        Grec        = $false
    }

    try {

        $Collection = New-Object System.Windows.Media.GlyphTypeface

        # Certaines polices peuvent être difficiles à ouvrir
        $Uri = New-Object System.Uri($Path)

        $Collection = New-Object System.Windows.Media.GlyphTypeface($Uri)

        # ----------------------------------------------------
        # Recherche Latin
        # ----------------------------------------------------

        foreach ($Code in $LatinChars) {

            if (Test-Character $Collection $Code) {

                $Result.Latin = $true
                break
            }
        }

        # ----------------------------------------------------
        # Arabe
        # ----------------------------------------------------

        foreach ($Code in (0x0600..0x06FF)) {

            if (Test-Character $Collection $Code) {

                $Result.Arabe = $true
                break
            }
        }

        # ----------------------------------------------------
        # CJK chinois
        # ----------------------------------------------------

        foreach ($Code in (0x4E00..0x4EFF)) {

            if (Test-Character $Collection $Code) {

                $Result.CJK = $true
                break
            }
        }

        # ----------------------------------------------------
        # Japonais - Hiragana
        # ----------------------------------------------------

        foreach ($Code in (0x3040..0x309F)) {

            if (Test-Character $Collection $Code) {

                $Result.Japonais = $true
                break
            }
        }

        # ----------------------------------------------------
        # Japonais - Katakana
        # ----------------------------------------------------

        foreach ($Code in (0x30A0..0x30FF)) {

            if (Test-Character $Collection $Code) {

                $Result.Japonais = $true
                break
            }
        }

        # ----------------------------------------------------
        # Coréen
        # ----------------------------------------------------

        foreach ($Code in (0xAC00..0xD7AF)) {

            if (Test-Character $Collection $Code) {

                $Result.Coreen = $true
                break
            }
        }

        # ----------------------------------------------------
        # Cyrillique
        # ----------------------------------------------------

        foreach ($Code in (0x0400..0x04FF)) {

            if (Test-Character $Collection $Code) {

                $Result.Cyrillique = $true
                break
            }
        }

        # ----------------------------------------------------
        # Grec
        # ----------------------------------------------------

        foreach ($Code in (0x0370..0x03FF)) {

            if (Test-Character $Collection $Code) {

                $Result.Grec = $true
                break
            }
        }

    }
    catch {

        return $null
    }

    return [PSCustomObject]$Result
}

# ------------------------------------------------------------
# Recherche récursive
# ------------------------------------------------------------

$Fichiers = Get-ChildItem `
    -Path $Base `
    -Recurse `
    -File `
    -Include *.ttf,*.otf,*.ttc

Write-Host "Nombre de fichiers de police trouves : $($Fichiers.Count)"
Write-Host ""

# ------------------------------------------------------------
# Tableau du rapport
# ------------------------------------------------------------

$RapportData = @()

$Compteur = 0

# ------------------------------------------------------------
# Analyse des polices
# ------------------------------------------------------------

foreach ($Font in $Fichiers) {

    $Compteur++

    Write-Host "[$Compteur/$($Fichiers.Count)] $($Font.Name)"

    $Info = Get-FontLanguageInfo $Font.FullName

    if ($null -eq $Info) {

        Write-Host "    Impossible d'analyser la police."
        Write-Host ""

        $RapportData += [PSCustomObject]@{
            Fichier      = $Font.Name
            Latin        = "?"
            Arabe        = "?"
            CJK          = "?"
            Japonais     = "?"
            Coreen       = "?"
            Cyrillique   = "?"
            Grec         = "?"
            Action       = "ERREUR ANALYSE"
        }

        continue
    }

    # --------------------------------------------------------
    # Affichage des langues détectées
    # --------------------------------------------------------

    $Langues = @()

    if ($Info.Latin)      { $Langues += "Latin" }
    if ($Info.Arabe)      { $Langues += "Arabe" }
    if ($Info.CJK)        { $Langues += "CJK" }
    if ($Info.Japonais)   { $Langues += "Japonais" }
    if ($Info.Coreen)     { $Langues += "Coreen" }
    if ($Info.Cyrillique) { $Langues += "Cyrillique" }
    if ($Info.Grec)       { $Langues += "Grec" }

    if ($Langues.Count -eq 0) {
        $Langues = @("Inconnue")
    }

    Write-Host "    Langues : $($Langues -join ', ')"

    # --------------------------------------------------------
    # Si aucun Latin n'est présent
    # --------------------------------------------------------

    if (-not $Info.Latin) {

        Write-Host "    -> IGNORE : aucun caractere latin detecte."
        Write-Host ""

        $RapportData += [PSCustomObject]@{
            Fichier      = $Font.Name
            Latin        = $Info.Latin
            Arabe        = $Info.Arabe
            CJK          = $Info.CJK
            Japonais     = $Info.Japonais
            Coreen       = $Info.Coreen
            Cyrillique   = $Info.Cyrillique
            Grec         = $Info.Grec
            Action       = "IGNORE - PAS DE LATIN"
        }

        continue
    }

    # --------------------------------------------------------
    # Vérification du nom de famille
    # --------------------------------------------------------

    try {

        $Typeface = New-Object System.Windows.Media.GlyphTypeface(
            (New-Object System.Uri($Font.FullName))
        )

        $FamilyName = (
            $Typeface.Win32FamilyNames.Values |
            Select-Object -First 1
        )

    }
    catch {

        $FamilyName = [System.IO.Path]::GetFileNameWithoutExtension(
            $Font.Name
        )
    }

    if ([string]::IsNullOrWhiteSpace($FamilyName)) {

        $FamilyName = [System.IO.Path]::GetFileNameWithoutExtension(
            $Font.Name
        )
    }

    # --------------------------------------------------------
    # Vérification installation
    # --------------------------------------------------------

    if ($PolicesInstallees.ContainsKey($FamilyName.ToLower())) {

        Write-Host "    -> DEJA INSTALLEE : $FamilyName"
        Write-Host ""

        $RapportData += [PSCustomObject]@{
            Fichier      = $Font.Name
            Latin        = $Info.Latin
            Arabe        = $Info.Arabe
            CJK          = $Info.CJK
            Japonais     = $Info.Japonais
            Coreen       = $Info.Coreen
            Cyrillique   = $Info.Cyrillique
            Grec         = $Info.Grec
            Action       = "DEJA INSTALLEE"
        }

        continue
    }

    # --------------------------------------------------------
    # Installation
    # --------------------------------------------------------

    try {

        $Shell = New-Object -ComObject Shell.Application

        $FontsFolder = $Shell.Namespace(0x14)

        $FontsFolder.CopyHere(
            $Font.FullName,
            0x10 + 0x4
        )

        Write-Host "    -> INSTALLATION : $FamilyName"

        # On ajoute immédiatement au tableau pour éviter
        # plusieurs installations de la même famille
        $PolicesInstallees[$FamilyName.ToLower()] = $true

        $Action = "INSTALLEE"

    }
    catch {

        Write-Host "    -> ERREUR INSTALLATION"

        $Action = "ERREUR INSTALLATION"
    }

    Write-Host ""

    $RapportData += [PSCustomObject]@{
        Fichier      = $Font.Name
        Latin        = $Info.Latin
        Arabe        = $Info.Arabe
        CJK          = $Info.CJK
        Japonais     = $Info.Japonais
        Coreen       = $Info.Coreen
        Cyrillique   = $Info.Cyrillique
        Grec         = $Info.Grec
        Action       = $Action
    }
}

# ------------------------------------------------------------
# Sauvegarde du rapport
# ------------------------------------------------------------

$RapportData |
    Export-Csv `
        -Path $Rapport `
        -Encoding UTF8 `
        -NoTypeInformation

# ------------------------------------------------------------
# Résumé
# ------------------------------------------------------------

$Installees = @(
    $RapportData |
    Where-Object { $_.Action -eq "INSTALLEE" }
).Count

$DejaInstallees = @(
    $RapportData |
    Where-Object { $_.Action -eq "DEJA INSTALLEE" }
).Count

$Ignorees = @(
    $RapportData |
    Where-Object { $_.Action -eq "IGNORE - PAS DE LATIN" }
).Count

$Erreurs = @(
    $RapportData |
    Where-Object { $_.Action -like "ERREUR*" }
).Count

Write-Host ""
Write-Host "============================================================"
Write-Host "                       RESULTAT"
Write-Host "============================================================"
Write-Host ""
Write-Host "Polices trouvees       : $($Fichiers.Count)"
Write-Host "Polices installees     : $Installees"
Write-Host "Deja installees        : $DejaInstallees"
Write-Host "Polices ignorees       : $Ignorees"
Write-Host "Erreurs                : $Erreurs"
Write-Host ""
Write-Host "Rapport :"
Write-Host $Rapport
Write-Host ""
Write-Host "============================================================"