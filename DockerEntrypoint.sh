#!/bin/sh

# Start fail2ban
[ $XUI_ENABLE_FAIL2BAN == "true" ] && fail2ban-client -x start

# Run YOUNGSCOOLPLAY-UI
exec /app/YOUNGSCOOLPLAY-UI
