#!/vendor/bin/sh

AUDIO_PATH="/data/vendor/audio"
CALIB_FILE="$AUDIO_PATH/upd_calib_v2"
PERSIST_AUDIO="/mnt/vendor/persist/factory/audio"
ULTRA_DEFAULT_FILE_NAME="/vendor/etc/motorola/12m/ultrasound.wav"
RUNNER=/vendor/bin/UPD_calib
SCRIPT_NAME="ultrasound_cal.sh"
ULTRASOUND_CAL_PROP="vendor.ultrasound.cal.action"
ULTRASOUND_PLAYBACK="vendor.ultrasound.playback_enable"
ULTRASOUND_PLAYBACK_FILENAME="vendor.ultrasound.playback_filename"

debug()
{
    echo "Debug: $*"
}

notice()
{
    echo "Debug: $*"
    echo "$SCRIPT_NAME: $*" > /dev/kmsg
}

init_log_path()
{
    if [ ! -d "$AUDIO_PATH" ]
    then
        mkdir -p $AUDIO_PATH
        chown audio $AUDIO_PATH
        chgrp audio $AUDIO_PATH
        chmod 660 $AUDIO_PATH
        touch $CALIB_FILE
        chown audio $CALIB_FILE
        chgrp audio $CALIB_FILE
        chmod 660 $CALIB_FILE
    else
        rm $CALIB_FILE
        rm $DEBUG_DUMP
        touch $CALIB_FILE
        chown audio $CALIB_FILE
        chgrp audio $CALIB_FILE
        chmod 660 $CALIB_FILE
    fi
}

start_runner()
{
    if [ -f "$RUNNER" ]
    then
        notice "init log path..."
        init_log_path
        #sleep 2s for initializaion is ready
        sleep 2
        $RUNNER &
        setprop $ULTRASOUND_CAL_PROP "running"
    else
        notice "$RUNNER dose not exists"
    fi
}

signal_runner()
{
    notice "send signal $1 to engine_runner"
    case "$1" in
        "stop")
            killall -INT UPD_calib
            ;;
        "far")
            killall -SIGUSR1 UPD_calib
            ;;
        "near")
            killall -SIGUSR2 UPD_calib
            ;;
    esac
}

copy_cal_data()
{
    if [ -f "$CALIB_FILE" ]
    then
        cp "$CALIB_FILE" "$PERSIST_AUDIO/upd_calib_v2"
        if [ "$?" == "0" ]
        then
            notice "copy calibration data done!"
        fi

        if [ -f "$PERSIST_AUDIO/upd_calib_v2" ]
        then
            chown audio audio "$PERSIST_AUDIO/upd_calib_v2"
            chgrp system system "$PERSIST_AUDIO/upd_calib_v2"
            chmod 664 "$PERSIST_AUDIO/upd_calib_v2"
        else
            notice "$PERSIST_AUDIO/upd_calib_v2 dosen't exists!"
        fi
    fi
}

ultrasound_handset_playback()
{
    tinymix 'WSA RX0 MUX' 'AIF1_PB' && \
    tinymix 'WSA_RX0 INP0' 'RX0' && \
    tinymix 'WSA_COMP1 Switch' 1 && \
    tinymix 'SpkrLeft COMP Switch' 0 && \
    tinymix 'SpkrLeft VISENSE Switch' 1 && \
    tinymix 'SpkrLeft SWR DAC_Port Switch' 1
    if [ "$?" == "0" ]
    then
       notice "set audio parameter done!"
    fi
    prop=`getprop $ULTRASOUND_PLAYBACK_FILENAME`
    notice "$ULTRASOUND_PLAYBACK_FILENAME is $prop"
    if [ "$prop" != "" ]
    then
        notice "use choosed playback file"
        if [ -f "$prop" ]
        then
            agmplay "$prop" –D 100 -d 100 -i 'CODEC_DMA-LPAIF_WSA-RX-0'
        fi
    elif [ -f "$ULTRA_DEFAULT_FILE_NAME" ]
    then
        notice "use default file $ULTRA_DEFAULT_FILE_NAME"
        agmplay "$ULTRA_DEFAULT_FILE_NAME" -D 100 -d 100 -i 'CODEC_DMA-LPAIF_WSA-RX-0'
    else
        notice "$ULTRA_DEFAULT_FILE_NAME dosen't exists!"

    fi
}

ultrasound_cal()
{
    while true
    do
        prop=`getprop $ULTRASOUND_CAL_PROP`
        notice "prop is $prop"
        if [ "$prop" == "start" ]; then
            start_runner
        elif [ "$prop" == "far" ]; then
            signal_runner "far"
        elif [ "$prop" == "near" ]; then
            signal_runner "near"
        elif [ "$prop" == "stop" ]; then
            signal_runner "stop"
            sleep 3
            copy_cal_data
            break;
        fi
        sleep 0.1
    done
}

while getopts "cp" op
do
    case "$op" in
        "c")
            notice "ultrasound calibration"
            ultrasound_cal
            ;;
        "p")
            notice "ultrasound playback"
            prop=`getprop $ULTRASOUND_PLAYBACK`
            notice "$ULTRASOUND_PLAYBACK is $prop"
            if [ "$prop" == "1" ]; then
                ultrasound_handset_playback
            fi
            ;;
        "h")
            usage
            ;;
        *)
            debug "unkown option arg"
            ;;
        esac
done

