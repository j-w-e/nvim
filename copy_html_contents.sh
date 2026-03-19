#!/bin/zsh

# Step 1: Open HTML file in Safari
osascript <<EOF
tell application "Firefox"
    open location "file:///tmp/temp.html"
    activate
    delay 0.5 -- wait for the page to load
    tell application "System Events" to keystroke "a" using command down
    tell application "System Events" to keystroke "c" using command down
    delay 0.5 -- wait for clipboard action
    tell application "System Events" to keystroke "w" using command down
    tell application "System Events" to keystroke tab using command down
end tell
EOF

echo "Content copied to clipboard and browser closed."
