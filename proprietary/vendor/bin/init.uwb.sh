#!/vendor/bin/sh

SCRIPT_NAME="init.uwb.sh"
SRC="/vendor/etc/uwb/"
DEST="/mnt/vendor/persist/uwb/"
CALIBRATION_FILE_NAME_ARRAY=("qorvo_calibration-CE.conf" "qorvo_calibration-JP.conf" "qorvo_calibration-TW.conf" "qorvo_calibration-FCC.conf" "qorvo_calibration-default.conf" "qorvo_calibration-RESTRICTED.conf")
TITTLE_JP="JP calibration file"
TITTLE_TW="TW calibration file"
TITTLE_FCC="FCC calibration file"
TITTLE_CE="CE calibration file"
TITTLE_DEFAULT="ROW (Rest of World) calibration file"


debug()
{
    echo "Debug: $*"
}

notice()
{
    echo "Debug: $*"
    echo "$SCRIPT_NAME: $*" > /dev/kmsg
}

correct_tittle()
{
    notice "correct tittle of uwb conf"
    for name in ${CALIBRATION_FILE_NAME_ARRAY[@]}
    do
        echo "uwb config file $name"
        if [ -f "$DEST$name" ]
        then
            if [[ $name == *CE.conf ]]
            then
                sed -i "s/^$TITTLE_CE/# $TITTLE_CE/g" $DEST$name
            fi
            if [[ $name == *FCC.conf ]]
            then
                sed -i "s/^$TITTLE_FCC/# $TITTLE_FCC/g" $DEST$name
            fi
            if [[ $name == *JP.conf ]]
            then
                sed -i "s/^$TITTLE_JP/# $TITTLE_JP/g" $DEST$name
            fi
            if [[ $name == *TW.conf ]]
            then
                sed -i "s/^$TITTLE_TW/# $TITTLE_TW/g" $DEST$name
            fi
            if [[ $name == *default.conf ]]
            then
                sed -i "s/^$TITTLE_DEFAULT/# $TITTLE_DEFAULT/g" $DEST$name
            fi
        fi
    done
}

PRODUCT=`getprop ro.vendor.product.device`
HW_REV=`getprop ro.boot.hwrev`

notice $PRODUCT:$HW_REV

if [[ "$PRODUCT" == "ctwo" ]]
then
    if [[ $HW_REV == 0xB1* ]]
    then
        correct_tittle
    fi
fi

notice "UWB calibration init"

for i in "${!CALIBRATION_FILE_NAME_ARRAY[@]}"
do
    if [ ! -f $DEST${CALIBRATION_FILE_NAME_ARRAY[$i]} ]
    then
        notice "copy uwb calibration file to persist, FileName:"${CALIBRATION_FILE_NAME_ARRAY[$i]}
        cp $SRC${CALIBRATION_FILE_NAME_ARRAY[$i]} $DEST${CALIBRATION_FILE_NAME_ARRAY[$i]}
        chmod 664 $DEST${CALIBRATION_FILE_NAME_ARRAY[$i]}
    else
        notice "uwb calibration file existed, FileName:"${CALIBRATION_FILE_NAME_ARRAY[$i]}
    fi
done

