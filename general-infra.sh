#!/bin/bash

COMMAND=apply
PWD=/home/centos/aws-consul-terraform/modules

for i in {1..5}
do
   cd $PWD/0$i*
   echo yes | terraform $COMMAND
   cd ..
done

cd $PWD
cd ..

echo "Print out all key-values from consul:"
consul kv get -recurse

set TF_LOG=DEBUG
set TF_LOG_PATH=/tmp/log
