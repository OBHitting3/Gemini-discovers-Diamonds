#!/bin/bash
# Start Chrome with remote debugging so add_test_user.py can use your existing session.
# Quit Chrome first, then run this. Keep this terminal open; run add_test_user.py in another terminal.
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9222
