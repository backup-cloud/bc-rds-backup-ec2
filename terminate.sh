# ten minutes is enough to give us a chance to login if there has been a
# problem but is unlikely to push us into an extra billing hour if we
# are running in hourly billing.
sudo shutdown -h 10 &

exit $FAILCODE
