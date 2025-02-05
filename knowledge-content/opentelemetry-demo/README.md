# Configuring the OpenTelemetry Demo App to send data to Oracle Cloud Infrastucture (OCI) backend

The [OpenTelemetry Astronomy Shop](https://github.com/open-telemetry/opentelemetry-demo) is a demo app to illustrate the implementation of OpenTelemetry in a near real-world environment. It is a microservice-based distributed system which can be easily deployed using Docker or Kubernetes, where we will focus here on deploying it using Kubernetes/Helm.

Our aim is to guide you through the needed steps to deploy the OpenTelemetry Demo in a K8s cluster and send its data to OCI Observability and Management Services.

## Prerequisites
The following prerequisites are needed:
1. Ensure to have an [OCI account](https://signup.cloud.oracle.com).
2. In Application Performance Monitoring (APM) service, create an APM domain.
3. Have the Data Upload Endpoint URL and the private data key of that domain available.
4. Have a Kubernetes Cluster available, either locally, in OCI or at other cloud vendors.

## Deploy the Demo App
We will start by creating a dedicated namespace for the demo app:
```bash
kubectl create namespace otel-demo-app
```
Next, we will create a secret named <samp>oci-apm-secret</samp>:
```bash
kubectl create secret generic oci-apm-secret -n otel-demo-app --from-literal="OCI_APM_ENDPOINT=<Data Upload Endpoint>" --from-literal="OCI_APM_DATAKEY=<Data Key>"
```
Add the OpenTelemetry Helm charts site to your repo to allow deploying the OpenTelemetry Demo:
```bash
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
```
Create file <samp>my-values.yaml</samp> with the following content:
```
opentelemetry-collector:
  extraEnvsFrom:
    - secretRef:
        name: oci-apm-secret

  config:
    exporters:
      otlphttp/oci_spans:
        endpoint: "${OCI_APM_ENDPOINT}/20200101/opentelemetry/"
        headers:
          authorization: "dataKey ${OCI_APM_DATAKEY}"
        tls:
          insecure: false
      otlphttp/oci_metrics:
        endpoint: "${OCI_APM_ENDPOINT}/20200101/observations/metric?dataFormat=otlp-metric&dataFormatVersion=1"
        headers:
          authorization: "dataKey ${OCI_APM_DATAKEY}"
        tls:
          insecure: false

    service:
      pipelines:
        traces:
          exporters: [otlp, debug, spanmetrics, otlphttp/oci_spans]
        metrics:
          exporters: [otlphttp/prometheus, debug, otlphttp/oci_metrics]
```
Run the following <samp>helm</samp> command to deploy the OpenTelemetry Demo App:
```bash
helm install otel-demo-app open-telemetry/opentelemetry-demo --values my-values.yaml -n otel-demo-app
```
Here is the expected output:
```bash
...

 ██████╗ ████████╗███████╗██╗         ██████╗ ███████╗███╗   ███╗ ██████╗
██╔═══██╗╚══██╔══╝██╔════╝██║         ██╔══██╗██╔════╝████╗ ████║██╔═══██╗
██║   ██║   ██║   █████╗  ██║         ██║  ██║█████╗  ██╔████╔██║██║   ██║
██║   ██║   ██║   ██╔══╝  ██║         ██║  ██║██╔══╝  ██║╚██╔╝██║██║   ██║
╚██████╔╝   ██║   ███████╗███████╗    ██████╔╝███████╗██║ ╚═╝ ██║╚██████╔╝
 ╚═════╝    ╚═╝   ╚══════╝╚══════╝    ╚═════╝ ╚══════╝╚═╝     ╚═╝ ╚═════╝


- All services are available via the Frontend proxy: http://localhost:8080
  by running these commands:
     kubectl --namespace default port-forward svc/otel-demo-app-frontendproxy 8080:8080

  The following services are available at these paths after the frontendproxy service is exposed with port forwarding:
  Webstore             http://localhost:8080/
  Jaeger UI            http://localhost:8080/jaeger/ui/
  Grafana              http://localhost:8080/grafana/
  Load Generator UI    http://localhost:8080/loadgen/
  Feature Flags UI     http://localhost:8080/feature/    
```
