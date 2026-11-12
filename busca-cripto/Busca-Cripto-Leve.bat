@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Busca Cripto Leve - Windows 10
color 0A
set "OUTDIR=%USERPROFILE%\Desktop"
if not exist "%OUTDIR%\" set "OUTDIR=%USERPROFILE%"
set "REL=%OUTDIR%\Busca-Cripto-Leve-%RANDOM%.txt"
> "%REL%" echo BUSCA LOCAL DE VESTIGIOS DE CRIPTOMOEDAS
>> "%REL%" echo Data: %DATE% %TIME%
>> "%REL%" echo Modo: leve - pastas comuns, sem ler conteudo
>> "%REL%" echo.
echo ========================================
echo  BUSCA CRIPTO LEVE - SEM POWERSHELL
echo ========================================
echo.
echo  Procurando indicios em pastas comuns...
echo  Relatorio: %REL%
echo.
set /a CONT=0
for %%P in (
    "%APPDATA%\Bitcoin"
    "%APPDATA%\Litecoin"
    "%APPDATA%\Dogecoin"
    "%APPDATA%\Namecoin"
    "%APPDATA%\PPCoin"
    "%APPDATA%\Peercoin"
    "%APPDATA%\Electrum"
    "%APPDATA%\MultiBit"
    "%APPDATA%\MultiBitHD"
    "%APPDATA%\Armory"
    "%APPDATA%\Ethereum"
    "%APPDATA%\Exodus"
    "%APPDATA%\Monero"
    "%APPDATA%\DashCore"
    "%LOCALAPPDATA%\Bitcoin"
    "%LOCALAPPDATA%\MultiBit"
    "%USERPROFILE%\Documents\MultiBit"
    "%USERPROFILE%\Documents\Electrum"
    "%USERPROFILE%\Documents\Bitcoin"
    "%USERPROFILE%\.bitcoin"
    "%USERPROFILE%\.electrum"
    "%USERPROFILE%\.multibit"
) do (
    if exist "%%~P\" (
        echo [PASTA] %%~P
        >> "%REL%" echo [PASTA CONHECIDA] %%~P
        set /a CONT+=1
    )
)
echo.
echo  Procurando arquivos de carteira...
for %%P in (
    "%APPDATA%\Bitcoin"
    "%APPDATA%\Litecoin"
    "%APPDATA%\Dogecoin"
    "%APPDATA%\Namecoin"
    "%APPDATA%\PPCoin"
    "%APPDATA%\Peercoin"
    "%APPDATA%\Electrum"
    "%APPDATA%\MultiBit"
    "%APPDATA%\MultiBitHD"
    "%APPDATA%\Armory"
    "%APPDATA%\Ethereum"
    "%APPDATA%\Exodus"
    "%APPDATA%\Monero"
    "%APPDATA%\DashCore"
    "%LOCALAPPDATA%\Bitcoin"
    "%LOCALAPPDATA%\MultiBit"
    "%USERPROFILE%\Documents"
    "%USERPROFILE%\Downloads"
    "%USERPROFILE%\Desktop"
) do (
    if exist "%%~P\" (
        echo  Lendo nomes em %%~P
        for %%N in ("wallet.dat" "default_wallet" "*.wallet" "*.multibit" "wallet.aes.json" "wallet.keys" "UTC--*") do (
            for /f "delims=" %%F in ('dir /s /b /a-d "%%~P\%%~N" 2^>nul') do (
                echo [POSSIVEL CARTEIRA] %%F
                >> "%REL%" echo [POSSIVEL CARTEIRA] %%F
                set /a CONT+=1
            )
        )
    )
)
echo.
>> "%REL%" echo.
>> "%REL%" echo OBSERVACOES:
>> "%REL%" echo Este programa apenas busca nomes e pastas; nao abre carteiras.
>> "%REL%" echo Um resultado nao comprova saldo nem posse de criptomoeda.
>> "%REL%" echo Sem resultados nao significa que nao exista carteira.
>> "%REL%" echo Nunca envie arquivos de carteira, seeds, senhas ou chaves privadas.
echo ========================================
echo  CONCLUIDO: %CONT% indicios
echo  Veja o arquivo na Area de Trabalho:
echo  %REL%
echo ========================================
echo.
echo  Clique no X da janela para fechar.
pause >nul
