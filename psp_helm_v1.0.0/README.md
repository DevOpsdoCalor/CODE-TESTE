# PSP Helm

Helm artifacts for Paravision Search related components and dependencies.

## Instructions to install a project/dependency using helm

### Prerequisites

1. Make sure helm is installed on local system. Helm can be installed via

      ```
      curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
      ```

- Clone this repo

### Install a project/dependency

1. To install a project/dependency, first the corresponding `value.yaml` file needs to be updated. E.g., in order to install `mongodb` go into the mongodb directory and edit the value.yaml file. Sample below:

   ```
   mongodb:
   database_name: aWdz
   igs_password: cGFzc3dvcmQK
   igs_user: aWdzX3VzZXI=
   mongodb: mongo:5.0
   namespace: mongodb
   pv_mount_path: <<Mount path on your local WSL. Typically a folder under /var/lib/>>
   root_password: cGFzc3dvcmQK
   root_user: YWRtaW4K
   user_roles: aWdzX3VzZXI6ZGJBZG1pbixyZWFkV3JpdGU6cGFzc3dvcmQ=
   ```

The place holders are marked with `<< >>` and must be provided with a valid value. E.g., in the sample yaml above, `<<Mount path on your local WSL. Typically a folder under /var/lib/>>` must be replaced with a valid directory on the WSL host machine. The rest of the properties could be used as is.

2. Command to install

   ```
   helm install <name of the helm chart> <path to the Chart.yaml>
   ```

   E.g., to install `mongodb` via

   ```
   helm install mongodb mongodb
   ```

# Steps to create certificate and Keystore

## Approach 1 - to reuse the worker certs for orchestrator

1. Convert worker pem files to pkcs12 keystore (Specify keystore password when prompted)

   ```
   openssl pkcs12 -export -in cert.pem -inkey key.pem -out psp_keystore.p12 -name "psp"
   ```

2. Validate the keystore

   ```
   keytool -list -v -storetype pkcs12 -keystore psp_keystore.p12 -storepass psppass
   ```

3. Create trust store with above certificate

   ```
   keytool -importcert -noprompt -alias psp -file cert.pem \
       -keystore psp_truststore.p12 -storepass psppass -storetype pkcs12
   ```

## Approach 2 - to generate separate certs for orchestrator and worker

1. Generate keystore in pkcs12 format

   ```
   keytool -genkeypair -noprompt -alias psp -dname "CN=psp" -keyalg RSA \
       -keysize 2048 -sigalg SHA256withRSA -storetype PKCS12 \
       -keystore psp_keystore.p12 -validity 3650 -keypass psppass -storepass psppass
   ```

2. Validate the keystore

   ```
   keytool -list -v -storetype pkcs12 -keystore psp_keystore.p12 -storepass psppass
   ```

3. Export the certificate

   ```
   keytool -exportcert -noprompt -rfc -storetype pkcs12 -keystore psp_keystore.p12 \
       -storepass psppass -alias psp -file psporc.crt
   ```

4. Create trust store with above certificate

   ```
   keytool -importcert -noprompt -alias psp -file psporc.crt \
       -keystore psp_truststore.p12 -storepass psppass -storetype pkcs12
   ```

# Deployment Steps

1. Configure helm variables in `values.yaml` or `values/local.yaml` or `values/cloud.yaml` to generate deployment YAML depending on target env.

2. Run `install.sh`

# Loki, Prometheus, Grafana
## Installing prometheus 
1. Deploy Prometheus on `monitoring` namespace after installation is completed using `install.sh`.
   ```
   helm upgrade --install prometheus --version 40.3.0 --namespace monitoring prometheus-community/kube-prometheus-stack
   ```

## Setting up Loki data source in Grafana

1. Open the Grafana dashboard in a webbrowser `http://<url>:3000`, if this
   is the first time logging into the Grafana dashboard the creds are admin/admin

2. Click on the "Configuration" gear icon on the left panel of the webpage

3. Click on "Data sources" and then click on "Loki"

4. In the URL section of the Loki configuration, use the URL
   `http://loki.psp.svc.cluster.local:3100`

5. Click the "Save and Test" button at the bottom of the page

6. The Loki data source should now be ready to use, click the "Explore" button
   start testing with Loki

