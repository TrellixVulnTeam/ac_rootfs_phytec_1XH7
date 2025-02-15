#!/bin/sh
# 
# Copyright (C) 2011 Texas Instruments Incorporated - http://www.ti.com/
#  
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as 
# published by the Free Software Foundation version 2.
# 
# This program is distributed "as is" WITHOUT ANY WARRANTY of any
# kind, whether express or implied; without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 

# Get devnode for all devices 
# Input: DEVICE_TYPE like 'rtc', 'i2c', 'mmc'
# Output: yes or no 

source "common.sh"

if [ $# -ne 1 ]; then
        echo "Error: Invalid Argument Count"
        echo "Syntax: $0 <device_type>"
        exit 1
fi
DEVICE_TYPE=$1

############################ Default Params ##############################
case $DEVICE_TYPE in
	mmc)
		IS_BLK_DEVICE="yes"
	;;
	usb)
		IS_BLK_DEVICE="yes"
	;;
	nand)
		IS_BLK_DEVICE="yes"
	;;
	nor)
		IS_BLK_DEVICE="yes"
	;;
	spi|qspi)
		IS_BLK_DEVICE="yes"
	;;
        *)
		IS_BLK_DEVICE="no"	
        ;;
esac

############################ USER-DEFINED Params ##############################
# Try to avoid defining values here, instead see if possible
# to determine the value dynamically
case $ARCH in
esac
case $DRIVER in
esac
case $SOC in
esac
case $MACHINE in
esac

######################### Logic here ###########################################
echo $IS_BLK_DEVICE
