{{/*
Copyright 2026 The Butler Authors.
SPDX-License-Identifier: Apache-2.0
*/}}

{{/*
Expand the name of the chart.
*/}}
{{- define "butler-console.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "butler-console.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "butler-console.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "butler-console.labels" -}}
helm.sh/chart: {{ include "butler-console.chart" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: butler
{{- end }}

{{/*
Server labels
*/}}
{{- define "butler-console.server.labels" -}}
{{ include "butler-console.labels" . }}
{{ include "butler-console.server.selectorLabels" . }}
{{- end }}

{{/*
Server selector labels
*/}}
{{- define "butler-console.server.selectorLabels" -}}
app.kubernetes.io/name: {{ include "butler-console.name" . }}-server
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: server
{{- end }}

{{/*
Frontend labels
*/}}
{{- define "butler-console.frontend.labels" -}}
{{ include "butler-console.labels" . }}
{{ include "butler-console.frontend.selectorLabels" . }}
{{- end }}

{{/*
Frontend selector labels
*/}}
{{- define "butler-console.frontend.selectorLabels" -}}
app.kubernetes.io/name: {{ include "butler-console.name" . }}-frontend
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: frontend
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "butler-console.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "butler-console.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Server image reference
*/}}
{{- define "butler-console.server.image" -}}
{{- $tag := .Values.server.image.tag | default .Chart.AppVersion }}
{{- printf "%s:%s" .Values.server.image.repository $tag }}
{{- end }}

{{/*
Frontend image reference
*/}}
{{- define "butler-console.frontend.image" -}}
{{- $tag := .Values.frontend.image.tag | default .Chart.AppVersion }}
{{- printf "%s:%s" .Values.frontend.image.repository $tag }}
{{- end }}

{{/*
Server fullname
*/}}
{{- define "butler-console.server.fullname" -}}
{{- printf "%s-server" (include "butler-console.fullname" .) }}
{{- end }}

{{/*
Frontend fullname
*/}}
{{- define "butler-console.frontend.fullname" -}}
{{- printf "%s-frontend" (include "butler-console.fullname" .) }}
{{- end }}
