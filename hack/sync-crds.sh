#!/bin/bash
# scripts/sync-crds.sh - Sync CRDs from butler-api into Helm chart templates
set -euo pipefail

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
    "butler.butlerlabs.dev_clusterbootstraps.yaml:clusterBootstrap:clusterbootstrap-crd.yaml"
    "butler.butlerlabs.dev_machinerequests.yaml:machineRequest:machinerequest-crd.yaml"
    "butler.butlerlabs.dev_providerconfigs.yaml:providerConfig:providerconfig-crd.yaml"
    "butler.butlerlabs.dev_tenantclusters.yaml:tenantCluster:tenantcluster-crd.yaml"
    "butler.butlerlabs.dev_tenantaddons.yaml:tenantAddon:tenantaddon-crd.yaml"
    "butler.butlerlabs.dev_teams.yaml:team:team-crd.yaml"
    "butler.butlerlabs.dev_butlerconfigs.yaml:butlerConfig:butlerconfig-crd.yaml"
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
    
    cat > "$dest" << EOF
{{/*
AUTO-GENERATED FROM butler-api - DO NOT EDIT
Source: config/crd/bases/$crd_file
*/}}
{{- if .Values.crds.${values_key} }}
EOF

    # Inject Helm labels after metadata.name
    sed '/^  name:/a\  labels:\n    {{- include "butler-crds.labels" . | nindent 4 }}' "$src" >> "$dest"
    
    echo "{{- end }}" >> "$dest"
    ((synced++))
done

echo "Done: $synced CRDs synced"
