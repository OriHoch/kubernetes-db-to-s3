#!/usr/bin/env bash

check_or_build_nsenter() {
    which nsenter >/dev/null && return 0
    echo "INFO: Building 'nsenter' ..."
cat <<-EOF | docker run -i --rm -v "$(pwd):/build" ubuntu:14.04 >& nsenter.build.log
        apt-get update
        apt-get install -qy git bison build-essential autopoint libtool automake autoconf gettext pkg-config
        git clone --depth 1 git://git.kernel.org/pub/scm/utils/util-linux/util-linux.git /tmp/util-linux
        cd /tmp/util-linux
        ./autogen.sh
        ./configure --without-python --disable-all-programs --enable-nsenter
        make nsenter
        cp -pfv nsenter /build
EOF
    if [ ! -f ./nsenter ]; then
        echo "ERROR: nsenter build failed, log:"
        cat nsenter.build.log
        return 1
    fi
    echo "INFO: nsenter build OK"
}

mkdir -p /tmp/build_nsenter && pushd /tmp/build_nsenter && check_or_build_nsenter && sudo chmod +x ./nsenter && sudo mv ./nsenter /usr/local/bin/ && popd &&\
which nsenter &&\
curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/v1.9.4/bin/linux/amd64/kubectl && chmod +x kubectl && sudo mv kubectl /usr/local/bin/ &&\
curl -Lo minikube https://storage.googleapis.com/minikube/releases/v0.25.2/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/ &&\
sudo -E minikube start --vm-driver=none --kubernetes-version=v1.9.4 &&\
minikube update-context &&\
JSONPATH='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}'; until kubectl get nodes -o jsonpath="$JSONPATH" 2>&1 | grep -q "Ready=True"; do sleep 1; done &&\
kubectl get nodes &&\
kubectl create secret generic db-backup --from-literal=S3_BUCKET=${S3_BUCKET} \
                                        --from-literal=S3_NAMESPACE=${S3_NAMESPACE} \
                                        --from-literal=AWS_ACCESS_KEY=${AWS_ACCESS_KEY} \
                                        --from-literal=AWS_SECRET_KEY=${AWS_SECRET_KEY} \
                                        --from-literal=S3_HOST=${S3_HOST} -n app
[ "${?}" != "0" ] && echo failed to initialize minikube && exit 1

minikube mount `pwd`:/kubernetes-db-to-s3 &
sleep 2
echo 'cd /kubernetes-db-to-s3; docker build -t db-backup .; exit' | minikube ssh &&\
kill %1 && sleep 1
[ "${?}" != "0" ] && echo failed to build the docker image inside minikube && exit 1

echo Testing environment was setup successfully
exit 0
