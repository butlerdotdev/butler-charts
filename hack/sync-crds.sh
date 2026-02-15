#!/bin/bash
# hack/sync-crds.sh - Sync CRDs from butler-api into Helm chart templates
# Copyright 2026 The Butler Authors.
# SPDX-License-Identifier: Apache-2.0
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUTLER_API_PATH="${1:-${BUTLER_API_PATH:-$REPO_ROOT/../butler-api}}"
CRD_SOURCE="$BUTLER_API_PATH/config/crd/bases"
CRD_DEST="$REPO_ROOT/charts/butler-crds/templates"

if [[ ! -d "$CRD_SOURCE" ]]; then
    echo "ERROR: CRD source not found: $CRD_SOURCE"
    exit 1
fi

echo "Syncing CRDs from: $CRD_SOURCE"

declare -a CRD_MAPPINGS=(
    "butler.butlerlabs.dev_addondefinitions.yaml:addonDefinition:addondefinition-crd.yaml"
    "butler.butlerlabs.dev_butlerconfigs.yaml:butlerConfig:butlerconfig-crd.yaml"
    "butler.butlerlabs.dev_clusterbootstraps.yaml:clusterBootstrap:clusterbootstrap-crd.yaml"
    "butler.butlerlabs.dev_identityproviders.yaml:identityProvider:identityprovider-crd.yaml"
    "butler.butlerlabs.dev_ipallocations.yaml:ipAllocation:ipallocation-crd.yaml"
    "butler.butlerlabs.dev_machinerequests.yaml:machineRequest:machinerequest-crd.yaml"
    "butler.butlerlabs.dev_managementaddons.yaml:managementAddon:managementaddon-crd.yaml"
    "butler.butlerlabs.dev_networkpools.yaml:networkPool:networkpool-crd.yaml"
    "butler.butlerlabs.dev_providerconfigs.yaml:providerConfig:providerconfig-crd.yaml"
    "butler.butlerlabs.dev_teams.yaml:team:team-crd.yaml"
    "butler.butlerlabs.dev_tenantaddons.yaml:tenantAddon:tenantaddon-crd.yaml"
    "butler.butlerlabs.dev_tenantclusters.yaml:tenantCluster:tenantcluster-crd.yaml"
    "butler.butlerlabs.dev_users.yaml:user:user-crd.yaml"
    "butler.butlerlabs.dev_workspaces.yaml:workspace:workspace-crd.yaml"
    "butler.butlerlabs.dev_workspacetemplates.yaml:workspaceTemplate:workspacetemplate-crd.yaml"
)

synced=0

for mapping in "${CRD_MAPPINGS[@]}"; do
    IFS=':' read -r crd_file values_key template_name <<< "$mapping"
    
    src="$CRD_SOURCE/$crd_file"
    dest="$CRD_DEST/$template_name"
    
    if [[ ! -f "$src" ]]; then
        echo "SKIP: $crd_file (not found)"
        continue
    fi
    
    echo "SYNC: $crd_file → $template_name"
    
    # Write header
    cat > "$dest" << EOF
{{/*
AUTO-GENERATED FROM butler-api - DO NOT EDIT
Source: config/crd/bases/$crd_file
*/}}
{{- if .Values.crds.${values_key} }}
EOF

    # Append CRD content with Helm labels injected after metadata.name
    awk '
        /controller-gen\.kubebuilder\.io\/version:/ {
            print
            print "    {{- include \"butler-crds.annotations\" . | nindent 4 }}"
            next
        }
        /^  name:.*butler\.butlerlabs\.dev$/ {
            print "  labels:"
            print "    {{- include \"butler-crds.labels\" . | nindent 4 }}"
            print
            next
        }
        { print }
    ' "$src" >> "$dest"
    
    echo "{{- end }}" >> "$dest"
    synced=$((synced + 1))
done

echo "Done: $synced CRDs synced"
exit 0
