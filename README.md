
k8s-humio - Ship Logs, Events and Metrics from Kubernetes to Humio
==================================================================

Contains components for shipping logs, events and metrics from
kubernetes clusters to [humio](https://humio.com).

Overview
--------

Here, fluentd is used to forward *application-* and *host-* level logs
from each kubernetes node to humio server. This extends the standard
setup [here](https://github.com/fluent/fluentd-kubernetes-daemonset)
from fluentd for log forwarding in kubernetes. Heapster is deployed so
for publishing various aggregated metrics to humio. For clusters where
the master nodes are not accessible (eg on GCP) we use eventer to
expose events occurring in the kubernetes control plane.

Getting Started
---------------

0. Pre-requisites:
   - Kubernetes cluster
   - User authorized to administrate via kubectl
   - Default service account with read privileges to API server for use
     by the [kubernetes metadata filter
     plugin](https://github.com/fabric8io/fluent-plugin-kubernetes_metadata_filter). This
     shouldbe present by default in the kube-system namespace (even in
     kubernetes 1.6 with RBAC enabled)
1. Setup your data space in humio and create an ingest token
2. Base64 encode your token by running `printf 'TOKEN' | base64` and
   update `fluentd/k8s/fluentd-humio-ingest-token-secret.yaml` with
   the value
3. Create fluentd resources in kubernetes: `kubectl apply -f
   fluentd/k8s/`
4. Create heapster to send metrics to humio: `kubectl apply -f
   heapster/`
5. If master nodes are not scheduleable in your cluster, also create
   eventer to expose control-plane events: `kubectl apply -f
   eventer/`
6. Logs start appearing in humio!

Node-level Forwarding
---------------------

In `fluentd/docker-image` a docker image is defined which specifies
how to forward to humio (with other settings, like log sources reused
from the base image). Kubernetes manifests are defined in
`fluentd/k8s`: a daemonset will deploy fluentd pods across every
worker node inside the *kube-system* namespace, and each pod will read
the humio ingest token from the `fluentd-humio-ingest-token` secret.

As per the normal setup, fluentd output is buffered, and uses TLS for
nice log confidentiality. It also appends kubernetes metadata such and
pod name and namespace to each log entry, wrapping raw logs in a
standard json structure.

### Log types

For any application running as a pod in kubernetes, the value of the
**log-type** label added to the pod will be used to determine the
parser humio uses to parse log lines arriving from the pod. Each value
must have a corresponding parser in humio. If the label is unspecified
or doesn't correspond to a parser then pod logs will be left as
unstructured text.

### Fluentd Container Variables

We expose three environment variables so the daemonset configuration
can be easily changed in different environments:

- **FLUENT_HUMIO_HOST**: humio host
- **FLUENT_HUMIO_DATA_SPACE**: used to parameterize the path to humio
    bulk elastic ingest API for your data space
- **FLUENT_HUMIO_INGEST_TOKEN**: authorization to push logs into humio

If you need to make further customizations, you will need to mount in
an altered version of the fluentd config files
`/fluentd/etc/fluent.conf` and `/fluentd/etc/kubernetes.conf`,
e.g. using ConfigMaps.

### Namespacing and Service Accounts Usage

As noted above, the 'default' service account is used by the fluentd
metadata plugin to lookup pod/namespace information. This is not
particularly in line with the developing RBAC model for service
accounts in kubernetes, but causes few problems in the kube-system
namespace where services are assumed to be somewhat root-like. Since
'default' service account is available to all pods in a namespace,
careful thought is recommended when assigning permissions to this
account to get fluentd to work outside the kube-system namespace.

Metrics
-------

In addition to ingesting logs and events it can also be helpful to
ingest metrics into humio. The standard component for metrics
collection is heapster, so that is what we use here to easily get hold
of metrics aggregated for hosts, namespaces, pods, containers, and the
cluster.  As with eventer, heapster is able to use stdout as a sink,
however the existing multi-line formatting is not readily
parseable. To solve this, we use a [forked
version](https://github.com/benjvi/heapster/tree/json-sink) which can
output metrics data in a predictable json structure. In this
structure: - A single log entry/json document is created for each
MetricSet. MetricSets are defined for logical components of each
[aggregation
object](https://github.com/kubernetes/heapster/blob/master/docs/storage-schema.md#user-content-aggregates)
- e.g. services on a host. This division is important to bound the
maximum size of log entries.  - Key-value metrics info can be found
under the 'Metrics' and 'LabeledMetrics' keys. In case of
LabeledMetrics the value is given as a list, to allow for further
disambiguation or metrics according to the `resource_id` label - All
information defined in the [storage-schema
docs](https://github.com/kubernetes/heapster/blob/master/docs/storage-schema.md)
is passed on

Control-plane Events
--------------------

Appropriate for clusters where fluentd cannot run on master nodes, the
eventer component of [heapster](github.com/kubernetes/heapster) is
used to retrieve cluster events from the API server. We forward events
to fluentd by simply printing events to stdout, providing a consistent
interface for logs coming out of kubernetes. Eventer runs as a
deployment with a single instance handling all cluster events,
regardless of cluster size. As with heapster, it makes use of the
addon-resizer component to update requested resources as load on the
eventer, causing the eventer pod to get redeployed as cluster activity
grows past certain thresholds.
