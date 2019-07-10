# ten minutes is enough to give us a chance to login if there has been
# a problem but is not so likely to push us into an extra billing hour
# if we are running in hourly billing.  Give a little extra since
# systems block login some time before shutdown

if [ "$AUTO_TERMINATE" = "long" ]
then
    # almost 5 days to debug
    sudo shutdown -h +7056 &
elif [ "$AUTO_TERMINATE" != "false" ]
then
    sudo shutdown -h +20 &
fi


exit $FAILCODE
