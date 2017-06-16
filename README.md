
k8s-humio - Ship Logs from Kubernetes to Humio
==============================================

Contains components for shipping logs from kubernetes clusters to humio.

Overview
--------

Here, fluentd is used to forward _application-_ and _host-_ level logs from each kubernetes worker node to humio server. This extends the standard setup [here](https://github.com/fluent/fluentd-kubernetes-daemonset) from fluentd for log forwarding in kubernetes.

Node-level Forwarding
---------------------

In `fluentd/docker-image` a docker image is defined which specifies how to forward to humio (with other settings, like log sources reused from the base image). Kubernetes manifests are defined in `fluentd/k8s`: a daemonset will deploy fluentd pods across every worker node inside the _kube-system_ namespace, and each pod will read the humio ingest token from the `fluentd-humio-ingest-token` secret. 

As per the normal setup, fluentd output is buffered, and uses tls for nice log confidentiality.

### Setup

 0. Pre-requisites: 
    - Kubernetes cluster
    - User authorized to administrate via kubectl 
    - Default service account with read privileges to API server for use by the [kubernetes metadata filter plugin](https://github.com/fabric8io/fluent-plugin-kubernetes_metadata_filter). This should be present by default in the kube-system namespace (even in kubernetes 1.6 with RBAC enabled)
 1. Setup your dataspace in humio and create an ingest token
 2. Base64 encode your token by running `printf 'TOKEN' | base64` and update `fluentd/k8s/fluentd-humio-ingest-token-secret.yaml` with the value 
 3. Create your resources in kubernetes: `kubectl apply -f fluentd/k8s/`
 4. Logs start appearing in humio!

### Fluentd Container Variables

We expose three environment variables so the daemonset configuration can be easily changed in different environments:
 - *FLUENT_HUMIO_HOST*: humio host
 - *FLUENT_HUMIO_DATA_SPACE*: used to parameterize the path to humio bulk elastic ingest API for your data space
 - *FLUENT_HUMIO_INGEST_TOKEN*: authorization to push logs into humio

If you need to make further customizations, you will need to mount in an altered version of the fluentd config files /fluentd/etc/fluent.conf and /fluentd/etc/kubernetes.conf, e.g. using ConfigMaps.

### Namespacing and Service Accounts Usage

As noted above, the 'default' service account is used by the fluentd metadata plugin to lookup pod/namespace information. This is not particularly in line with the developing RBAC model for service accounts in Kubernetes, but causes few problems in the kube-system namespace where services are assumed to be somewhat root-like. Since 'default' service account is available to all pods in a namespace, careful thought is recommended when assigning permissions to this account to get fluentd to work outside the kube-system namespace. 

Control-plane Events
--------------------

TODO
