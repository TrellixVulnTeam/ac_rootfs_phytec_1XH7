#!/bin/sh
#
# PM-QA validation test suite for the power management on Linux
#
# Copyright (C) 2011, Linaro Limited.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# Contributors:
#     Daniel Lezcano <daniel.lezcano@linaro.org> (IBM Corporation)
#       - initial API and implementation
#

# URL : https://wiki.linaro.org/WorkingGroups/PowerManagement/Resources/TestSuite/PmQaSpecification#cpufreq_07

. ../include/functions.sh

CPUBURN=cpuburn

check_ondemand() {

    cpu=$1
    maxfreq=$(get_max_frequency $cpu)
    minfreq=$(get_min_frequency $cpu)
    curfreq=$(get_frequency $cpu)

    set_governor $cpu ondemand

    # wait for a quescient point
    for i in $(seq 1 10); do

	if [ "$minfreq" -eq "$(get_frequency $cpu)" ]; then

	    $CPUBURN $cpu &
	    pid=$!

	    sleep 1
	    wait_latency $cpu
	    curfreq=$(get_frequency $cpu)
	    kill $pid

	    check "'ondemand' increase frequency on load" "test \"$curfreq\" = \"$maxfreq\""

	    sleep 1
	    curfreq=$(get_frequency $cpu)

	    check "'ondemand' decrease frequency on idle" "test \"$curfreq\" = \"$minfreq\""

	    return 0
	fi

	sleep 1

    done

    log_skip "can not reach a quescient point for 'ondemand'"

    return 1
}

supported=$(cat $CPU_PATH/cpu0/cpufreq/scaling_available_governors | grep "ondemand")
if [ -z "$supported" ]; then
    log_skip "ondemand not supported"
    return 0
fi

save_governors

trap "restore_governors; sigtrap" HUP INT TERM

for_each_cpu check_ondemand

restore_governors
test_status_show
