#!/bin/sh
rc-status -a >/dev/null 2>&1
echo "Service 'RSYSLOG': Starting..."
rc-service rsyslog start >/dev/null 2>&1
echo "Service 'SSHD': Starting..."
rc-service sshd start >/dev/null 2>&1
echo "Service 'FAIL2BAN': Starting..."
rc-service fail2ban start >/dev/null 2>&1
echo "Socat : 0.0.0.0:${FAIL2BAN_SOCAT_PORT} -> ${FAIL2BAN_SOCKET_FILE}"
socat TCP-LISTEN:"${FAIL2BAN_SOCAT_PORT}",reuseaddr,fork UNIX-CONNECT:"${FAIL2BAN_SOCKET_FILE}"
