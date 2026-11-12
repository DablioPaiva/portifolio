# Busca-Cripto.ps1
# Procura INDICIOS de carteiras e softwares de criptomoedas no proprio computador.
# Nao le o conteudo de carteiras, nao acessa a internet e nao modifica arquivos encontrados.
# Windows 10 / Windows PowerShell 5.1+
# Uso:
#   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Busca-Cripto.ps1
#   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Busca-Cripto.ps1 -Completo
#   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Busca-Cripto.ps1 -Completo -VerZips

param(
    [switch]$Completo,
    [switch]$VerZips
)

$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'
$desktop = [Environment]::GetFolderPath('Desktop')
if (-not $desktop -or -not (Test-Path -LiteralPath $desktop)) { $desktop = $env:USERPROFILE }
$saida = Join-Path $desktop ('BuscaCripto-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path $saida -Force | Out-Null
$csv = Join-Path $saida 'resultados.csv'
$txt = Join-Path $saida 'resumo.txt'

$achados = New-Object 'System.Collections.Generic.List[object]'
$vistos = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
$forteNome = '(?i)(^wallet\.dat($|\.)|^wallet\.aes\.json$|^default_wallet$|\.wallet($|\.)|\.multibit$|^UTC--|^wallet\.keys$)'
$forteCaminho = '(?i)[\\/](electrum[\\/]wallets|ethereum[\\/]keystore|bitcoin[\\/]wallets|litecoin[\\/]wallets|monero[\\/]wallets)[\\/]'
$indicativo = '(?i)(bitcoin|litecoin|dogecoin|namecoin|peercoin|ppcoin|multibit|electrum|armory|blockchain\.info|bitaddress|cgminer|bfgminer|guiminer|poclbm|bitcoin-qt|monero|ethereum|exodus|cryptocurrency|criptomoed|wallet)'

function Registrar([string]$prioridade, [string]$tipo, [string]$caminho, [string]$observacao) {
    $chave = $tipo + '|' + $caminho
    if ($script:vistos.Add($chave)) {
        $script:achados.Add([pscustomobject]@{
            Prioridade = $prioridade
            Tipo = $tipo
            Caminho = $caminho
            Observacao = $observacao
        })
    }
}

if ($VerZips) {
    try { Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop } catch {
        Write-Warning 'Nao foi possivel ativar leitura de indices ZIP; os arquivos ZIP nao serao inspecionados.'
        $VerZips = $false
    }
}

function Inspecionar-Zip([string]$arquivo) {
    $zip = $null
    try {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($arquivo)
        foreach ($item in $zip.Entries) {
            $nome = ($item.FullName -split '[/\\]')[-1]
            if (-not $nome) { continue }
            if ($nome -match $script:forteNome -or $item.FullName -match $script:forteCaminho) {
                Registrar 'ALTA' 'Arquivo dentro de ZIP' ($arquivo + ' :: ' + $item.FullName) 'Apenas o nome do arquivo no ZIP foi verificado; nada foi extraido.'
            } elseif ($nome -match $script:indicativo) {
                Registrar 'MEDIA' 'Nome dentro de ZIP' ($arquivo + ' :: ' + $item.FullName) 'Apenas o nome do arquivo no ZIP foi verificado; nada foi extraido.'
            }
        }
    } catch {
        # ZIP protegido, danificado ou inacessivel: ignorar.
    } finally {
        if ($null -ne $zip) { $zip.Dispose() }
    }
}

function Examinar-Raiz([string]$raiz) {
    if (-not (Test-Path -LiteralPath $raiz -PathType Container)) { return }
    Write-Host ('Varrendo: ' + $raiz)
    $pilha = New-Object 'System.Collections.Generic.Stack[string]'
    $pilha.Push($raiz)
    $ignorar = @('Windows', 'Program Files', 'Program Files (x86)', '$Recycle.Bin',
                 'System Volume Information', 'node_modules', '.git')
    while ($pilha.Count -gt 0) {
        $pasta = $pilha.Pop()
        try { $itens = Get-ChildItem -LiteralPath $pasta -Force -ErrorAction Stop }
        catch { continue }
        foreach ($item in $itens) {
            if ($item.PSIsContainer) {
                # Evita loops com atalhos/junctions e pastas do sistema.
                if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { continue }
                if ($ignorar -contains $item.Name) { continue }
                $pilha.Push($item.FullName)
                continue
            }
            $nome = $item.Name
            if ($nome -match $script:forteNome -or $item.FullName -match $script:forteCaminho) {
                Registrar 'ALTA' 'Possivel arquivo de carteira' $item.FullName 'Investigar SEM abrir, alterar ou enviar este arquivo.'
            } elseif ($nome -match $script:indicativo) {
                Registrar 'MEDIA' 'Arquivo com nome relacionado' $item.FullName 'Pode ser programa, documento, backup ou falso positivo.'
            }
            if ($script:VerZips -and $item.Extension -ieq '.zip') {
                Inspecionar-Zip $item.FullName
            }
        }
    }
}

Write-Host '=== BUSCA LOCAL DE VESTIGIOS DE CRIPTOMOEDAS ===' -ForegroundColor Cyan
Write-Host 'Nao envia dados, nao abre conteudo de carteiras e nao altera arquivos.'

$unidades = @(Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty DeviceID)
if ($unidades.Count -eq 0) { $unidades = @($env:SystemDrive) }
$perfis = New-Object 'System.Collections.Generic.List[string]'
if ($env:USERPROFILE) { $perfis.Add($env:USERPROFILE) }
foreach ($unidade in $unidades) {
    $pastaUsuarios = Join-Path ($unidade + '\') 'Users'
    if (Test-Path -LiteralPath $pastaUsuarios -PathType Container) {
        foreach ($usuario in @(Get-ChildItem -LiteralPath $pastaUsuarios -Directory -Force -ErrorAction SilentlyContinue)) {
            $perfis.Add($usuario.FullName)
        }
    }
}
$perfis = @($perfis | Select-Object -Unique)

# Pastas usadas por carteiras antigas e atuais; nao e preciso executar nenhum programa.
$pastasConhecidas = @(
    'AppData\Roaming\Bitcoin', 'AppData\Roaming\Litecoin', 'AppData\Roaming\Dogecoin',
    'AppData\Roaming\Namecoin', 'AppData\Roaming\PPCoin', 'AppData\Roaming\Peercoin',
    'AppData\Roaming\Electrum', 'AppData\Roaming\MultiBit', 'AppData\Roaming\MultiBitHD',
    'AppData\Roaming\Armory', 'AppData\Roaming\Exodus', 'AppData\Roaming\Ethereum',
    'AppData\Roaming\DashCore', 'AppData\Roaming\Monero', 'AppData\Roaming\Zcash',
    'AppData\Local\Bitcoin', 'AppData\Local\MultiBit',
    '.bitcoin', '.electrum', '.multibit', '.litecoin', '.dogecoin',
    'Documents\MultiBit', 'Documents\Electrum', 'Documents\Bitcoin'
)
foreach ($perfil in $perfis) {
    foreach ($subpasta in $pastasConhecidas) {
        $local = Join-Path $perfil $subpasta
        if (Test-Path -LiteralPath $local -PathType Container) {
            Registrar 'MEDIA' 'Pasta conhecida de software cripto' $local 'A existencia da pasta nao comprova saldo ou carteira valida.'
        }
    }
}

# Programas que continuam registrados no Windows, mesmo sem arquivo de carteira identificado.
$chaves = @(
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
)
foreach ($chave in $chaves) {
    if (Test-Path -LiteralPath $chave) {
        foreach ($subchave in @(Get-ChildItem -LiteralPath $chave -ErrorAction SilentlyContinue)) {
            $programa = Get-ItemProperty -LiteralPath $subchave.PSPath -ErrorAction SilentlyContinue
            if ($programa.DisplayName -and $programa.DisplayName -match $indicativo) {
                Registrar 'MEDIA' 'Programa registrado no Windows' ([string]$programa.DisplayName) ('Chave: ' + $subchave.Name)
            }
        }
    }
}

$raizes = New-Object 'System.Collections.Generic.List[string]'
if ($Completo) {
    foreach ($unidade in $unidades) { $raizes.Add($unidade + '\') }
} else {
    foreach ($perfil in $perfis) { $raizes.Add($perfil) }
    if ($env:PROGRAMDATA) { $raizes.Add($env:PROGRAMDATA) }
    foreach ($unidade in $unidades) {
        $antigos = Join-Path ($unidade + '\') 'Windows.old\Users'
        if (Test-Path -LiteralPath $antigos -PathType Container) { $raizes.Add($antigos) }
    }
}
foreach ($raiz in @($raizes | Select-Object -Unique)) { Examinar-Raiz $raiz }

$ordenado = @($achados | Sort-Object @{ Expression = { if ($_.Prioridade -eq 'ALTA') { 0 } else { 1 } } }, Tipo, Caminho)
if ($ordenado.Count -gt 0) {
    $ordenado | Export-Csv -LiteralPath $csv -NoTypeInformation -Encoding UTF8
} else {
    'Nenhum indicio encontrado nesta varredura.' | Set-Content -LiteralPath $csv -Encoding UTF8
}
$alta = @($ordenado | Where-Object { $_.Prioridade -eq 'ALTA' }).Count
$media = @($ordenado | Where-Object { $_.Prioridade -eq 'MEDIA' }).Count
@(
    'BUSCA DE VESTIGIOS DE CRIPTOMOEDAS',
    ('Data: ' + (Get-Date -Format 'dd/MM/yyyy HH:mm:ss')),
    ('Modo: ' + $(if ($Completo) { 'Completo: unidades locais' } else { 'Rapido: usuarios e pastas de dados' })),
    ('Nomes internos de ZIP verificados: ' + $(if ($VerZips) { 'Sim' } else { 'Nao' })),
    ('Possiveis carteiras (ALTA): ' + $alta),
    ('Outros indicios (MEDIA): ' + $media),
    ('Relatorio: ' + $csv),
    '',
    'ALTA nao significa que haja saldo ou que o arquivo seja realmente uma carteira.',
    'Nenhum arquivo de carteira foi aberto, modificado ou enviado.',
    'Arquivos com nomes genericos, discos desconectados e ZIP/RAR/7z podem passar despercebidos.',
    'Se encontrar wallet.dat ou outro candidato, NAO abra com programas aleatorios. Faca copia segura primeiro.'
) | Set-Content -LiteralPath $txt -Encoding UTF8
Write-Host ''
Write-Host ('Concluido! Possiveis carteiras: ' + $alta + '; outros indicios: ' + $media) -ForegroundColor Green
Write-Host ('Relatorio CSV: ' + $csv)
Write-Host ('Resumo TXT: ' + $txt)
