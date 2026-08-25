#!/bin/bash

d="`dirname $0`" ; cd "`realpath $d/../../..`"

if [ \! -f setup ] ; then ln -s idnai-make/docs/setup.sh ; fi

cat <<EOF | ./setup.sh
y
y
vthierry
idnai-test
EOF

cd idnai-test
for p in sys web esp32 # numeric maple python 
do make install=idnai-$p
done


