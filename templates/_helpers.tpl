{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}

{{- define "forgejo.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "forgejo.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "forgejo.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Get version from .Values.image.tag or Chart.AppVersion.
Trim optional docker digest.
*/}}
{{- define "forgejo.version" -}}
{{- regexReplaceAll "@.+" (.Values.image.tag | default .Chart.AppVersion | toString) "" -}}
{{- end -}}

{{/*
Create image name and tag used by the deployment.
*/}}
{{- define "forgejo.image" -}}
{{- $fullOverride := .Values.image.fullOverride | default "" -}}
{{- $registry := .Values.global.imageRegistry | default .Values.image.registry -}}
{{- $repository := .Values.image.repository -}}
{{- $separator := ":" -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion | toString -}}
{{- $rootless := ternary "-rootless" "" (.Values.image.rootless) -}}
{{- $digest := "" -}}
{{- if .Values.image.digest }}
    {{- $digest = (printf "@%s" (.Values.image.digest | toString)) -}}
{{- end -}}
{{- if $fullOverride }}
    {{- printf "%s" $fullOverride -}}
{{- else if $registry }}
    {{- printf "%s/%s%s%s%s%s" $registry $repository $separator $tag $rootless $digest -}}
{{- else -}}
    {{- printf "%s%s%s%s%s" $repository $separator $tag $rootless $digest -}}
{{- end -}}
{{- end -}}

{{/*
Docker Image Registry Secret Names evaluating values as templates
*/}}
{{- define "forgejo.images.pullSecrets" -}}
{{- $pullSecrets := .Values.imagePullSecrets -}}
{{- range .Values.global.imagePullSecrets -}}
    {{- $pullSecrets = append $pullSecrets (dict "name" .) -}}
{{- end -}}
{{- if (not (empty $pullSecrets)) }}
imagePullSecrets:
{{ toYaml $pullSecrets }}
{{- end }}
{{- end -}}


