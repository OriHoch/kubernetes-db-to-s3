#!/usr/bin/env bash

NAMESPACE="${1:-default}"

S3_BUCKET="123456"
S3_NAMESPACE=$S3_BUCKET
AWS_ACCESS_KEY=$S3_BUCKET
AWS_SECRET_KEY=$S3_BUCKET
S3_HOST=$S3_BUCKET
S3_HOST_BUCKET=$S3_BUCKET

if [ -n "${S3_BUCKET}" ] && [ -n "${S3_NAMESPACE}" ] && [ -n "${AWS_ACCESS_KEY}" ] && [ -n "${AWS_SECRET_KEY}" ] && [ -n "${S3_HOST}" ]; then
    kubectl create secret generic db-backup --from-literal=S3_BUCKET=${S3_BUCKET} \
                                            --from-literal=S3_NAMESPACE=${S3_NAMESPACE} \
                                            --from-literal=AWS_ACCESS_KEY=${AWS_ACCESS_KEY} \
                                            --from-literal=AWS_SECRET_KEY=${AWS_SECRET_KEY} \
                                            --from-literal=S3_HOST=${S3_HOST} \
                                            --from-literal=S3_HOST_BUCKET=${S3_HOST_BUCKET} -n "${NAMESPACE}"
    exit 0
else
    echo missing environment variables
    exit 1
fi
