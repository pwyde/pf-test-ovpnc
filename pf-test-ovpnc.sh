#!/usr/bin/env bash
 
_print_help() {
    echo "
Usage:
  ${0} --vpn-iface <interface> --vpn-id <id>
 
Description:
  A script for pfSense that restarts specified OpenVPN client connection if it
  appears to be down.
 
Options:
  -i, --vpn-iface    OpenVPN client interface, i.e. 'ovpnc1'. This can be
                     acquired with 'ifconfig'.
 
  -I, --vpn-id       OpenVPN client ID, i.e. '1'. This can be obtained from the
                     pfSense configuration file '/cf/conf/config.xml'.
" >&2
}
 
# Print help if no argument is specified.
if [[ "${#}" -le 0 ]]; then
    _print_help
    exit 1
fi
 
# Loop as long as there is at least one more argument.
while [[ "${#}" -gt 0 ]]; do
    key="${1}"
    case "${key}" in
        # This is an arg value type option. Will catch both '-i' or
        # '--vpn-iface' value.
        -i|--vpn-iface) shift; VPN_IFACE="${1}" ;;
        # This is an arg value type option. Will catch both '-I' or
        # '--vpn-id' value.
        -I|--vpn-id) shift; VPN_ID="${1}" ;;
        # This is an arg value type option. Will catch both '-h' or
        # '--help' value.
        -h|--help) print_help; exit ;;
        *) echo "Unknown argument '${key}'."; _print_help; exit 1 ;;
    esac
    # Shift after checking all the cases to get the next option.
    shift
done
 
VPN_INET="$(/sbin/ifconfig "${VPN_IFACE}" | /usr/bin/grep "inet")"
VPN_INET_IP="$(/sbin/ifconfig "${VPN_IFACE}" | awk '/inet / {print $2}')"
PF_CONF="/cf/conf/config.xml"
LOG_FILE="/var/log/pf-test-ovpnc.log"
HOST="$(/bin/hostname -s)"
TIMESTAMP="$(/bin/date +"%b  %d %T")"
LOGLINE="${TIMESTAMP} ${HOST} ${0}:"
 
_validate_script() {
    # Validate specified network interface.
    if /sbin/ifconfig "${VPN_IFACE}" > /dev/null 2>&1; then
        # Interface found.
        echo "${LOGLINE} INFO: Network interface '${VPN_IFACE}' found."
        echo "<100>${LOGLINE} INFO: Network interface '${VPN_IFACE}' found." >> "${LOG_FILE}"
    else
        echo "${LOGLINE} ERROR: Network interface '${VPN_IFACE}' does not exist."
        echo "<1>${LOGLINE} ERROR: Network interface '${VPN_IFACE}' does not exist." >> "${LOG_FILE}"
        exit 1
    fi
 
    # Validate OpenVPN client interface argument.
    if [[ -z "${VPN_IFACE}" ]]; then
        echo "${LOGLINE} ERROR: No OpenVPN client interface specified. Please use '-i' or see help '-h'."
        echo "<2>${LOGLINE} ERROR: No OpenVPN client interface specified. Please use '-i' or see help '-h'." >> "${LOG_FILE}"
        exit 1
    fi
 
    # Validate OpenVPN client ID argument.
    if [[ -z "${VPN_ID}" ]]; then
        echo "${LOGLINE} ERROR: No OpenVPN client ID specified. Please use '-I' or see help '-h'."
        echo "<3>${LOGLINE} ERROR: No OpenVPN client ID specified. Please use '-I' or see help '-h'." >> "${LOG_FILE}"
        exit 1
    fi
 
    # Validate pfSense configuration file.
    if [[ -e "${PF_CONF}" ]]; then
        echo "${LOGLINE} Located pfSense configuration file '${PF_CONF}'."
        echo "<101>${LOGLINE} INFO: Located pfSense configuration file '${PF_CONF}'." >> "${LOG_FILE}"
    else
        echo "${LOGLINE} ERROR: Could not locate pfSense configuration file '${PF_CONF}'."
        echo "<4>${LOGLINE} ERROR: Could not locate pfSense configuration file '${PF_CONF}'." >> "${LOG_FILE}"
        exit 1
    fi
 
    # Extract OpenVPN client information from pfSense configuratione file.
    VPNID="$(/usr/local/bin/xmllint --xpath "string(/pfsense/openvpn/openvpn-client/vpnid)" --nocdata "${PF_CONF}")"
    VPN_DESCR="$(/usr/local/bin/xmllint --xpath "string(/pfsense/openvpn/openvpn-client/description)" --nocdata "${PF_CONF}")"
 
    # Validate specified OpenVPN client ID.
    if [[ "${VPN_ID}" != "${VPNID}" ]]; then
        echo "${LOGLINE} ERROR: Specified OpenVPN client ID '${VPN_ID}' does not exist in pfSense configuration file '${PF_CONF}'."
        echo "<5>${LOGLINE} ERROR: Specified OpenVPN client ID '${VPN_ID}' does not exist in pfSense configuration file '${PF_CONF}'." >> "${LOG_FILE}"
        exit 1
    fi
 
    # If OpenVPN client connection has no description specified in configuration, give it a name.
    if [[ -z "${VPN_DESCR}" ]]; then
        VPN_DESCR="NAMELESS CONNECTION"
    fi
}
 
