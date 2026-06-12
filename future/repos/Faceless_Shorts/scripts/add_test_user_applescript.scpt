-- Open Chrome to OAuth Audience page so Karl can add test user
-- Run: osascript scripts/add_test_user_applescript.scpt
tell application "Google Chrome" to activate
tell application "Google Chrome" to open location "https://console.cloud.google.com/auth/audience?project=coastal-sunspot-487703-p7"
-- Focus the new tab - user adds ob.hitting.3.tv@gmail.com as test user
