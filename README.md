# kubernetes-db-to-s3
A Kubernetes solution for backing up DBs to an S3 bucket using pg_dump and s3cmd


## Running the tests locally

* Start [minikube](https://kubernetes.io/docs/getting-started-guides/minikube/)
* Build the db-backup image inside minikube
  * `tests/minikube_docker_build.sh`
* Create the test namespace
  * `kubectl create namespace kdbs3test`
* Create the secrets required to upload to S3 in kdbs3test namespace (requires some env vars, see the script)
  * `tests/create_secret.sh kdbs3test`
* Run the tests on kdbs3test namespace
  * `tests/test.sh kdbs3test`
* Delete the namespace when done
  * `kubectl delete namespace kdbs3test --now --force --grace-period=1`