{{/*
Storage Class
*/}}
{{- define "forgejo.persistence.storageClass" -}}
{{- $storageClass :=  (tpl ( default "" .Values.persistence.storageClass) .) | default (tpl ( default "" .Values.global.storageClass) .) }}
{{- if $storageClass }}
storageClassName: {{ $storageClass | quote }}
{{- end }}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "forgejo.labels" -}}
helm.sh/chart: {{ include "forgejo.chart" . }}
app: {{ include "forgejo.name" . }}
{{ include "forgejo.selectorLabels" . }}
app.kubernetes.io/version: {{ include "forgejo.version" . | quote }}
version: {{ include "forgejo.version" . | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "forgejo.selectorLabels" -}}
app.kubernetes.io/name: {{ include "forgejo.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "forgejo.default_domain" -}}
{{- printf "%s-http.%s.svc.%s" (include "forgejo.fullname" .) .Release.Namespace .Values.clusterDomain -}}
{{- end -}}

{{- define "forgejo.ldap_settings" -}}
{{- $idx := index . 0 }}
{{- $values := index . 1 }}

{{- if not (hasKey $values "bindDn") -}}
{{- $_ := set $values "bindDn" "" -}}
{{- end -}}

{{- if not (hasKey $values "bindPassword") -}}
{{- $_ := set $values "bindPassword" "" -}}
{{- end -}}

{{- $flags := list "notActive" "skipTlsVerify" "allowDeactivateAll" "synchronizeUsers" "attributesInBind" -}}
{{- range $key, $val := $values -}}
{{- if and (ne $key "enabled") (ne $key "existingSecret") -}}
{{- if eq $key "bindDn" -}}
{{- printf "--%s \"${GITEA_LDAP_BIND_DN_%d}\" " ($key | kebabcase) ($idx) -}}
{{- else if eq $key "bindPassword" -}}
{{- printf "--%s \"${GITEA_LDAP_PASSWORD_%d}\" " ($key | kebabcase) ($idx) -}}
{{- else if eq $key "port" -}}
{{- printf "--%s %d " $key ($val | int) -}}
{{- else if has $key $flags -}}
{{- printf "--%s " ($key | kebabcase) -}}
{{- else -}}
{{- printf "--%s %s " ($key | kebabcase) ($val | squote) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "forgejo.oauth_settings" -}}
{{- $idx := index . 0 }}
{{- $values := index . 1 }}

{{- if not (hasKey $values "key") -}}
{{- $_ := set $values "key" (printf "${GITEA_OAUTH_KEY_%d}" $idx) -}}
{{- end -}}

{{- if not (hasKey $values "secret") -}}
{{- $_ := set $values "secret" (printf "${GITEA_OAUTH_SECRET_%d}" $idx) -}}
{{- end -}}

{{- $flags := list "skipLocal-2fa" "groupTeamMapRemoval" "skip-local-2fa" "group-team-map-removal" -}}
{{- range $key, $val := $values -}}
{{- if has $key $flags -}}
{{- printf "--%s " ($key | kebabcase) -}}
{{- else if ne $key "existingSecret" -}}
{{- printf "--%s %s " ($key | kebabcase) ($val | quote) -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "forgejo.public_protocol" -}}
{{- if and .Values.ingress.enabled (gt (len .Values.ingress.tls) 0) -}}
https
{{- else -}}
{{ .Values.gitea.config.server.PROTOCOL }}
{{- end -}}
{{- end -}}

{{- define "forgejo.inline_configuration" -}}
  {{- include "forgejo.inline_configuration.init" . -}}
  {{- include "forgejo.inline_configuration.defaults" . -}}

  {{- $generals := list -}}
  {{- $inlines := dict -}}

  {{- range $key, $value := .Values.gitea.config  }}
    {{- if kindIs "map" $value }}
      {{- if gt (len $value) 0 }}
        {{- $section := default list (get $inlines $key) -}}
        {{- range $n_key, $n_value := $value }}
          {{- $section = append $section (printf "%s=%v" $n_key $n_value) -}}
        {{- end }}
        {{- $_ := set $inlines $key (join "\n" $section) -}}
      {{- end -}}
    {{- else }}
      {{- if or (eq $key "APP_NAME") (eq $key "RUN_USER") (eq $key "RUN_MODE") (eq $key "APP_SLOGAN") (eq $key "APP_DISPLAY_NAME_FORMAT") -}}
        {{- $generals = append $generals (printf "%s=%s" $key $value) -}}
      {{- else -}}
        {{- (printf "Key %s cannot be on top level of configuration" $key) | fail -}}
      {{- end -}}

    {{- end }}
  {{- end }}

  {{- $_ := set $inlines "_generals_" (join "\n" $generals) -}}
  {{- toYaml $inlines -}}
{{- end -}}

{{- define "forgejo.inline_configuration.init" -}}
  {{- if not (hasKey .Values.gitea.config "cache") -}}
    {{- $_ := set .Values.gitea.config "cache" dict -}}
  {{- end -}}
  {{- if not (hasKey .Values.gitea.config "server") -}}
    {{- $_ := set .Values.gitea.config "server" dict -}}
  {{- end -}}
  {{- if not (hasKey .Values.gitea.config "metrics") -}}
    {{- $_ := set .Values.gitea.config "metrics" dict -}}
  {{- end -}}
  {{- if not (hasKey .Values.gitea.config "database") -}}
    {{- $_ := set .Values.gitea.config "database" dict -}}
  {{- end -}}
  {{- if not (hasKey .Values.gitea.config "security") -}}
    {{- $_ := set .Values.gitea.config "security" dict -}}
  {{- end -}}
  {{- if not .Values.gitea.config.repository -}}
    {{- $_ := set .Values.gitea.config "repository" dict -}}
  {{- end -}}
  {{- if not (hasKey .Values.gitea.config "oauth2") -}}
    {{- $_ := set .Values.gitea.config "oauth2" dict -}}
  {{- end -}}
  {{- if not (hasKey .Values.gitea.config "session") -}}
    {{- $_ := set .Values.gitea.config "session" dict -}}
  {{- end -}}
  {{- if not (hasKey .Values.gitea.config "queue") -}}
    {{- $_ := set .Values.gitea.config "queue" dict -}}
  {{- end -}}
  {{- if not (hasKey .Values.gitea.config "queue.issue_indexer") -}}
    {{- $_ := set .Values.gitea.config "queue.issue_indexer" dict -}}
  {{- end -}}
  {{- if not (hasKey .Values.gitea.config "indexer") -}}
    {{- $_ := set .Values.gitea.config "indexer" dict -}}
  {{- end -}}
{{- end -}}

{{- define "forgejo.inline_configuration.defaults" -}}
  {{- include "forgejo.inline_configuration.defaults.server" . -}}

  {{- if not .Values.gitea.config.database.DB_TYPE -}}
    {{- $_ := set .Values.gitea.config.database "DB_TYPE" "sqlite3" -}}
  {{- end -}}  

  {{- if not .Values.gitea.config.repository.ROOT -}}
    {{- $_ := set .Values.gitea.config.repository "ROOT" "/data/git/gitea-repositories" -}}
  {{- end -}}
  {{- if not .Values.gitea.config.security.INSTALL_LOCK -}}
    {{- $_ := set .Values.gitea.config.security "INSTALL_LOCK" "true" -}}
  {{- end -}}
  {{- if not (hasKey .Values.gitea.config.metrics "ENABLED") -}}
    {{- $_ := set .Values.gitea.config.metrics "ENABLED" .Values.gitea.metrics.enabled -}}
  {{- end -}}
  
  {{- if not (get .Values.gitea.config.session "PROVIDER") -}}
    {{- $_ := set .Values.gitea.config.session "PROVIDER" "memory" -}}
  {{- end -}}
  {{- if not (get .Values.gitea.config.session "PROVIDER_CONFIG") -}}
    {{- $_ := set .Values.gitea.config.session "PROVIDER_CONFIG" "" -}}
  {{- end -}}
  {{- if not (get .Values.gitea.config.queue "TYPE") -}}
    {{- $_ := set .Values.gitea.config.queue "TYPE" "level" -}}
  {{- end -}}
  {{- if not (get .Values.gitea.config.queue "CONN_STR") -}}
    {{- $_ := set .Values.gitea.config.queue "CONN_STR" "" -}}
  {{- end -}}
  {{- if not (get .Values.gitea.config.cache "ADAPTER") -}}
    {{- $_ := set .Values.gitea.config.cache "ADAPTER" "memory" -}}
  {{- end -}}
  {{- if not (get .Values.gitea.config.cache "HOST") -}}
    {{- $_ := set .Values.gitea.config.cache "HOST" "" -}}
  {{- end -}}

  {{- if not .Values.gitea.config.indexer.ISSUE_INDEXER_TYPE -}}
     {{- $_ := set .Values.gitea.config.indexer "ISSUE_INDEXER_TYPE" "db" -}}
  {{- end -}}
{{- end -}}

{{- define "forgejo.inline_configuration.defaults.server" -}}
  {{- if not (hasKey .Values.gitea.config.server "HTTP_PORT") -}}
    {{- $_ := set .Values.gitea.config.server "HTTP_PORT" .Values.service.http.port -}}
  {{- end -}}
  {{- if not .Values.gitea.config.server.PROTOCOL -}}
    {{- $_ := set .Values.gitea.config.server "PROTOCOL" "http" -}}
  {{- end -}}
  {{- if not (.Values.gitea.config.server.DOMAIN) -}}
    {{- if gt (len .Values.ingress.hosts) 0 -}}
      {{- $_ := set .Values.gitea.config.server "DOMAIN" ( tpl (index .Values.ingress.hosts 0).host $) -}}
    {{- else -}}
      {{- $_ := set .Values.gitea.config.server "DOMAIN" (include "forgejo.default_domain" .) -}}
    {{- end -}}
  {{- end -}}
  {{- if not .Values.gitea.config.server.ROOT_URL -}}
    {{- $_ := set .Values.gitea.config.server "ROOT_URL" (printf "%s://%s" (include "forgejo.public_protocol" .) .Values.gitea.config.server.DOMAIN) -}}
  {{- end -}}
  {{- if not .Values.gitea.config.server.SSH_DOMAIN -}}
    {{- $_ := set .Values.gitea.config.server "SSH_DOMAIN" .Values.gitea.config.server.DOMAIN -}}
  {{- end -}}
  {{- if not .Values.gitea.config.server.SSH_PORT -}}
    {{- $_ := set .Values.gitea.config.server "SSH_PORT" .Values.service.ssh.port -}}
  {{- end -}}
  {{- if not (hasKey .Values.gitea.config.server "SSH_LISTEN_PORT") -}}
    {{- if not .Values.image.rootless -}}
      {{- $_ := set .Values.gitea.config.server "SSH_LISTEN_PORT" .Values.gitea.config.server.SSH_PORT -}}
    {{- else -}}
      {{- $_ := set .Values.gitea.config.server "SSH_LISTEN_PORT" "2222" -}}
    {{- end -}}
  {{- end -}}
  {{- if not (hasKey .Values.gitea.config.server "START_SSH_SERVER") -}}
    {{- if .Values.image.rootless -}}
      {{- $_ := set .Values.gitea.config.server "START_SSH_SERVER" "true" -}}
    {{- end -}}
  {{- end -}}
  {{- if not (hasKey .Values.gitea.config.server "APP_DATA_PATH") -}}
    {{- $_ := set .Values.gitea.config.server "APP_DATA_PATH" "/data" -}}
  {{- end -}}
  {{- if not (hasKey .Values.gitea.config.server "ENABLE_PPROF") -}}
    {{- $_ := set .Values.gitea.config.server "ENABLE_PPROF" false -}}
  {{- end -}}
{{- end -}}

{{- define "forgejo.init-additional-mounts" -}}
  {{- /* Honor the deprecated extraVolumeMounts variable when defined */ -}}
  {{- if gt (len .Values.extraInitVolumeMounts) 0 -}}
    {{- toYaml .Values.extraInitVolumeMounts -}}
  {{- else if gt (len .Values.extraVolumeMounts) 0 -}}
    {{- toYaml .Values.extraVolumeMounts -}}
  {{- end -}}
{{- end -}}

{{- define "forgejo.container-additional-mounts" -}}
  {{- /* Honor the deprecated extraVolumeMounts variable when defined */ -}}
  {{- if gt (len .Values.extraContainerVolumeMounts) 0 -}}
    {{- toYaml .Values.extraContainerVolumeMounts -}}
  {{- else if gt (len .Values.extraVolumeMounts) 0 -}}
    {{- toYaml .Values.extraVolumeMounts -}}
  {{- end -}}
{{- end -}}

{{- define "forgejo.gpg-key-secret-name" -}}
{{ default (printf "%s-gpg-key" (include "forgejo.fullname" .)) .Values.signing.existingSecret }}
{{- end -}}

{{- define "forgejo.serviceAccountName" -}}
{{ .Values.serviceAccount.name | default (include "forgejo.fullname" .) }}
{{- end -}}

{{- define "forgejo.admin.passwordMode" -}}
{{- if has .Values.gitea.admin.passwordMode (tuple "keepUpdated" "initialOnlyNoReset" "initialOnlyRequireReset") -}}
{{ .Values.gitea.admin.passwordMode }}
{{- else -}}
{{ printf "gitea.admin.passwordMode must be set to one of 'keepUpdated', 'initialOnlyNoReset', or 'initialOnlyRequireReset'. Received: '%s'" .Values.gitea.admin.passwordMode | fail }}
{{- end -}}
{{- end -}}
