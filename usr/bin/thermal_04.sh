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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA
#
# Contributors:
#     Amit Daniel <amit.kachhap@linaro.org> (Samsung Electronics)
#       - initial API and implementation
#

# URL : https://wiki.linaro.org/WorkingGroups/PowerManagement/Resources/TestSuite/PmQaSpecification#thermal_04

. ../include/functions.sh
. ../include/thermal_functions.sh
HEAT_CPU_MODERATE=heat_cpu
pid=0

heater_kill() {
    if [ $pid -ne 0 ]; then
	kill -9 $pid
    fi
}

verify_cooling_device_temp_change() {
    dirpath=$THERMAL_PATH/$1
    cdev_name=$1
    shift 1
    tzonepath=$THERMAL_PATH/thermal_zone0
    test -d $tzonepath
    if [ $? -ne 0 ] ; then
	echo "No thermal zone present"
	return 1;
    fi
    max_state=$(cat $dirpath/max_state)
    prev_state_val=$(cat $dirpath/cur_state)

    count=1
    cur_state_val=0
    init_temp=0
    final_temp=0
    cool_temp=0
    $HEAT_CPU_MODERATE moderate &
    pid=$!
    test $pid -eq 0 && return

    while (test $count -le $max_state); do
	echo 0 > $dirpath/cur_state
	sleep 5
	init_temp=$(cat $tzonepath/temp)

	echo $count > $dirpath/cur_state
	sleep 5
	final_temp=$(cat $tzonepath/temp)
	cool_temp=$(($init_temp - $final_temp))
	check "$cdev_name:state=$count effective cool=$cool_temp "\
					"test $cool_temp -ge 0"
	count=$((count+1))
    done
    heater_kill
    echo $prev_state_val > $dirpath/cur_state
}

trap "heater_kill; sigtrap" HUP INT TERM

set_thermal_governors user_space

for_each_cooling_device verify_cooling_device_temp_change

restore_thermal_governors

test_status_show
