@echo off
REM ============================================================
REM  Double-cliquez sur ce fichier pour ouvrir le tableau de
REM  bord Cafe-Cacao dans votre navigateur.
REM  Laissez la fenetre ouverte pendant l'utilisation ;
REM  fermez-la pour arreter l'application.
REM ============================================================
cd /d "%~dp0"

REM 1) On essaie Rscript s'il est dans le PATH
where Rscript >nul 2>nul
if %errorlevel%==0 (
  Rscript -e "shiny::runApp('app.R', launch.browser=TRUE)"
  goto :fin
)

REM 2) Sinon on cherche R dans son emplacement d'installation habituel
for /d %%D in ("C:\Program Files\R\R-*") do set "RPATH=%%D\bin\Rscript.exe"
if defined RPATH if exist "%RPATH%" (
  "%RPATH%" -e "shiny::runApp('app.R', launch.browser=TRUE)"
  goto :fin
)

echo.
echo  R est introuvable. Installez R depuis https://cran.r-project.org
echo  puis relancez ce fichier, ou ouvrez app.R dans RStudio.

:fin
pause
