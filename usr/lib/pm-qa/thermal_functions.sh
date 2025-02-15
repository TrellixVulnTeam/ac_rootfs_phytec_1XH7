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

THERMAL_PATH="/sys/devices/virtual/thermal"
MAX_ZONE=0-12
MAX_CDEV=0-50
scaling_freq_array="scaling_freq"
mode_array="mode_list"
thermal_gov_array="thermal_governor_backup"
thermal_zones=$(ls $THERMAL_PATH | grep "thermal_zone['$MAX_ZONE']")

check_valid_temp() {
    file=$1
    zone_name=$2
    dir=$THERMAL_PATH/$zone_name

    temp_file=$dir/$file
    shift 2;

    temp_val=$(cat $temp_file)
    descr="'$zone_name'/'$file' ='$temp_val'"
    log_begin "checking $descr"

    if [ $temp_val -gt 0 ]; then
        log_end "Ok"
        return 0
    fi

    log_end "Err"

    return 1
}

for_each_thermal_zone() {

    thermal_func=$1
    shift 1

    for thermal_zone in $thermal_zones; do
	INC=0
	$thermal_func $thermal_zone $@
    done

    return 0
}

get_total_trip_point_of_zone() {
    zone=$1
    zone_path=$THERMAL_PATH/$zone
    count=0
    shift 1
    trips=$(ls $zone_path | grep "trip_point_['$MAX_ZONE']_temp")
    for trip in $trips; do
	count=$((count + 1))
    done
    return $count
}

for_each_trip_point_of_zone() {

    zone_path=$THERMAL_PATH/$1
    count=0
    func=$2
    zone_name=$1
    shift 2
    trips=$(ls $zone_path | grep "trip_point_['$MAX_ZONE']_temp")
    for trip in $trips; do
	$func $zone_name $count
	count=$((count + 1))
    done
    return 0
}

for_each_binding_of_zone() {

    zone_path=$THERMAL_PATH/$1
    count=0
    func=$2
    zone_name=$1
    shift 2
    trips=$(ls $zone_path | grep "cdev['$MAX_CDEV']_trip_point")
    for trip in $trips; do
	$func $zone_name $count
	count=$((count + 1))
    done

    return 0

}

check_valid_binding() {
    trip_point=$1
    zone_name=$2
    dirpath=$THERMAL_PATH/$zone_name
    temp_file=$zone_name/$trip_point
    trip_point_val=$(cat $dirpath/$trip_point)
    get_total_trip_point_of_zone $zone_name
    trip_point_max=$?
    descr="'$temp_file' valid binding"
    shift 2

    log_begin "checking $descr"
    if [ $trip_point_val -ge $trip_point_max ]; then
        log_end "Err"
        return 1
    fi

    log_end "Ok"
    return 0
}

validate_trip_bindings() {
    zone_name=$1
    bind_no=$2
    dirpath=$THERMAL_PATH/$zone_name
    trip_point=cdev"$bind_no"_trip_point
    shift 2

    check_file $trip_point $dirpath || return 1
    check_valid_binding $trip_point $zone_name || return 1
}

validate_trip_level() {
    zone_name=$1
    trip_no=$2
    dirpath=$THERMAL_PATH/$zone_name
    trip_temp=trip_point_"$trip_no"_temp
    trip_type=trip_point_"$trip_no"_type
    shift 2

    check_file $trip_temp $dirpath || return 1
    check_file $trip_type $dirpath || return 1
    check_valid_temp $trip_temp $zone_name || return 1
}

for_each_cooling_device() {

    cdev_func=$1
    shift 1

    cooling_devices=$(ls $THERMAL_PATH | grep "cooling_device['$MAX_CDEV']")
    if [ "$cooling_devices" = "" ]; then
	log_skip "no cooling devices"
	return 0
    fi

    for cooling_device in $cooling_devices; do
	INC=0
	$cdev_func $cooling_device $@
    done

    return 0
}
check_scaling_freq() {

    before_freq_list=$1
    after_freq_list=$2
    shift 2
    index=0

    flag=0
    for cpu in $cpus; do
        after_freq=$(eval echo \$$after_freq_list$index)
        before_freq=$(eval echo \$$before_freq_list$index)

        if [ $after_freq -ne $before_freq ]; then
            flag=1
        fi

        index=$((index + 1))
    done    

    return $flag
}

store_scaling_maxfreq() {
    index=0

    for cpu in $cpus; do
        scaling_freq_max_value=$(cat $CPU_PATH/$cpu/cpufreq/scaling_max_freq)
        eval $scaling_freq_array$index=$scaling_freq_max_value
        eval echo $scaling_freq_array$index    
    done

    return 0
}

get_trip_id() {

    trip_name=$1
    shift 1

    id1=$(echo $trip_name|cut -c12)
    id2=$(echo $trip_name|cut -c13)
    if [ $id2 != "_" ]; then
	id1=$(($id2 + 10*$id1))
    fi
    return $id1
}

disable_all_thermal_zones() {

    index=0

    for thermal_zone in $thermal_zones; do
        mode=$(cat $THERMAL_PATH/$thermal_zone/mode)
        eval $mode_array$index=$mode
        eval export $mode_array$index
        index=$((index + 1))
        echo -n "disabled" > $THERMAL_PATH/$thermal_zone/mode
    done

    return 0
}

enable_all_thermal_zones() {

    index=0

    for thermal_zone in $thermal_zones; do
        mode=$(eval echo \$$mode_array$index)
        echo $mode > $THERMAL_PATH/$thermal_zone/mode
        index=$((index + 1))
    done

    return 0
}

GPU_HEAT_BIN=/usr/bin/glmark2
gpu_pid=0

start_glmark2() {
    if [ -n "$ANDROID" ]; then
        am start org.linaro.glmark2/.Glmark2Activity
        return
    fi

    if [ -x $GPU_HEAT_BIN ]; then
        $GPU_HEAT_BIN &
        gpu_pid=$(pidof $GPU_HEAT_BIN)
        # Starting X application from serial console needs this
        if [ -z "$gpu_pid" ]; then
            cp /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.bk
            echo "autologin-user=root" >> /etc/lightdm/lightdm.conf
            export DISPLAY=localhost:0.0
            restart lightdm
            sleep 5
            mv /etc/lightdm/lightdm.conf.bk /etc/lightdm/lightdm.conf
            $GPU_HEAT_BIN &
            gpu_pid=$(pidof $GPU_HEAT_BIN)
        fi
        test -z "$gpu_pid" && cpu_pid=0
        echo "start gpu heat binary $gpu_pid"
    else
        echo "glmark2 not found." 1>&2
    fi
}

kill_glmark2() {
    if [ -n "$ANDROID" ]; then
        am kill org.linaro.glmark2
        return
    fi

    if [ "$gpu_pid" -ne 0 ]; then
	kill -9 $gpu_pid
    fi
}

set_thermal_governors() {

    gov=$1
    index=0

    for thermal_zone in $thermal_zones; do
        policy=$(cat $THERMAL_PATH/$thermal_zone/policy)
        eval $thermal_gov_array$index=$policy
        eval export $thermal_gov_array$index
        index=$((index + 1))
        echo $gov > $THERMAL_PATH/$thermal_zone/policy
    done

    return 0
}

restore_thermal_governors() {

    index=0

    for thermal_zone in $thermal_zones; do
        old_policy=$(eval echo \$$thermal_gov_array$index)
        echo $old_policy > $THERMAL_PATH/$thermal_zone/policy
        index=$((index + 1))
    done

    return 0
}
