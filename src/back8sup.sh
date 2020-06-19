#!/usr/bin/env bash

# -*- coding: utf-8 -*-
#
# back8sup - backup your k8s api resources easily to a PV of your choice
#
# Copyright (C) 2020 Adfinis AG
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# SPDX-FileCopyrightText: 2020 Adfinis AG
# SPDX-License-Identifier: AGPL-3.0-or-later


# Environment variables for configuration

readonly API_ENDPOINT=${API_ENDPOINT:-https://kubernetes.local:6443}
readonly CA_CERT=${CA_CERT:-/etc/ssl/ca.crt}
readonly TOKEN_FILE=${TOKEN_FILE:-/var/run/secrets/sa}
readonly DST_FOLDER=${DST_FOLDER:-/mnt/back8sup}
readonly CONFIGMAP_PATH=${CONFIGMAP_PATH:-/etc/config.yaml}
readonly EXPORT_FORMAT=${EXPORT_FORMAT:-yaml}
readonly BINARIES="kubectl yq jq yamllint"
readonly NOTNAMESPACEDDIR=${NOTNAMESPACEDDIR:-not-namespaced}

# define log function

log(){
  NOW=$(date "+%FT%H:%M:%S")
  echo "$NOW" "$@"
}

# check if binaries are available

for BIN in $BINARIES
do
  if ! command -v "$BIN" >/dev/null
  then
    log "ERROR $BIN not found in \$PATH"
    exit 1
  fi
done

# create DST_FOLDER

DATE=$(date "+%Y%m%d%H%M")
DST="$DST_FOLDER/$DATE"
log "INFO creating directory $DST for export"
if ! mkdir -p "$DST"
then
  log "ERROR could not create $DST"
  exit 1
fi

# check TOKEN_FILE and connection

if [ ! -r "$TOKEN_FILE" ]
then
  log "ERROR $TOKEN_FILE not readable"
  exit 1
fi

TOKEN=$(cat "$TOKEN_FILE")

log "INFO checking token and connection to cluster"
if ! curl -k "$API_ENDPOINT/version/" -H "Authorization: Bearer ${TOKEN}"
then
  log "ERROR couldn't reach the API endpoint."
  exit 1
fi

# first parse Configmap

if ! yamllint --no-warnings "$CONFIGMAP_PATH"
then
  log "ERROR yamllint unsuccessful" 
  exit 1
fi
log "INFO parsing $CONFIGMAP_PATH"
GLOBAL=$(yq -r '.global[]' "$CONFIGMAP_PATH")
NAMESPACES=$(yq -r '.namespaces[].name' "$CONFIGMAP_PATH")
log "INFO $CONFIGMAP_PATH parsed"

# first get all global stuff

log "INFO starting with global export"
for KIND in $GLOBAL
do
  log "INFO starting export for all $KIND"
  # first check if resources is not namespaced 
  if kubectl api-resources --namespaced=false | grep "$KIND "
  then 
    mkdir -p "$DST/$NOTNAMESPACEDDIR"
    for ITEM IN $(kubectl get "$KIND" -oname)
      do 
        log "INFO exporting non-namespaced $ITEM into $DST/$NOTNAMESPACEDDIR"
        mkdir -p "$DST/$NS/$KIND"
        kubectl get "$ITEM" -n "$NS" -o "$EXPORT_FORMAT" > "$DST/$NS/$KIND/$(basename "$ITEM").$EXPORT_FORMAT"
      done
  else
  kubectl get ns -oname | cut -d/ -f2 | while read -r NS
  do
    mkdir -p "$DST/$NS"
    for ITEM in $(kubectl get "$KIND" -n "$NS" -oname)
    do 
      log "INFO exporting $ITEM from namespace $NS into $DST/$NS/$KIND"
      mkdir -p "$DST/$NS/$KIND"
      kubectl get "$ITEM" -n "$NS" -o "$EXPORT_FORMAT" > "$DST/$NS/$KIND/$(basename "$ITEM").$EXPORT_FORMAT"
    done
  done
  log "INFO done exporting all $KIND"
  fi
done
log "INFO done with global export"

# now all namespaces stuff

for NS in $NAMESPACES
do
  log "INFO starting export in namespace $NS"
  # shellcheck disable=SC2016
  NSKINDS=$(yq -r --arg ns "$NS" '.namespaces[]|select(.name == $ns)|.kind[]' "$CONFIGMAP_PATH")
  for KIND in $NSKINDS
  do
    log "INFO starting export for all $KIND in namespace $NS"
    for ITEM in $(kubectl get "$KIND" -n "$NS" -oname)
    do
      log "INFO exporting $ITEM from namespace $NS into $DST/$NS/$KIND"
      mkdir -p "$DST/$NS/$KIND"
      kubectl get "$ITEM" -n "$NS" -o "$EXPORT_FORMAT" > "$DST/$NS/$KIND/$(basename "$ITEM").$EXPORT_FORMAT"
    done
  done
  log "INFO done exporting all $KIND in namespace $NS"
done
log "INFO done exporting namespace $NS"
