#!/bin/bash

PATH=/usr/local/bin:/usr/local/sbin:/opt/local/bin:/usr/bin:/usr/sbin:/bin:/sbin
SHELL=/bin/bash

local_ip_rg() {
  if [ -e "/root/.local.IP.list" ]; then
    echo "the file /root/.local.IP.list already exists"
    for _IP in `hostname -I`; do
      _IP_CHECK=$(cat /root/.local.IP.list \
        | cut -d '#' -f1 \
        | sort \
        | uniq \
        | tr -d "\s" \
        | grep ${_IP} 2>&1)
      if [ -z ${_IP_CHECK} ]; then
        echo "${_IP} not yet listed in /root/.local.IP.list"
        echo "${_IP} # local IP address" >> /root/.local.IP.list
      else
        echo "${_IP} already listed in /root/.local.IP.list"
      fi
    done
    for _IP in `cat /root/.local.IP.list \
      | cut -d '#' -f1 \
      | sort \
      | uniq \
      | tr -d "\s"`; do
      echo removing ${_IP} from firewall rules
      csf -ar ${_IP} &> /dev/null
      csf -dr ${_IP} &> /dev/null
      csf -tr ${_IP} &> /dev/null
      echo removing ${_IP} from csf.ignore
      sed -i "s/^${_IP} .*//g" /etc/csf/csf.ignore
      wait
      echo removing ${_IP} from csf.allow
      sed -i "s/^${_IP} .*//g" /etc/csf/csf.allow
      wait
    done
  else
    echo "the file /root/.local.IP.list does not exist"
    rm -f /root/.tmp.IP.list*
    rm -f /root/.local.IP.list*
    for _IP in `hostname -I`;do echo ${_IP} >> /root/.tmp.IP.list;done
    for _IP in `cat /root/.tmp.IP.list \
      | sort \
      | uniq`;do echo "${_IP} # local IP address" >> /root/.local.IP.list;done
    rm -f /root/.tmp.IP.list*
  fi
  sed -i "/^$/d" /etc/csf/csf.ignore &> /dev/null
  wait
  sed -i "/^$/d" /etc/csf/csf.allow &> /dev/null
  wait
}

