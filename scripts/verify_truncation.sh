#!/bin/bash
# Test script to verify truncation logging
echo "Starting log stream..."
/usr/bin/log stream --predicate 'subsystem == "com.markdownquicklook.app" AND category == "MarkdownPreview"' --style compact --timeout 10 > truncation_test.log &
LOG_PID=$!

echo "Waiting for log stream to attach..."
sleep 2

echo "Triggering QuickLook..."
# Run qlmanage in background, suppress stdout/stderr (it's noisy)
qlmanage -p large_test.md > /dev/null 2>&1 &
QL_PID=$!

echo "Waiting for preview generation..."
sleep 5

echo "Stopping QuickLook..."
kill $QL_PID 2>/dev/null

echo "Waiting for log stream to finish..."
wait $LOG_PID 2>/dev/null

echo "--- LOG OUTPUT ---"
cat truncation_test.log
