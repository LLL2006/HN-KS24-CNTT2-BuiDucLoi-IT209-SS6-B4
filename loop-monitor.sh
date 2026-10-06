#!/bin/bash

# Script giam sat ghi thoi gian he thong vao file log
# File luu log: /tmp/monitor.log
# Chu ky: 5 giay / lan

echo "=== Bat dau khao sat monitor: $(date) ===" >> /tmp/monitor.log

while true; do
    echo "System time: $(date)" >> /tmp/monitor.log
    sleep 5
done
