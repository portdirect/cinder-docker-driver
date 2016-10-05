#!/bin/sh
set -x
echo "Moving the payload into place"
/bin/cp -Rf /opt/payload/* /
/bin/rm -Rf /opt/payload
