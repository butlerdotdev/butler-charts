{{/*
Copyright 2026 The Butler Authors.
SPDX-License-Identifier: Apache-2.0
*/}}
{{/*
Expand the name of the chart.
*/}}
{{- define "butler-addons.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}
{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "butler-addons.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}
{{/*
Common labels
*/}}
{{- define "butler-addons.labels" -}}
helm.sh/chart: {{ include "butler-addons.chart" . }}
app.kubernetes.io/name: {{ include "butler-addons.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: butler
{{- end }}
