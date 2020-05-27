# back8sup

A simple way to backup your kubernetes resources


## Deployment w/ HELM v3.x

```
helm repo add adfinis https://charts.adfinis.com
helm install back8sup adfinis/back8sup
```
## Configuration

Back8sup is configured via environment variables inside the container and an additional configmap.


### Environment variables

```
API_ENDPOINT=${API_ENDPOINT:-https://kubernetes.local:6443}
CA_CERT=${CA_CERT:-/etc/ssl/ca.crt}
TOKEN_FILE=${TOKEN_FILE:-/var/run/secrets/sa}
DST_FOLDER=${DST_FOLDER:-/mnt/back8sup}
CONFIGMAP_PATH=${CONFIGMAP_PATH:-/etc/config.yaml}
EXPORT_FORMAT=${EXPORT_FORMAT:-yaml}
```

### ConfigMap (managed by Helm)

```
global: ['cm', 'pvc', 'pv'] # global resources to export over all namespaces
namespaces:
  - name: default # per namespace resources to export
    kind: ['deployment']
  - name: infra-backup
    kind: ['deployment']
```
