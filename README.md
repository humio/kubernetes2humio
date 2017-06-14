
k8s-humio - Ship Logs from Kubernetes to Humio
==============================================

Contains components for shipping logs from kubernetes clusters to humio.

Overview
--------

fluentd is used to forward application- and host-level logs from each kubernetes worker node to a humio server. This is built upon the approach suggested by fluentd for log forwarding in kubernetes: [Fluentd Kubernetes daemonset](https://github.com/fluent/fluentd-kubernetes-daemonset).  

Node-level-forwarding
---------------------

A docker image is defined here which specifies how to forward to Humio (log sources are reused from the base image). A Kubernetes daemon-set will deploy fluentd pods across every worker node inside the kube-system namespace. Each pod will read the humio ingest token from the "fluentd-humio-ingest-token" secret. 

As per the normal setup, fluentd output is buffered, and uses tls for nice log confidentiality.

Setup
-----

 0. Pre-requisites: 
    - kubernetes cluster
    - user authorized to administrate via kubectl 
    - default service account with read privileges to API server for use by the [kubernetes metadata filter plugin](https://github.com/fabric8io/fluent-plugin-kubernetes_metadata_filter). This should be present by default in the kube-system namespace (even in kubernetes 1.6)
 1. Setup your dataspace in humio and create an ingest token
 2. Base64 encode your token and update fluentd/k8s/fluentd-humio-ingest-token-secret.yaml with the value 
 3. Create your resources in kubernetes: `kubectl apply -f fluentd/k8s/`
