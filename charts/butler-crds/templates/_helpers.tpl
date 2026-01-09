{{/*
Copyright 2026 The Butler Authors.
SPDX-License-Identifier: Apache-2.0
*/}}

{{/*
Expand the name of the chart.
*/}}
{{- define "butler-crds.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "butler-crds.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels for all CRDs
*/}}
{{- define "butler-crds.labels" -}}
helm.sh/chart: {{ include "butler-crds.chart" . }}
app.kubernetes.io/name: {{ include "butler-crds.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: butler
{{- with .Values.labels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
CRD annotations including resource policy
*/}}
{{- define "butler-crds.annotations" -}}
{{- if .Values.keep }}
"helm.sh/resource-policy": keep
{{- end }}
{{- with .Values.annotations }}
{{ toYaml . }}
{{- end }}
{{- end }}
