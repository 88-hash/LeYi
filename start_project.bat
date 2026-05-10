@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

set "ROOT=%~dp0"
set "JAVA_HOME=D:\program tool\java\jdk"
set "PATH=%JAVA_HOME%\bin;%PATH%"
set "MAVEN_CMD=C:\Users\lmc\Desktop\apache-maven-3.9.12\bin\mvn.cmd"
if not exist "%MAVEN_CMD%" set "MAVEN_CMD=%ROOT%.tools\apache-maven-3.9.6\bin\mvn.cmd"

echo ==========================================
echo       Leyi Snack Shop - Start Script
echo ==========================================

if not exist "%JAVA_HOME%\bin\java.exe" (
  echo [ERROR] JAVA_HOME is invalid: %JAVA_HOME%
  pause
  exit /b 1
)

if not exist "%MAVEN_CMD%" (
  echo [ERROR] Maven not found. Expected:
  echo         %MAVEN_CMD%
  pause
  exit /b 1
)

call :stop_port 8080
call :stop_port 3000
call :stop_port 3001

echo [1/4] Building Backend...
call "%MAVEN_CMD%" -f "%ROOT%backend\pom.xml" clean package -DskipTests
if errorlevel 1 (
  echo [ERROR] Backend build failed. Startup aborted.
  pause
  exit /b 1
)

:: 2. Start Backend
echo [2/4] Starting Backend...
start "Leyi Backend" cmd /k "cd /d ""%ROOT%backend"" && set JAVA_HOME=%JAVA_HOME%&& set PATH=%JAVA_HOME%\bin;%PATH%&& java -jar target\leyi-snack-1.0.0.jar"

:: 3. Start Admin Frontend
echo [3/4] Starting Admin Frontend...
if not exist "%ROOT%frontend-admin\node_modules" (
  echo [INFO] frontend-admin dependencies missing, installing...
  call cmd /c "cd /d ""%ROOT%frontend-admin"" && npm install"
  if errorlevel 1 (
    echo [ERROR] frontend-admin dependency install failed.
    pause
    exit /b 1
  )
)
start "Leyi Admin" cmd /k "cd /d ""%ROOT%frontend-admin"" && npm run dev"

:: 4. Start Customer Frontend
echo [4/4] Starting Customer Frontend...
if not exist "%ROOT%frontend-customer\node_modules" (
  echo [INFO] frontend-customer dependencies missing, installing...
  call cmd /c "cd /d ""%ROOT%frontend-customer"" && npm install"
  if errorlevel 1 (
    echo [ERROR] frontend-customer dependency install failed.
    pause
    exit /b 1
  )
)
start "Leyi Customer" cmd /k "cd /d ""%ROOT%frontend-customer"" && npm run dev"

echo.
echo All services started in background windows.
echo Waiting 15 seconds for services to initialize...
echo.

:: Wait for services
timeout /t 15 >nul

echo [5/5] Opening Browser...
start http://localhost:3000/login
start http://localhost:3001/login

echo.
echo ==========================================
echo          Done! Please check browser.
echo      (Do NOT close the popped up windows)
echo ==========================================
pause
exit /b 0

:stop_port
for /f "tokens=5" %%P in ('netstat -ano ^| findstr /R /C:":%~1 .*LISTENING"') do (
  echo [INFO] Stopping process %%P on port %~1...
  taskkill /F /PID %%P >nul 2>&1
)
exit /b 0
