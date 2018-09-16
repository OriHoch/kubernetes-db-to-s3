#!/usr/bin/env bash

mkdir .kube .minikube  >/dev/null 2>&1
#copy the current user minkube configuration to docker  image
cp ~/.minikube/client.*   .minikube/ && cp ~/.minikube/ca.crt .minikube/
chmod  a+r .minikube/client.key
# modify cthe config file from the current user to point to root user on the docker image
sed -e 's|\(.*client-key:\).*\(client\.key$\)|\1 /root/.minikube/\2|'\
        -e 's|\(.*client-certificate:\).*\(client\.crt$\)|\1 /root/.minikube/\2|' \
        -e   's|\(.*certificate-authority:\).*\(ca\.crt$\)|\1 /root/.minikube/\2|' ~/.kube/config >  .kube/config
minikube mount `pwd`:/kubernetes-db-to-s3 &
sleep 2
echo 'cd /kubernetes-db-to-s3; docker build  -t db-backup .; exit' | minikube ssh &&\
kill %1 && sleep 1
[ "${?}" != "0" ] && echo failed to build the docker image inside minikube && exit 1
echo db-backup docker image was built successfully inside minikube
exit 0
 