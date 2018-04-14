#!/usr/bin/env bash

TEST_NAMESPACE="${1:-kdbs3test}"

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
        imagePullPolicy: IfNotPresent
        envFrom:
        - secretRef:
            name: db-backup" \
    | kubectl create -f - && kubectl rollout status "deployment/${NAME}" -n "${NAMESPACE}"
}

kubectl create secret generic db --from-literal=DATABASE_URL=postgres://budgetkey:postgres@postgres/budgetkey -n "${TEST_NAMESPACE}" &&\
create_db postgres "${TEST_NAMESPACE}" &&\
create_app app "${TEST_NAMESPACE}" db &&\
DB_POD=$(kubectl get pods -n "${TEST_NAMESPACE}" -l app=postgres -o=jsonpath='{.items[0].metadata.name}') &&\
kubectl exec -it -n "${TEST_NAMESPACE}" "${DB_POD}" -- su postgres -c "psql -d budgetkey -c 'create table test (id integer); \
                                                                       insert into test (id) values (1), (2), (3); \
                                                                       select * from test;'"
[ "$?" != "0" ] && echo failed to initialize db and app && exit 1

create_db_backup db-backup "${TEST_NAMESPACE}" &&\
BACKUP_POD=$(kubectl get pods -n "${TEST_NAMESPACE}" -l app=db-backup -o=jsonpath='{.items[0].metadata.name}')
[ "$?" != "0" ] && echo failed to initialize backup pod && exit 1
sleep 5
kubectl logs $BACKUP_POD -n "${TEST_NAMESPACE}"
