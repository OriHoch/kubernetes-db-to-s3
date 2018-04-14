#!/usr/bin/env bash

create_db() {
    NAME="${1}"
    NAMESPACE="${2}"
echo "
apiVersion: v1
kind: Service
metadata:
  name: ${NAME}
  namespace: ${NAMESPACE}
spec:
  ports:
  - name: '5432'
    port: 5432
  selector:
    app: ${NAME}
---
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: ${NAME}
  namespace: ${NAMESPACE}
spec:
  replicas: 1
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: ${NAME}
    spec:
      containers:
      - name: ${NAME}
        image: budgetkey/budgetkey-postgres:latest
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_PASSWORD
          value: postgres" \
    | kubectl create -f - && kubectl rollout status "deployment/${NAME}" -n "${NAMESPACE}"
}

create_app() {
    NAME="${1}"
    NAMESPACE="${2}"
    SECRET_NAME="${3}"
    echo "
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: ${NAME}
  namespace: ${NAMESPACE}
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: ${NAME}
    spec:
      containers:
      - name: ${NAME}
        image: alpine
        command:
        - sh
        - "-c"
        - while true; do sleep 86400; done
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: ${SECRET_NAME}
              key: DATABASE_URL" \
    | kubectl create -f - && kubectl rollout status "deployment/${NAME}" -n "${NAMESPACE}"
}

create_db_backup() {
    NAME="${1}"
    NAMESPACE="${2}"
    echo "
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: ${NAME}
  namespace: ${NAMESPACE}
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: ${NAME}
    spec:
      containers:
      - name: ${NAME}
        image: db-backup
        envFrom:
        - secretRef:
            name: db-backup" \
    | kubectl create -f - && kubectl rollout status "deployment/${NAME}" -n "${NAMESPACE}"
}

docker build -t db-backup . &&\
kubectl create namespace app &&\
kubectl create secret generic db --from-literal=DATABASE_URL=postgres://postgres:postgres@postgres/postgres -n app &&\
create_db postgres app &&\
create_app app app db &&\
create_db_backup db-backup app
