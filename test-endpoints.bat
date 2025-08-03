@echo off
REM BMI Chat Endpoint Testing Script for Windows
REM Tests all API endpoints to ensure they work correctly

setlocal enabledelayedexpansion

echo [INFO] BMI Chat Endpoint Testing Script

REM Configuration
set BASE_URL=http://localhost:3006
set API_URL=%BASE_URL%/api/v1

REM Test counter
set TESTS_PASSED=0
set TESTS_FAILED=0

REM Function to run a test
:run_test
set test_name=%~1
set method=%~2
set endpoint=%~3
set data=%~4
set expected_status=%~5

echo [INFO] Testing: %test_name%

REM Build curl command
set curl_cmd=curl -s -w "%%{http_code}" -o temp_response.json

if "%method%"=="GET" (
    set curl_cmd=%curl_cmd% -X GET
) else if "%method%"=="POST" (
    set curl_cmd=%curl_cmd% -X POST
) else if "%method%"=="PUT" (
    set curl_cmd=%curl_cmd% -X PUT
) else if "%method%"=="DELETE" (
    set curl_cmd=%curl_cmd% -X DELETE
)

if not "%data%"=="" (
    set curl_cmd=%curl_cmd% -H "Content-Type: application/json" -d "%data%"
)

set curl_cmd=%curl_cmd% "%endpoint%"

REM Run the test
for /f %%i in ('%curl_cmd%') do set status_code=%%i
set response_body=
if exist temp_response.json (
    set /p response_body=<temp_response.json
    del temp_response.json
)

REM Check if test passed
if "%status_code%"=="%expected_status%" (
    echo [SUCCESS] %test_name% - Status: %status_code%
    set /a TESTS_PASSED+=1
) else (
    echo [ERROR] %test_name% - Expected: %expected_status%, Got: %status_code%
    echo [ERROR] Response: %response_body%
    set /a TESTS_FAILED+=1
)

echo.
goto :eof

REM Wait for backend to be ready
echo [INFO] Waiting for backend to be ready...
for /l %%i in (1,1,30) do (
    curl -f "%BASE_URL%/health" >nul 2>&1
    if !errorlevel! equ 0 (
        echo [SUCCESS] Backend is ready!
        goto :start_tests
    )
    timeout /t 1 /nobreak >nul
)
echo [ERROR] Backend is not responding after 30 seconds
pause
exit /b 1

:start_tests
echo [INFO] Starting endpoint tests...
echo.

REM Test 1: Health Check
call :run_test "Health Check" "GET" "%BASE_URL%/health" "" "200"

REM Test 2: API Root
call :run_test "API Root" "GET" "%API_URL%/" "" "200"

REM Test 3: Chat Endpoints
call :run_test "Chat History" "GET" "%API_URL%/chat/history" "" "200"
call :run_test "Chat Send Message" "POST" "%API_URL%/chat/send" "{\"message\":\"Hello, how are you?\"}" "200"

REM Test 4: Document Endpoints
call :run_test "Documents List" "GET" "%API_URL%/documents" "" "200"
call :run_test "Documents Upload Info" "GET" "%API_URL%/documents/upload-info" "" "200"

REM Test 5: Search Endpoints
call :run_test "Search Documents" "POST" "%API_URL%/search" "{\"query\":\"test query\"}" "200"

REM Test 6: Widget Endpoints
call :run_test "Widget Config" "GET" "%API_URL%/widget/config/1" "" "200"
call :run_test "Widget Health" "GET" "%API_URL%/widget/health/1" "" "200"
call :run_test "Widget Chat" "POST" "%API_URL%/widget/chat" "{\"tenant_id\":1,\"session_id\":\"test-session\",\"question\":\"Hello\"}" "200"

REM Test 7: Analytics Endpoints
call :run_test "Analytics Overview" "GET" "%API_URL%/analytics/overview" "" "200"
call :run_test "Analytics Usage" "GET" "%API_URL%/analytics/usage" "" "200"

REM Test 8: Admin Endpoints (if available)
call :run_test "Admin Settings" "GET" "%API_URL%/admin/settings" "" "200"

REM Test 9: Error handling
call :run_test "404 Not Found" "GET" "%API_URL%/nonexistent" "" "404"

REM Test 10: CORS (if applicable)
call :run_test "CORS Preflight" "OPTIONS" "%API_URL%/chat/send" "" "200"

REM Summary
echo ==========================================
echo [INFO] Test Summary:
echo   Tests Passed: %TESTS_PASSED%
echo   Tests Failed: %TESTS_FAILED%
set /a TOTAL_TESTS=%TESTS_PASSED%+%TESTS_FAILED%
echo   Total Tests: %TOTAL_TESTS%
echo ==========================================

if %TESTS_FAILED% equ 0 (
    echo [SUCCESS] All tests passed! 🎉
    exit /b 0
) else (
    echo [ERROR] %TESTS_FAILED% tests failed!
    exit /b 1
) 