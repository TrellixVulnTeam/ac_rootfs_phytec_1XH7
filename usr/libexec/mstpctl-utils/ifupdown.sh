#!/bin/sh

# This script should be symlinked into /etc/network/ip-pre-up.d/ and
# /etc/network/ip-post-down.d/ so that it will be run by ifupdown when
# configuring network interfaces.
#
# Have a look at /usr/share/doc/bridge-utils/README.Debian if you want
# more info about the way in which bridges are set up on Debian.
#
# Author: Satish Ashok, <sashok@cumulusnetworks.com>

mstpctl='/sbin/mstpctl'
if [ ! -x "$mstpctl" ]; then
  exit 0
fi
brctl="$(which brctl)"
if [ -z "$brctl" ] || [ ! -x "$brctl" ]; then
  echo "'brctl' binary does not exist or is not executable" >&2
  exit 2
fi
ip="$(which ip)"
if [ -z "$ip" ] || [ ! -x "$ip" ]; then
  echo "'ip' binary does not exist or is not executable" >&2
  exit 2
fi

# shellcheck disable=SC1091
. '/usr/libexec/mstpctl-utils/mstpctl-utils-functions.sh' || exit 2

case "$IF_MSTPCTL_PORTS" in
    '')
	exit 0
	;;
    none)
	INTERFACES=''
	;;
    *)
	INTERFACES="$IF_MSTPCTL_PORTS"
	;;
esac

# Previous work (create the interface)
if [ "$MODE" = 'start' ] && [ ! -d "/sys/class/net/$IFACE" ]; then
  "$brctl" addbr "$IFACE" || exit 2
# Previous work (stop the interface)
elif [ "$MODE" = 'stop' ]; then
  "$ip" link set dev "$IFACE" down || exit 2
fi

# shellcheck disable=SC2086
unset all_interfaces &&
# $INTERFACES should be word split into multiple arguments to
# mstpctl_parse_ports.  Therefore it should not be quoted here.
mstpctl_parse_ports $INTERFACES | while read -r i; do
  for port in $i; do
    # We attach and configure each port of the bridge
    if [ "$MODE" = 'start' ] && [ ! -d "/sys/class/net/$IFACE/brif/$port" ]; then
      if [ -x /etc/network/if-pre-up.d/vlan ]; then
        IFACE="$port" /etc/network/if-pre-up.d/vlan
      fi
      if [ "$IF_BRIDGE_HW" ]; then
        "$ip" link set dev "$port" down; "$ip" link set dev "$port" address "$IF_BRIDGE_HW"
      fi
      if [ -f "/proc/sys/net/ipv6/conf/$port/disable_ipv6" ]; then
        echo 1 > "/proc/sys/net/ipv6/conf/$port/disable_ipv6"
      fi
      "$brctl" addif "$IFACE" "$port" && "$ip" link set dev "$port" up
    # We detach each port of the bridge
    elif [ "$MODE" = 'stop' ] && [ -d "/sys/class/net/$IFACE/brif/$port" ]; then
      "$ip" link set dev "$port" down && "$brctl" delif "$IFACE" "$port" && \
        if [ -x /etc/network/if-post-down.d/vlan ]; then
          IFACE="$port" /etc/network/if-post-down.d/vlan
        fi
      if [ -f "/proc/sys/net/ipv6/conf/$port/disable_ipv6" ]; then
        echo 0 > "/proc/sys/net/ipv6/conf/$port/disable_ipv6"
      fi
    fi
  done
done