## Setting up Prometheus data source in Grafana

1. Open the Grafana dashboard in a webbrowser `http://<url>:3000`, if this
   is the first time logging into the Grafana dashboard the creds are admin/admin

2. Click on the "Configuration" gear icon on the left panel of the webpage

3. Click on "Data sources" and then click on "Prometheus"

4. In the URL section of the Prometheus configuration, use the URL
   `http://prometheus-kube-prometheus-prometheus.psp.svc.cluster.local:9090`

5. Click the "Save and Test" button at the bottom of the page

6. The Prometheus data source should now be ready to use, click the "Explore" button
   start testing with prometheus

## Setting up Loki LogQL queries with Grafana to acquire Orchestrator metrics

### Average request latency

1. Build the following raw Loki LogQL query with Grafana to acquire the average
   search request latency over time:

   ```
   avg_over_time({app="psp-orchestrator"} |~ `psp/v1/search.*mean` |
   regexp `.*mean=(?P<latency>\d+.\d+).*` | unwrap latency [$__interval])
   ```

2. Build the following raw Loki LogQL query with Grafana to acquire the average
   enroll request latency over time:

   ```
   avg_over_time({app="psp-orchestrator"} |~ `psp/v1/datasets/.*/records.*mean` |
   regexp `.*mean=(?P<latency>\d+.\d+).*` | unwrap latency [$__interval])
   ```

3. Build the following raw Loki LogQL query with Grafana to acquire the average
   extraction request latency over time:

   ```
   avg_over_time({app="psp-orchestrator"} |~ `psp/v1/extract/face.*mean` |
   regexp `.*mean=(?P<value>\d+.\d+).*` | unwrap value [$__interval])
   ```

### Request concurrency

1. Build the following raw Loki LogQL query with Grafana to acquire the active
   search request concurrency over time:

   ```
   max_over_time({app="psp-orchestrator"} |~ `.search_concurrency_gauge{}` |
   regexp `value=(?P<count>[0-9]+)` |
   unwrap count [$__interval])
   ```

2. Build the following raw Loki LogQL query with Grafana to acquire the active
   enroll request concurrency over time:

   ```
   max_over_time({app="psp-orchestrator"} |~ `.enroll_concurrency_gauge{}` |
   regexp `value=(?P<count>[0-9]+)` |
   unwrap count [$__interval])
   ```

3. Build the following raw Loki LogQL query with Grafana to acquire the active
   extract request concurrency over time:

   ```
   max_over_time({app="psp-orchestrator"} |~ `.extract_concurrency_gauge{}` |
   regexp `value=(?P<count>[0-9]+)` |
   unwrap count [$__interval])
   ```

### Active pod count

1. Build the following raw Loki LogQL query with Grafana to acquire the active
   data-worker pod count over time:

   ```
   count by(pod) (rate({pod=~"psp-data-worker.*"} [$__interval]))
   ```

2. Build the following raw Loki LogQL query with Grafana to acquire the active
   extract-worker pod count over time:

   ```
   count by(pod) (rate({pod=~"psp-extract-worker.*"} [$__interval]))
   ```

3. Build the following raw Loki LogQL query with Grafana to acquire the active
   search-worker pod count over time:

   ```
   count by(pod) (rate({pod=~"psp-search-worker.*"} [$__interval]))
   ```

## Setting up Prometheus queries with Grafana to acquire Kubernetes metrics

### Pod Count

1. Build the following raw Prometheus PromQL query with Grafana to acquire the
   search worker pod count:

   ```
   count(kube_pod_info{pod=~".*psp-search-worker.*"})
   ```

2. Build the following raw Prometheus PromQL query with Grafana to acquire the
   extract worker pod count:

   ```
   count(kube_pod_info{pod=~".*psp-extract-worker.*"})
   ```

3. Build the following raw Prometheus PromQL query with Grafana to acquire the
   data worker pod count:

   ```
   count(kube_pod_info{pod=~".*psp-data-worker.*"})
   ```

## Changing the legend text on the Grafana graphs

1. Go to the Grafana dashboard

2. Go to the "Edit Panel" of the desired graph

3. Click the drop-down for the "Options" in the query

4. Use the desired text or label for your legend value by using the Legend value:

```
<text> OR {{<label-name>}}
```