_test_openvpn_client_conn() {
    if [[ -z "${VPN_INET}" ]]; then
        echo "${LOGLINE} WARNING: Could not obtain inet address for OpenVPN client interface '${VPN_IFACE}'. Client connection '${VPN_DESCR}' appears to be down (vpnid: ${VPN_ID})."
        echo "<50>${LOGLINE} WARNING: Could not obtain inet address for OpenVPN client interface '${VPN_IFACE}'. Client connection '${VPN_DESCR}' appears to be down (vpnid: ${VPN_ID})." >> "${LOG_FILE}"
        echo "${LOGLINE} WARNING: Restarting OpenVPN client '${VPN_DESCR}' (vpnid: ${VPN_ID})."
        echo "<51>${LOGLINE} WARNING: Restarting OpenVPN client '${VPN_DESCR}' (vpnid: ${VPN_ID})." >> "${LOG_FILE}"
        echo "<?php include('openvpn.inc'); openvpn_restart_by_vpnid(client, ${VPN_ID});?>" | /usr/local/bin/php -q
    else
        echo "${LOGLINE} INFO: Obtained inet address for OpenVPN client interface '${VPN_IFACE}'. Client connection '${VPN_DESCR}' appears to be up (vpnid: ${VPN_ID})."
        echo "<102>${LOGLINE} INFO: Obtained inet address for OpenVPN client interface '${VPN_IFACE}'. Client connection '${VPN_DESCR}' appears to be up (vpnid: ${VPN_ID})." >> "${LOG_FILE}"
    fi
}
 
_test_internet_conn() {
    ping -oc 10 -S "${VPN_INET_IP}" 8.8.8.8 > /dev/null
    if [[ "${?}" -eq 0 ]]; then
        echo "${LOGLINE} INFO: PING test was successful. Internet connection appears to be functional."
        echo "<103>${LOGLINE} INFO: PING test was successful. Internet connection appears to be functional." >> "${LOG_FILE}"
    else
        echo "${LOGLINE} WARNING: PING test failed. Internet connection appears to be down."
        echo "<52>${LOGLINE} WARNING: PING test failed. Internet connection appears to be down." >> "${LOG_FILE}"
        echo "${LOGLINE} WARNING: Restarting OpenVPN client '${VPN_DESCR}' (vpnid: ${VPN_ID})."
        echo "<51>${LOGLINE} WARNING: Restarting OpenVPN client '${VPN_DESCR}' (vpnid: ${VPN_ID})." >> "${LOG_FILE}"
        echo "<?php include('openvpn.inc'); openvpn_restart_by_vpnid(client, ${VPN_ID});?>" | /usr/local/bin/php -q
    fi
}
 
_validate_script
_test_openvpn_client_conn
_test_internet_conn
exit 0