# We finish setting up the bridge
if [ "$MODE" = 'start' ]; then

  if [ "$IF_MSTPCTL_STP" ]; then
    "$brctl" stp "$IFACE" "$IF_MSTPCTL_STP"
  fi

  if [ "$IF_MSTPCTL_MAXAGE" ]; then
    "$mstpctl" setmaxage "$IFACE" "$IF_MSTPCTL_MAXAGE"
  fi

  if [ "$IF_MSTPCTL_FDELAY" ]; then
    "$mstpctl" setfdelay "$IFACE" "$IF_MSTPCTL_FDELAY"
  fi

  if [ "$IF_MSTPCTL_MAXHOPS" ]; then
    "$mstpctl" setmaxhops "$IFACE" "$IF_MSTPCTL_MAXHOPS"
  fi

  if [ "$IF_MSTPCTL_TXHOLDCOUNT" ]; then
    "$mstpctl" settxholdcount "$IFACE" "$IF_MSTPCTL_TXHOLDCOUNT"
  fi

  if [ "$IF_MSTPCTL_FORCEVERS" ]; then
    "$mstpctl" setforcevers "$IFACE" "$IF_MSTPCTL_FORCEVERS"
  fi

  if [ "$IF_MSTPCTL_TREEPRIO" ]; then
    "$mstpctl" settreeprio "$IFACE" 0 "$IF_MSTPCTL_TREEPRIO"
  fi

  if [ "$IF_MSTPCTL_PORTPATHCOST" ]; then
    portpathcosts="$(echo "$IF_MSTPCTL_PORTPATHCOST" | tr '\n' ' ' | tr -s ' ')"
    for portpathcost in $portpathcosts; do
      port="$(echo "$portpathcost" | cut -d '=' -f1)"
      pathcost="$(echo "$portpathcost" | cut -d '=' -f2)"
      if [ -n "$port" ] && [ -n "$pathcost" ]; then
        "$mstpctl" setportpathcost "$IFACE" "$port" "$pathcost"
      fi
    done
  fi

  if [ "$IF_MSTPCTL_PORTADMINEDGE" ]; then
    portadminedges="$(echo "$IF_MSTPCTL_PORTADMINEDGE" | tr '\n' ' ' | tr -s ' ')"
    for portadminedge in $portadminedges; do
      port="$(echo "$portadminedge" | cut -d '=' -f1)"
      adminedge="$(echo "$portadminedge" | cut -d '=' -f2)"
      if [ -n "$port" ] && [ -n "$adminedge" ]; then
        "$mstpctl" setportadminedge "$IFACE" "$port" "$adminedge"
      fi
    done
  fi

  if [ "$IF_MSTPCTL_PORTAUTOEDGE" ]; then
    portautoedges="$(echo "$IF_MSTPCTL_PORTAUTOEDGE" | tr '\n' ' ' | tr -s ' ')"
    for portautoedge in $portautoedges; do
      port="$(echo "$portautoedge" | cut -d '=' -f1)"
      autoedge="$(echo "$portautoedge" | cut -d '=' -f2)"
      if [ -n "$port" ] && [ -n "$autoedge" ]; then
        "$mstpctl" setportautoedge "$IFACE" "$port" "$autoedge"
      fi
    done
  fi

  if [ "$IF_MSTPCTL_PORTP2P" ]; then
    portp2ps="$(echo "$IF_MSTPCTL_PORTP2P" | tr '\n' ' ' | tr -s ' ')"
    for portp2p in $portp2ps; do
      port="$(echo "$portp2p" | cut -d '=' -f1)"
      p2p="$(echo "$portp2p" | cut -d '=' -f2)"
      if [ -n "$port" ] && [ -n "$p2p" ]; then
        "$mstpctl" setportp2p "$IFACE" "$port" "$p2p"
      fi
    done
  fi

  if [ "$IF_MSTPCTL_PORTRESTRROLE" ]; then
    portrestrroles="$(echo "$IF_MSTPCTL_PORTRESTRROLE" | tr '\n' ' ' | tr -s ' ')"
    for portrestrrole in $portrestrroles; do
      port="$(echo "$portrestrrole" | cut -d '=' -f1)"
      restrrole="$(echo "$portrestrrole" | cut -d '=' -f2)"
      if [ -n "$port" ] && [ -n "$restrrole" ]; then
        "$mstpctl" setportrestrrole "$IFACE" "$port" "$restrrole"
      fi
    done
  fi

  if [ "$IF_MSTPCTL_PORTRESTRTCN" ]; then
    portrestrtcns="$(echo "$IF_MSTPCTL_PORTRESTRTCN" | tr '\n' ' ' | tr -s ' ')"
    for portrestrtcn in $portrestrtcns; do
      port="$(echo "$portrestrtcn" | cut -d '=' -f1)"
      restrtcn="$(echo "$portrestrtcn" | cut -d '=' -f2)"
      if [ -n "$port" ] && [ -n "$restrtcn" ]; then
        "$mstpctl" setportrestrtcn "$IFACE" "$port" "$restrtcn"
      fi
    done
  fi

  if [ "$IF_MSTPCTL_BPDUGUARD" ]; then
    portbpduguards="$(echo "$IF_MSTPCTL_BPDUGUARD" | tr '\n' ' ' | tr -s ' ')"
    for portbpduguard in $portbpduguards; do
      port="$(echo "$portbpduguard" | cut -d '=' -f1)"
      bpduguard="$(echo "$portbpduguard" | cut -d '=' -f2)"
      if [ -n "$port" ] && [ -n "$bpduguard" ]; then
        "$mstpctl" setbpduguard "$IFACE" "$port" "$bpduguard"
      fi
    done
  fi

  if [ "$IF_MSTPCTL_TREEPORTPRIO" ]; then
    treeportprios="$(echo "$IF_MSTPCTL_TREEPORTPRIO" | tr '\n' ' ' | tr -s ' ')"
    for treeportprio in $treeportprios; do
      treeport="$(echo "$treeportprio" | cut -d '=' -f1)"
      prio="$(echo "$treeportprio" | cut -d '=' -f2)"
      if [ -n "$treeport" ] && [ -n "$prio" ]; then
        "$mstpctl" settreeportprio "$IFACE" "$treeport" 0 "$prio"
      fi
    done
  fi

  if [ "$IF_MSTPCTL_TREEPORTCOST" ]; then
    treeportcosts="$(echo "$IF_MSTPCTL_TREEPORTCOST" | tr '\n' ' ' | tr -s ' ')"
    for treeportcost in $treeportcosts; do
      treeport="$(echo "$treeportcost" | cut -d '=' -f1)"
      cost="$(echo "$treeportcost" | cut -d '=' -f2)"
      if [ -n "$treeport" ] && [ -n "$cost" ]; then
        "$mstpctl" settreeportcost "$IFACE" "$treeport" 0 "$cost"
      fi
    done
  fi

  if [ "$IF_MSTPCTL_HELLO" ]; then
    "$mstpctl" sethello "$IFACE" "$IF_MSTPCTL_HELLO"
  fi

  if [ "$IF_MSTPCTL_AGEING" ]; then
    "$mstpctl" setageing "$IFACE" "$IF_MSTPCTL_AGEING"
  fi

  if [ "$IF_MSTPCTL_PORTNETWORK" ]; then
    portnetworks="$(echo "$IF_MSTPCTL_PORTNETWORK" | tr '\n' ' ' | tr -s ' ')"
    for portnetwork in $portnetworks; do
      port="$(echo "$portnetwork" | cut -d '=' -f1)"
      network="$(echo "$portnetwork" | cut -d '=' -f2)"
      if [ -n "$port" ] && [ -n "$network" ]; then
        "$mstpctl" setportnetwork "$IFACE" "$port" "$network"
      fi
    done
  fi

  # We activate the bridge
  "$ip" link set dev "$IFACE" up

  # Calculate the maximum time to wait for STP to converge
  maxwait=''
  if [ -n "$IF_MSTPCTL_MAXWAIT" ] && [ "$IF_MSTPCTL_MAXWAIT" != 'auto' ]; then
    # if [ "$IF_MSTPCTL_MAXWAIT" is a number ]; then
    if [ "$IF_MSTPCTL_MAXWAIT" = "${IF_MSTPCTL_MAXWAIT%[!0-9]*}" ]; then
      maxwait="$IF_MSTPCTL_MAXWAIT"
    else
      echo "Ignoring invalid mstpctl_maxwait value '$maxwait'" >&2
    fi
  fi
  if [ -z "$maxwait" ]; then
    root_forward_delay="$("$mstpctl" showbridge "$IFACE" forward-delay)"
    if [ -z "$root_forward_delay" ] || [ "$root_forward_delay" != "${root_forward_delay%[!0-9]*}" ]; then
      root_forward_delay=0
    fi
    bridge_forward_delay="$("$mstpctl" showbridge "$IFACE" bridge-forward-delay)"
    if [ -z "$bridge_forward_delay" ] || [ "$root_forward_delay" != "${bridge_forward_delay%[!0-9]*}" ]; then
      bridge_forward_delay=0
    fi
    if [ $root_forward_delay -gt $bridge_forward_delay ]; then
      maxwait="$root_forward_delay"
    else
      maxwait="$bridge_forward_delay"
    fi
    maxwait=$((maxwait*2+1))
  fi

  # Wait for STP to converge
  if [ $maxwait -ne 0 ]; then
    echo
    echo "Waiting for STP on bridge '$IFACE' to converge (mstpctl_maxwait is $maxwait seconds)."

    # Use 0.1 delay if available
    sleep 0.1 2>/dev/null && maxwait=$((maxwait*10))

    count=0 ; transitioned='' ; converged=''
    while [ -z "$converged" ] && [ $count -lt $maxwait ]; do
      sleep 0.1 2>/dev/null || sleep 1
      count=$((count+1))

      # Converged if all ports are either 'forwarding', 'blocking', or
      # 'disabled', except if all ports are 'disabled' and we have yet to see
      # any port transition to any other valid state.
      converged=true
      for i in $("$brctl" showstp "$IFACE" | sed -n 's/^.*port id.*state[ \t]*\(.*\)$/\1/p'); do
        if [ "$i" = 'listening' ] || [ "$i" = 'learning' ]; then
          transitioned=true
          converged=''
          break
        elif [ "$i" = 'forwarding' ] || [ "$i" = 'blocking' ]; then
          transitioned=true
        elif [ "$i" != 'disabled' ] || [ -z "$transitioned" ]; then
          converged=''
        fi
      done
    done
    if [ -z "$converged" ]; then
      echo "Timed out waiting for STP on bridge '$IFACE' to converge" >&2
    fi
  fi

# Finally we destroy the interface
elif [ "$MODE" = 'stop' ]; then

  "$brctl" delbr "$IFACE"

fi