guard_stats() {
  if [ -e "${_HA}" ]; then
    for _IP in `cat ${_HA} | cut -d '#' -f1 | sort | uniq`; do
      _NR_TEST="0"
      _NR_TEST=$(tr -s ' ' '\n' < ${_HA} | grep -c ${_IP} 2>&1)
      if [ -e "/root/.local.IP.list" ]; then
        _IP_CHECK=$(cat /root/.local.IP.list \
          | cut -d '#' -f1 \
          | sort \
          | uniq \
          | tr -d "\s" \
          | grep ${_IP} 2>&1)
        if [ ! -z ${_IP_CHECK} ]; then
          _NR_TEST="0"
          echo "${_IP} is a local IP address, ignoring ${_HA}"
        fi
      fi
      if [ ! -z ${_NR_TEST} ] && [ ${_NR_TEST} -ge "24" ]; then
        echo ${_IP} ${_NR_TEST}
        _FW_TEST=$(csf -g ${_IP} 2>&1)
        if [[ "${_FW_TEST}" =~ "DENY" ]] || [[ "${_FW_TEST}" =~ "ALLOW" ]]; then
          echo "${_IP} already denied or allowed on port 22"
        else
          if [ ${_NR_TEST} -ge "64" ]; then
            echo "Deny ${_IP} permanently ${_NR_TEST}"
            csf -d ${_IP} do not delete Brute force SSH Server ${_NR_TEST} attacks
          else
            echo "Deny ${_IP} until limits rotation ${_NR_TEST}"
            csf -d ${_IP} Brute force SSH Server ${_NR_TEST} attacks
          fi
        fi
      fi
    done
  fi
  if [ -e "${_WA}" ]; then
    for _IP in `cat ${_WA} | cut -d '#' -f1 | sort | uniq`; do
      _NR_TEST="0"
      _NR_TEST=$(tr -s ' ' '\n' < ${_WA} | grep -c ${_IP} 2>&1)
      # _CF_TEST=
      # _CF_TEST=$(whois ${_IP} | grep cloudflare.com 2>&1)
      # if [[ "${_CF_TEST}" =~ "cloudflare" ]]; then
      #   _NR_TEST="0"
      #   echo "${_IP} is a cloudflare IP address, ignoring ${_HA}"
      # fi
      # _SC_TEST=
      # _SC_TEST=$(whois ${_IP} | grep sucuri.net 2>&1)
      # if [[ "${_SC_TEST}" =~ "sucuri" ]]; then
      #   _NR_TEST="0"
      #   echo "${_IP} is a sucuri IP address, ignoring ${_HA}"
      # fi
      if [ -e "/root/.local.IP.list" ]; then
        _IP_CHECK=$(cat /root/.local.IP.list \
          | cut -d '#' -f1 \
          | sort \
          | uniq \
          | tr -d "\s" \
          | grep ${_IP} 2>&1)
        if [ ! -z ${_IP_CHECK} ]; then
          _NR_TEST="0"
          echo "${_IP} is a local IP address, ignoring ${_WA}"
        fi
      fi
      if [ ! -z ${_NR_TEST} ] && [ ${_NR_TEST} -ge "24" ]; then
        echo ${_IP} ${_NR_TEST}
        _FW_TEST=$(csf -g ${_IP} 2>&1)
        if [[ "${_FW_TEST}" =~ "DENY" ]] || [[ "${_FW_TEST}" =~ "ALLOW" ]]; then
          echo "${_IP} already denied or allowed on port 80"
        else
          if [ ${_NR_TEST} -ge "64" ]; then
            echo "Deny ${_IP} permanently ${_NR_TEST}"
            csf -d ${_IP} do not delete Brute force Web Server ${_NR_TEST} attacks
          else
            echo "Deny ${_IP} until limits rotation ${_NR_TEST}"
            csf -d ${_IP} Brute force Web Server ${_NR_TEST} attacks
          fi
        fi
      fi
    done
  fi
  if [ -e "$_FA" ]; then
    for _IP in `cat $_FA | cut -d '#' -f1 | sort | uniq`; do
      _NR_TEST="0"
      _NR_TEST=$(tr -s ' ' '\n' < $_FA | grep -c ${_IP} 2>&1)
      if [ -e "/root/.local.IP.list" ]; then
        _IP_CHECK=$(cat /root/.local.IP.list \
          | cut -d '#' -f1 \
          | sort \
          | uniq \
          | tr -d "\s" \
          | grep ${_IP} 2>&1)
        if [ ! -z ${_IP_CHECK} ]; then
          _NR_TEST="0"
          echo "${_IP} is a local IP address, ignoring $_FA"
        fi
      fi
      if [ ! -z ${_NR_TEST} ] && [ ${_NR_TEST} -ge "24" ]; then
        echo ${_IP} ${_NR_TEST}
        _FW_TEST=$(csf -g ${_IP} 2>&1)
        if [[ "${_FW_TEST}" =~ "DENY" ]] || [[ "${_FW_TEST}" =~ "ALLOW" ]]; then
          echo "${_IP} already denied or allowed on port 21"
        else
          if [ ${_NR_TEST} -ge "64" ]; then
            echo "Deny ${_IP} permanently ${_NR_TEST}"
            csf -d ${_IP} do not delete Brute force FTP Server ${_NR_TEST} attacks
          else
            echo "Deny ${_IP} until limits rotation ${_NR_TEST}"
            csf -d ${_IP} Brute force FTP Server ${_NR_TEST} attacks
          fi
        fi
      fi
    done
  fi
}

if [ -e "/etc/csf/csf.deny" ] && [ -e "/usr/sbin/csf" ]; then
  if [ -e "/root/.local.IP.list" ]; then
    for _IP in `cat /root/.local.IP.list \
      | cut -d '#' -f1 \
      | sort \
      | uniq \
      | tr -d "\s"`; do
      csf -dr ${_IP} &> /dev/null
      csf -tr ${_IP} &> /dev/null
    done
  fi
  sed -i "s/param db_port.*/param db_port   3306;/g" \
    /data/disk/*/config/server_*/nginx/vhost.d/* &> /dev/null
  wait
  n=$((RANDOM%900+80))
  echo Waiting $n seconds...
  sleep $n
  touch /var/run/water.pid
  sleep 10
  local_ip_rg
  _HA=/var/xdrago/monitor/hackcheck.archive.log
  _WA=/var/xdrago/monitor/scan_nginx.archive.log
  _FA=/var/xdrago/monitor/hackftp.archive.log
  guard_stats
  rm -f /var/xdrago/monitor/ssh.log
  rm -f /var/xdrago/monitor/web.log
  rm -f /var/xdrago/monitor/ftp.log
  ntpdate pool.ntp.org
  csf -e
  csf -q
  rm -f /var/run/water.pid
else
  if [ -e "/root/.mstr.clstr.cnf" ] \
    || [ -e "/root/.wbhd.clstr.cnf" ] \
    || [ -e "/root/.dbhd.clstr.cnf" ]; then
    ntpdate pool.ntp.org
  fi
fi
exit 0
###EOF2016###
