# back8sup

[![](https://images.microbadger.com/badges/image/adfinissygroup/back8sup.svg)](https://microbadger.com/images/adfinissygroup/back8sup "Get your own image badge on microbadger.com") [![](https://images.microbadger.com/badges/version/adfinissygroup/back8sup.svg)](https://microbadger.com/images/adfinissygroup/back8sup "Get your own version badge on microbadger.com")

A simple way to backup your kubernetes resources

## Why?

In some cases, using Velero with an S3 storage provider is overkill.

This script keeps things very basic and simple, and makes it easy to backup your Kubernetes metadata quickly by using your default StorageClass.

## Deployment with Helm

```shell
helm repo add adfinis https://charts.adfinis.com
helm install back8sup adfinis/back8sup
```
## Configuration

Back8sup is configured via environment variables inside the container and an additional configmap.

### Environment variables

```shell
API_ENDPOINT=${API_ENDPOINT:-https://kubernetes.local:6443}
CA_CERT=${CA_CERT:-/etc/ssl/ca.crt}
TOKEN_FILE=${TOKEN_FILE:-/var/run/secrets/sa}
DST_FOLDER=${DST_FOLDER:-/mnt/back8sup}
CONFIGMAP_PATH=${CONFIGMAP_PATH:-/etc/config.yaml}
EXPORT_FORMAT=${EXPORT_FORMAT:-yaml}
```

### ConfigMap

The configmap is managed by helm and configured in the `values.yaml` file.

Example configuration (see [`src/config.sample.yaml`](src/config.sample.yaml))

```yaml
global: ['cm', 'pvc', 'pv'] # global resources to export over all namespaces
namespaces:
  - name: default # per namespace resources to export
    kind: ['deployment']
  - name: infra-backup
    kind: ['deployment']
```
