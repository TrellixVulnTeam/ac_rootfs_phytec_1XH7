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

# URL : https://wiki.linaro.org/WorkingGroups/PowerManagement/Resources/TestSuite/PmQaSpecification#cpufreq_09

. ../include/functions.sh

CPUBURN=cpuburn

check_powersave() {

    cpu=$1
    minfreq=$(get_min_frequency $cpu)
    curfreq=$(get_frequency $cpu)

    set_governor $cpu powersave

    wait_latency $cpu
    curfreq=$(get_frequency $cpu)

    check "'powersave' sets frequency to $(frequnit $minfreq)" "test \"$curfreq\" = \"$minfreq\""

    $CPUBURN $cpu &
    pid=$!

    wait_latency $cpu
    curfreq=$(get_frequency $cpu)
    kill $pid

    check "'powersave' frequency $(frequnit $minfreq) is fixed" "test \"$curfreq\" = \"$minfreq\""

    return 0
}

save_governors

supported=$(cat $CPU_PATH/cpu0/cpufreq/scaling_available_governors | grep "powersave")
if [ -z "$supported" ]; then
    log_skip "powersave not supported"
    return 0
fi

trap "restore_governors; sigtrap" HUP INT TERM

for_each_cpu check_powersave

restore_governors
test_status_show
