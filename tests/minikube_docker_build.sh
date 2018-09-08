#!/usr/bin/env bash

mkdir .kube .minikube
cp ~/.kube/config .kube/ && cp ~/.minikube/client.*   .minikube/ && cp ~/.minikube/ca.crt .minikube/
minikube mount `pwd`:/kubernetes-db-to-s3 &
sleep 2
echo 'cd /kubernetes-db-to-s3; docker build  -t db-backup .; exit' | minikube ssh &&\
kill %1 && sleep 1
[ "${?}" != "0" ] && echo failed to build the docker image inside minikube && exit 1
echo db-backup docker image was built successfully inside minikube
exit 0
