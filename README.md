# back8sup

A simple way to backup your kubernetes resources


## Deployment w/ HELM v3.x

```
helm install back8sup charts/back8sup
```
## Configuration

Configuration is done via environment variables inside the container and an additional configmap


### Environment variables

```
API_ENDPOINT=${API_ENDPOINT:-https://kubernetes.local:6443}
CA_CERT=${CA_CERT:-/etc/ssl/ca.crt}
TOKEN_FILE=${TOKEN_FILE:-/var/run/secrets/sa}
DST_FOLDER=${DST_FOLDER:-/mnt/back8sup}
CONFIGMAP_PATH=${CONFIGMAP_PATH:-/etc/config.yaml}
EXPORT_FORMAT=${EXPORT_FORMAT:-yaml}
```

### ConfigMap

```
global: ['cm', 'pvc', 'pv'] # global resources to export over all namespaces
namespaces:
  - name: default # per namespace resources to export
    kind: ['deployment']
  - name: infra-backup
    kind: ['deployment']
```
