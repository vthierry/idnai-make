#!/bin/bash

## Builds a test job using maple to test the installation
cat >/tmp/OARjob <<EOF
#!/bin/bash

echo "\$*"

## Loads required modules
module load maple

## Runs the job itself
echo "lprint(expand((u-v)^2)):" | maple -q

EOF
chmod a+rx /tmp/OARjob

## Calls rrun 
rrun oar:sophia.aba/tmp --name idnai-rrun-test '/tmp/OARjob --hello world -ok'

## Gets and tests the result
cat > rrun.stdok <<EOF
--hello world -ok
u^2-2*u*v+v^2
EOF
if ! diff rrun.stdout rrun.stdok ; then echo "Error: in $0, unexpected result rrun.stdout <> rrun.stdok" ; exit 1 ; fi
/bin/rm -f rrun.std*



