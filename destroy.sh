#!/bin/bash

COMMAND=destroy
PWD=/home/centos/aws-consul-terraform/modules


#for i in {7..6}
#do
#    cd $PWD/0$i*
#    echo yes | terraform $COMMAND -var cluster_type=$1
#    rm *.tfstate*
#    cd ..
#done  



for i in {5..1}
do
   cd $PWD/0$i*
   echo yes | terraform $COMMAND
   rm *.tfstate*
   cd ..
done

cd $PWD
cd ..

echo "Restart consul..."
sudo systemctl restart consul.service

sleep 5

echo "Print out all key-values from consul:"
consul kv get -recurse
