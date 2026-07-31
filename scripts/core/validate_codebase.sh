#!/bin/bash
# Quickshell Notch Codebase Validation Pipeline
# Run this script to catch syntax errors before reloading the live daemon.

DIR="$HOME/.config/quickshell"
EXIT_CODE=0

echo "======================================"
echo " Starting Codebase Validation Pipeline"
echo "======================================"

echo -ne "[1/3] Validating QML Syntax (qmllint)... "
QML_FAILS=0
while IFS= read -r file; do
    if ! qmllint "$file" > /dev/null 2>&1; then
        echo -e "\n  ❌ Failed: $file"
        qmllint "$file"
        QML_FAILS=$((QML_FAILS + 1))
    fi
done < <(find "$DIR" -name "*.qml" ! -name "scratch_*" ! -name "test_*")

if [ $QML_FAILS -eq 0 ]; then
    echo "✅ Passed"
else
    EXIT_CODE=1
fi

echo -ne "[2/3] Compiling Python Backend... "
PY_FAILS=0
while IFS= read -r file; do
    if ! python3 -m py_compile "$file" > /dev/null 2>&1; then
        echo -e "\n  ❌ Failed: $file"
        python3 -m py_compile "$file"
        PY_FAILS=$((PY_FAILS + 1))
    fi
done < <(find "$DIR/scripts" -name "*.py")

if [ $PY_FAILS -eq 0 ]; then
    echo "✅ Passed"
else
    EXIT_CODE=1
fi

echo -ne "[3/3] Validating Bash AST... "
SH_FAILS=0
while IFS= read -r file; do
    if ! bash -n "$file" > /dev/null 2>&1; then
        echo -e "\n  ❌ Failed: $file"
        bash -n "$file"
        SH_FAILS=$((SH_FAILS + 1))
    fi
done < <(find "$DIR/scripts" -name "*.sh")

if [ $SH_FAILS -eq 0 ]; then
    echo "✅ Passed"
else
    EXIT_CODE=1
fi

echo "======================================"
if [ $EXIT_CODE -eq 0 ]; then
    echo "🚀 Success! Codebase is 100% valid."
else
    echo "🚨 Error: Validation failed. Do not reload the daemon."
fi

exit $EXIT_CODE
