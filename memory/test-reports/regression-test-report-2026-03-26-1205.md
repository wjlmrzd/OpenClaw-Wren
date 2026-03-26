# Regression Test Report
Generated: 2026-03-26 12:05:00

## Summary
- Total Tests: 5
- Passed: 4
- Failed: 1

## Results

**✅ T001 - JSON Syntax Validation**: PASS
- Details: All JSON files parsed successfully

**✅ T002 - Model Name Validation**: PASS
- Details: All model names are valid

**✅ T003 - Cron Expression Validation**: PASS
- Details: All cron expressions are valid

**❌ T004 - Gateway Health Check**: FAIL
- Details: Gateway response too slow: 6000ms (>5000ms) 

**✅ T005 - PowerShell Syntax Check**: PASS
- Details: All PowerShell scripts have valid syntax