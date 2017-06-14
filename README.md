
k8s-humio - Ship Logs from Kubernetes to Humio
==============================================

Contains components for shipping logs from kubernetes clusters to humio.

Overview
--------

Here, fluentd is used to forward _application-_ and _host-_level logs from each kubernetes worker node to humio server. This extends the standard setup [here](https://github.com/fluent/fluentd-kubernetes-daemonset) from fluentd for log forwarding in kubernetes.

Node-level-forwarding
---------------------

In `fluentd/docker-image` a docker image is defined which specifies how to forward to humio (with other settings, like log sources reused from the base image). Kubernetes manifests are defined in `fluentd/k8s`: a daemonset will deploy fluentd pods across every worker node inside the kube-system namespace, and each pod will read the humio ingest token from the `fluentd-humio-ingest-token` secret. 

As per the normal setup, fluentd output is buffered, and uses tls for nice log confidentiality.

Setup
-----

 0. Pre-requisites: 
    - kubernetes cluster
    - user authorized to administrate via kubectl 
    - default service account with read privileges to API server for use by the [kubernetes metadata filter plugin](https://github.com/fabric8io/fluent-plugin-kubernetes_metadata_filter). This should be present by default in the kube-system namespace (even in kubernetes 1.6 with RBAC enabled)
 1. Setup your dataspace in humio and create an ingest token
 2. Base64 encode your token by running `printf 'TOKEN' | base64` and update `fluentd/k8s/fluentd-humio-ingest-token-secret.yaml` with the value 
 3. Create your resources in kubernetes: `kubectl apply -f fluentd/k8s/`
 4. Logs start appearing in humio!
