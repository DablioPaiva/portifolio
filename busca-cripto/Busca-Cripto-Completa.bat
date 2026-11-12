@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Busca Cripto Completa - CMD - Windows 10
color 0A

rem Procura NOMES de arquivos e pastas relacionados a carteiras, sem abrir conteudo.
rem Nao usa PowerShell. Nao instala software. Nao transmite dados.
rem ATENCAO: a varredura completa pode ser demorada em discos antigos.

set "DESKTOP=%USERPROFILE%\Desktop"
if not exist "%DESKTOP%\" set "DESKTOP=%USERPROFILE%"
set "SAIDA=%DESKTOP%\BuscaCripto-Completa-%RANDOM%-%RANDOM%"
md "%SAIDA%" 2>nul
if not exist "%SAIDA%\" (
    echo Nao foi possivel criar a pasta de relatorio.
    echo Verifique acesso a Area de Trabalho e tente novamente.
    pause
    exit /b 1
)

set "TODOS=%SAIDA%\Todos_Indicios.txt"
set "ALTOS=%SAIDA%\Possiveis_Carteiras.txt"
set "PASTAS=%SAIDA%\Pastas_Conhecidas.txt"
set "RESUMO=%SAIDA%\Resumo.txt"
type nul > "%TODOS%"
type nul > "%ALTOS%"
type nul > "%PASTAS%"
set /a DISCOS=0

echo.
echo ========================================================
echo           BUSCA CRIPTO COMPLETA - CMD
echo ========================================================
echo Este arquivo procura nomes, nao le conteudo de carteiras.
echo Nao modifica suas carteiras e nao envia arquivos.
echo.
echo O computador pode ficar lento durante a busca.
echo Se o HD estiver com defeito ou fazendo barulhos estranhos,
echo interrompa e priorize um backup do HD.
echo.
echo Resultados em:
echo %SAIDA%
echo.

rem Procura nas unidades C: a Z: que estejam acessiveis.
rem O comando DIR inclui nomes de arquivos ocultos e de sistema.
rem Uma passada por unidade reduz leituras repetidas do disco.
for %%D in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%D:\" (
        set /a DISCOS+=1 >nul
        echo [VARRENDO] %%D:\ - pode demorar...
        >> "%TODOS%" echo ========= UNIDADE %%D: =========
        dir /s /b /a:-d "%%D:\*" 2>nul | findstr /I /L /C:"wallet" /C:"bitcoin" /C:"litecoin" /C:"dogecoin" /C:"namecoin" /C:"peercoin" /C:"multibit" /C:"electrum" /C:"armory" /C:"monero" /C:"ethereum" /C:"exodus" /C:"keystore" /C:"UTC--" /C:"cgminer" /C:"bfgminer" /C:"guiminer" /C:"poclbm" /C:"keys.dat" >> "%TODOS%"
        echo [CONCLUIDA] %%D:\
    )
)
echo.
echo Separando os achados por importancia...

rem Trata como fortes os padroes tipicos de arquivos reais de carteira.
rem Nem todo arquivo encontrado contem fundos.
findstr /I /L /C:"wallet.dat" /C:"default_wallet" /C:".wallet" /C:".multibit" /C:"wallet.aes.json" /C:"wallet.keys" /C:"\Electrum\wallets" /C:"\Ethereum\keystore" /C:"UTC--" "%TODOS%" > "%ALTOS%"

rem Verifica a EXISTENCIA de pastas historicas, mesmo que vazias
rem ou que os arquivos guardados nelas tenham nomes nao reconhecidos.
for %%D in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%D:\" (
        for %%U in ("%%D:\Users" "%%D:\Windows.old\Users" "%%D:\Documents and Settings") do (
            if exist "%%~U\" (
                for /d %%P in ("%%~U\*") do (
                    for %%K in (
                        "AppData\Roaming\Bitcoin"
                        "AppData\Roaming\Litecoin"
                        "AppData\Roaming\Dogecoin"
                        "AppData\Roaming\Namecoin"
                        "AppData\Roaming\Peercoin"
                        "AppData\Roaming\PPCoin"
                        "AppData\Roaming\MultiBit"
                        "AppData\Roaming\MultiBitHD"
                        "AppData\Roaming\Electrum"
                        "AppData\Roaming\Armory"
                        "AppData\Roaming\Ethereum"
                        "AppData\Roaming\Monero"
                        "AppData\Roaming\Exodus"
                        "AppData\Local\Bitcoin"
                        "Documents\MultiBit"
                        "Documents\Electrum"
                        "Documents\Bitcoin"
                        ".bitcoin"
                        ".electrum"
                        ".multibit"
                    ) do (
                        if exist "%%~fP\%%~K\" (
                            >> "%PASTAS%" echo %%~fP\%%~K
                        )
                    )
                )
            )
        )
    )
)

set "CONTATODOS=0"
set "CONTAALTOS=0"
set "CONTAPASTAS=0"
for /f %%N in ('find /v /c "" ^< "%TODOS%"') do set "CONTATODOS=%%N"
for /f %%N in ('find /v /c "" ^< "%ALTOS%"') do set "CONTAALTOS=%%N"
for /f %%N in ('find /v /c "" ^< "%PASTAS%"') do set "CONTAPASTAS=%%N"

(
    echo BUSCA CRIPTO COMPLETA - WINDOWS CMD
    echo Data: %DATE% %TIME%
    echo Unidades encontradas: %DISCOS%
    echo Entradas em todos os indicios: %CONTATODOS%
    echo Possiveis carteiras: %CONTAALTOS%
    echo Pastas historicas encontradas: %CONTAPASTAS%
    echo.
    echo Arquivos gerados:
    echo Possiveis_Carteiras.txt - maior prioridade
    echo Todos_Indicios.txt - nomes de arquivos relacionados
    echo Pastas_Conhecidas.txt - pastas historicas de programas
    echo.
    echo IMPORTANTE:
    echo - Busca nomes de arquivos e pastas, nao examina seu conteudo.
    echo - Nao procura entradas internas de ZIP, RAR ou 7z.
    echo - Nao recupera arquivos apagados ou sobrescritos.
    echo - Pastas sem acesso podem ser ignoradas pelo Windows.
    echo - Um achado nao comprova carteira valida ou saldo.
    echo - Nenhum achado nao comprova ausencia de carteira.
    echo - NUNCA compartilhe wallet.dat, senhas, seeds ou chaves privadas.
    echo - Compartilhe apenas o resumo, revisando nomes de usuarios e caminhos.
) > "%RESUMO%"

echo.
echo ========================================================
echo                     FINALIZADO
echo ========================================================
echo Possiveis carteiras: %CONTAALTOS%
echo Pastas historicas:   %CONTAPASTAS%
echo.
echo Abra a pasta na Area de Trabalho:
echo %SAIDA%
echo.
echo Leia primeiro Resumo.txt e Possiveis_Carteiras.txt
echo.
start "" explorer.exe "%SAIDA%" >nul 2>nul
echo Pressione qualquer tecla no teclado virtual para fechar.
pause >nul
endlocal
