# Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
# All rights reserved.
# Confidential and Proprietary - Qualcomm Technologies, Inc.

create_instance()
{
    local instance_dir=$1
    if [ ! -d $instance_dir ]
    then
        mkdir $instance_dir
    fi
}

find_build_type()
{
    linux_banner=`cat /proc/version`
    if [[ "$linux_banner" == *"-debug"* ]]
    then
        debug_build=true
    fi
}

create_stp_policy()
{
    create_instance /config/stp-policy/coresight-stm:p_ost.policy
    chmod 660 /config/stp-policy/coresight-stm:p_ost.policy
    create_instance /config/stp-policy/coresight-stm:p_ost.policy/default
    chmod 660 /config/stp-policy/coresight-stm:p_ost.policy/default
    echo ftrace > /config/stp-policy/coresight-stm:p_ost.policy/default/entity
}

adjust_permission()
{
    #add permission for block_size, mem_type, mem_size nodes to collect diag over QDSS by ODL
    #application by "oem_2902" group
    chown -h root.oem_2902 /sys/devices/platform/soc/10048000.tmc/coresight-tmc-etr/block_size
    chmod 660 /sys/devices/platform/soc/10048000.tmc/coresight-tmc-etr/block_size
    chown -h root.oem_2902 /sys/devices/platform/soc/10048000.tmc/coresight-tmc-etr/buffer_size
    chmod 660 /sys/devices/platform/soc/10048000.tmc/coresight-tmc-etr/buffer_size
    chmod 660 /sys/devices/platform/soc/10048000.tmc/coresight-tmc-etr/out_mode
    chown -h root.oem_2902 /sys/devices/platform/soc/1004f000.tmc/coresight-tmc-etr1/block_size
    chmod 660 /sys/devices/platform/soc/1004f000.tmc/coresight-tmc-etr1/block_size
    chown -h root.oem_2902 /sys/devices/platform/soc/1004f000.tmc/coresight-tmc-etr1/buffer_size
    chmod 660 /sys/devices/platform/soc/1004f000.tmc/coresight-tmc-etr1/buffer_size
    chmod 660 /sys/devices/platform/soc/1004f000.tmc/coresight-tmc-etr1/out_mode

    chgrp shell /sys/bus/coresight/devices/*/enable_source
    chmod 660 /sys/bus/coresight/devices/*/enable_source
    chgrp shell /sys/bus/coresight/devices/*/enable_sink
    chmod 660 /sys/bus/coresight/devices/*/enable_sink
}

enable_cti_flush_for_etf()
{
    if [ "$debug_build" != true ]
    then
        return
    fi

    echo 1 > /sys/bus/coresight/devices/coresight-tmc-etf/stop_on_flush
    echo 1 > /sys/bus/coresight/devices/coresight-cti-swao/enable
    echo 0 24 > /sys/bus/coresight/devices/coresight-cti-swao/channels/trigin_attach
    echo 0 1 > /sys/bus/coresight/devices/coresight-cti-swao/channels/trigout_attach
}

debug_build=false
enable_debug()
{
    echo "kera debug"
    find_build_type
    create_stp_policy
    adjust_permission
    enable_cti_flush_for_etf
}

enable_debug
