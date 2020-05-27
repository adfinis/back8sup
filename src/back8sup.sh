#!/usr/bin/env bash

# -*- coding: utf-8 -*-
#
# back8sup - backup your k8s api resources easily on a PV of your choice
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

# check if binaries are available

if ! command -v kubectl >/dev/null
then 
  echo "$(date "+%FT%H:%M:%S") ERROR kubectl not found in \$PATH" 
  exit 1
fi
if ! command -v yq >/dev/null
then
  echo "$(date "+%FT%H:%M:%S") ERROR yq not found in \$PATH" 
  exit 1
fi
if ! command -v jq >/dev/null
then
  echo "$(date "+%FT%H:%M:%S") ERROR jq not found in \$PATH"
  exit 1
fi
if ! command -v yamllint >/dev/null
then 
  echo "$(date "+%FT%H:%M:%S") ERROR yamllint not found in \$PATH" 
  exit 1
fi

# create DST_FOLDER

DATE=$(date "+%Y%m%d%H%M")
DST="$DST_FOLDER/$DATE"
echo "$(date "+%FT%H:%M:%S") INFO creating directory $DST for export"
if ! mkdir -p "$DST"
then
  echo "$(date "+%FT%H:%M:%S") ERROR could not create $DST"
  exit 1
fi

# check TOKEN_FILE and connection

if [ ! -r "$TOKEN_FILE" ]
  then 
    echo "$(date "+%FT%H:%M:%S") ERROR $TOKEN_FILE not readable"
    exit 1
  fi

TOKEN=$(cat "$TOKEN_FILE")

echo "$(date "+%FT%H:%M:%S") INFO checking token and connection to cluster"
if ! curl -k "$API_ENDPOINT/version/" -H "Authorization: Bearer ${TOKEN}"
  then 
    echo "$(date "+%FT%H:%M:%S") ERROR couldn't reach the API endpoint."
    exit 1
fi

# first parse Configmap

if ! yamllint --no-warnings "$CONFIGMAP_PATH"
then
  echo "$(date "+%FT%H:%M:%S") ERROR yamllint unsuccessful" 
  exit 1
fi
echo "$(date "+%FT%H:%M:%S") INFO parsing $CONFIGMAP_PATH"
GLOBAL=$(yq -r '.global[]' "$CONFIGMAP_PATH")
NAMESPACES=$(yq -r '.namespaces[].name' "$CONFIGMAP_PATH")
echo "$(date "+%FT%H:%M:%S") INFO $CONFIGMAP_PATH parsed"

# first get all global stuff

echo "$(date "+%FT%H:%M:%S") INFO staring with global export"
for KIND in $GLOBAL 
do
  echo "$(date "+%FT%H:%M:%S") INFO starting export for all $KIND"
  kubectl get ns -oname | cut -d/ -f2 | while read -r NS
  do
    mkdir -p "$DST/$NS"
    for ITEM in $(kubectl get "$KIND" -n "$NS" -oname)
    do 
      echo "$(date "+%FT%H:%M:%S") INFO exporting $ITEM from namespace $NS into $DST/$NS/$KIND"
      mkdir -p "$DST/$NS/$KIND"
      kubectl get "$ITEM" -n "$NS" -o "$EXPORT_FORMAT" > "$DST/$NS/$KIND/$(basename "$ITEM").$EXPORT_FORMAT"
    done
  done
  echo "$(date "+%FT%H:%M:%S") INFO done exporting all $KIND"
done
echo "$(date "+%FT%H:%M:%S") INFO done with global export"

# now all namespaces stuff

for NS in $NAMESPACES
do
  echo "$(date "+%FT%H:%M:%S") INFO staring export in namespace $NS"
  # shellcheck disable=SC2016
  NSKINDS=$(yq -r --arg ns "$NS" '.namespaces[]|select(.name == $ns)|.kind[]' "$CONFIGMAP_PATH")
  for KIND in $NSKINDS
  do
    echo "$(date "+%FT%H:%M:%S") INFO starting export for all $KIND in namespace $NS"
    for ITEM in $(kubectl get "$KIND" -n "$NS" -oname)
    do
      echo "$(date "+%FT%H:%M:%S") INFO exporting $ITEM from namespace $NS into $DST/$NS/$KIND"
      mkdir -p "$DST/$NS/$KIND"
      kubectl get "$ITEM" -n "$NS" -o "$EXPORT_FORMAT" > "$DST/$NS/$KIND/$(basename "$ITEM").$EXPORT_FORMAT"
    done
  done
  echo "$(date "+%FT%H:%M:%S") INFO done exporting all $KIND in namespace $NS"
done
echo "$(date "+%FT%H:%M:%S") INFO done exporting namespace $NS"
