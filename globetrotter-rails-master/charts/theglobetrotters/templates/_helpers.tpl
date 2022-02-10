{{/*
Expand the name of the chart.
*/}}
{{- define "theglobetrotters.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "theglobetrotters.fullname" -}}
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
{{- define "theglobetrotters.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "theglobetrotters.rails.labels" -}}
helm.sh/chart: {{ include "theglobetrotters.chart" . }}
{{ include "theglobetrotters.rails.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "theglobetrotters.rails-active-job.labels" -}}
helm.sh/chart: {{ include "theglobetrotters.chart" . }}
{{ include "theglobetrotters.rails-active-job.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "theglobetrotters.traefik.labels" -}}
helm.sh/chart: {{ include "theglobetrotters.chart" . }}
{{ include "theglobetrotters.traefik.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "theglobetrotters.postgres.labels" -}}
helm.sh/chart: {{ include "theglobetrotters.chart" . }}
{{ include "theglobetrotters.postgres.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "theglobetrotters.database-upgrade.labels" -}}
helm.sh/chart: {{ include "theglobetrotters.chart" . }}
{{ include "theglobetrotters.database-upgrade.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "theglobetrotters.database-backup.labels" -}}
helm.sh/chart: {{ include "theglobetrotters.chart" . }}
{{ include "theglobetrotters.database-backup.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}


{{/*
Selector labels
*/}}
{{- define "theglobetrotters.rails.selectorLabels" -}}
service: rails
app.kubernetes.io/name: rails
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "theglobetrotters.rails-active-job.selectorLabels" -}}
service: "rails-active-job"
app.kubernetes.io/name: "rails-active-job"
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "theglobetrotters.traefik.selectorLabels" -}}
service: traefik
app.kubernetes.io/name: traefik
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "theglobetrotters.postgres.selectorLabels" -}}
service: postgres
app.kubernetes.io/name: postgres
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "theglobetrotters.database-upgrade.selectorLabels" -}}
service: "database-upgrade"
app.kubernetes.io/name: "database-upgrade"
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "theglobetrotters.database-backup.selectorLabels" -}}
service: "database-backup"
app.kubernetes.io/name: "database-backup"
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "theglobetrotters.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "theglobetrotters.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
