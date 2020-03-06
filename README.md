# pf-test-ovpnc

## Description
A script for pfSense that restarts specified OpenVPN client connection if it appears to be down.

## Options
| **Option** | **Description** |
| --- | --- |
| `-i`, `--vpn-iface` | OpenVPN client interface, i.e. **ovpnc1**. This can be acquired with `ifconfig`. |
| `-I`, `--vpn-id`    | OpenVPN client ID, i.e. **1**. This can be obtained from the pfSense configuration file `/cf/conf/config.xml`. |

## Requirements
The script requires the **Bash** package and can be installed from the official [FreeBSD.org pkg mirror](https://pkg.freebsd.org/).

pfSense 2.4.x is based on FreeBSD 11.x. Hence the correct version and architecture must be selected on the FreeBSD pkg mirror. To view all current and native packages for FreeBSD 11.x go to http://pkg.freebsd.org/FreeBSD:11:amd64/latest/All/.

Download and install Bash with command below.

```
# pkg add http://pkg.freebsd.org/FreeBSD:11:amd64/latest/All/bash-4.4.19.txz
```

## Install Instructions
Install the **cron** package in **System** > **Package Manager** > **Available Packages** > **Cron** > **Install**.

Configure a new cron job in **Services** > **Cron** > **Add** > set the options below.

| **Field**             | **Value** |
| --- | --- |
| **Minute**            | `*/15`    |
| **Hour**              | `*`       |
| **Day of the Month**  | `*`       |
| **Month of the Year** | `*`       |
| **Day of the Week**   | `*`       |
| **User**              | `root`    |
| **Command**           | `/usr/local/bin/bash /usr/local/bin/pf-test-ovpnc.sh –vpn-iface ovpnc1 –vpn-id 1 > /dev/null 2>&1 >/dev/null 2>&1` |

The following entry will be added to the root user **crontab**; `/etc/crontab`.

```
*/15 * * * * /usr/local/bin/bash /usr/local/bin/pf-test-ovpnc.sh --vpn-iface ovpnc1 --vpn-id 1 > /dev/null 2>&1
```

## Logging Capabilities
Script logs all events to **stdout** and `/var/log/pf-test-ovpnc.log` which is in syslog format (sort of). It is therefore possible to use it with a log collector or log management platform such as [Graylog](https://www.graylog.org/).

**Example 1:**
```
<100>Dec  12 23:00:00 fw /usr/local/bin/pf-test-ovpnc.sh: INFO: Network interface 'ovpnc1' found.
<101>Dec  12 23:00:00 fw /usr/local/bin/pf-test-ovpnc.sh: INFO: Located pfSense configuration file '/cf/conf/config.xml'.
<102>Dec  12 23:00:00 fw /usr/local/bin/pf-test-ovpnc.sh: INFO: Obtained inet address for OpenVPN client interface 'ovpnc1'. Client connection 'PIA' appears to be up (vpnid: 1).
<103>Dec  12 23:00:00 fw /usr/local/bin/pf-test-ovpnc.sh: INFO: PING test was successful. Internet connection appears to be functional.
```

**Example 2:**
```
<100>Dec  12 22:05:48 fw pf-test-ovpnc.sh: INFO: Network interface 'ovpnc1' found.
<101>Dec  12 22:05:48 fw pf-test-ovpnc.sh: INFO: Located pfSense configuration file '/cf/conf/config.xml'.
<102>Dec  12 22:05:48 fw pf-test-ovpnc.sh: INFO: Obtained inet address for OpenVPN client interface 'ovpnc1'. Client connection 'PIA' appears to be up (vpnid: 1).
<52>Dec  12 22:05:48 fw pf-test-ovpnc.sh: WARNING: PING test failed. Internet connection appears to be down.
<51>Dec  12 22:05:48 fw pf-test-ovpnc.sh: WARNING: Restarting OpenVPN client 'PIA' (vpnid: 1).
```

## License
This project is licensed under the **GNU General Public License v3.0**. See the [LICENSE](LICENSE) file for more information.
