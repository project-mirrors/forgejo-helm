{{/*
Helper to get Forgejo configuration with backward compatibility for gitea:
Usage: {{ include "forgejo.config" . }}
Returns the forgejo configuration, falling back to gitea configuration if forgejo is not defined
*/}}
{{- define "forgejo.config" -}}
{{- if .Values.forgejo -}}
  {{- .Values.forgejo | toYaml -}}
{{- else if .Values.gitea -}}
  {{- .Values.gitea | toYaml -}}
{{- else -}}
  {{- dict | toYaml -}}
{{- end -}}
{{- end -}}

{{/*
Check if using deprecated gitea: section and emit warning
*/}}
{{- define "forgejo.checkDeprecation" -}}
{{- if and .Values.gitea (not .Values.forgejo) -}}
  {{- printf "\n\n⚠️  DEPRECATION WARNING: The 'gitea:' configuration section is deprecated and will be removed in a future release.\nPlease rename 'gitea:' to 'forgejo:' in your values.yaml file.\n\n" -}}
{{- end -}}
{{- end -}}

{{/*
Merge forgejo/gitea config into Values for backward compatibility
This allows existing templates to continue working
*/}}
{{- define "forgejo.mergeConfig" -}}
{{- if .Values.forgejo -}}
  {{- $_ := set .Values "gitea" .Values.forgejo -}}
{{- else if not .Values.gitea -}}
  {{- $_ := set .Values "gitea" dict -}}
{{- end -}}
{{- if not .Values.gitea -}}
  {{- $_ := set .Values "gitea" dict -}}
{{- end -}}
{{- if not .Values.gitea.admin -}}
  {{- $_ := set .Values.gitea "admin" dict -}}
{{- end -}}
{{- if not .Values.gitea.metrics -}}
  {{- $_ := set .Values.gitea "metrics" dict -}}
{{- end -}}
{{- if not .Values.gitea.config -}}
  {{- $_ := set .Values.gitea "config" dict -}}
{{- end -}}
{{- if not .Values.gitea.config.server -}}
  {{- $_ := set .Values.gitea.config "server" dict -}}
{{- end -}}
{{- if not .Values.gitea.config.server.SSH_LISTEN_PORT -}}
  {{- $_ := set .Values.gitea.config.server "SSH_LISTEN_PORT" 2222 -}}
{{- end -}}
{{- if not .Values.gitea.livenessProbe -}}
  {{- $_ := set .Values.gitea "livenessProbe" dict -}}
{{- end -}}
{{- if not .Values.gitea.readinessProbe -}}
  {{- $_ := set .Values.gitea "readinessProbe" dict -}}
{{- end -}}
{{- if not .Values.gitea.startupProbe -}}
  {{- $_ := set .Values.gitea "startupProbe" dict -}}
{{- end -}}
{{- if not .Values.gitea.ldap -}}
  {{- $_ := set .Values.gitea "ldap" list -}}
{{- end -}}
{{- if not .Values.gitea.oauth -}}
  {{- $_ := set .Values.gitea "oauth" list -}}
{{- end -}}
{{- if not .Values.gitea.additionalConfigSources -}}
  {{- $_ := set .Values.gitea "additionalConfigSources" list -}}
{{- end -}}
{{- if not .Values.gitea.additionalConfigFromEnvs -}}
  {{- $_ := set .Values.gitea "additionalConfigFromEnvs" list -}}
{{- end -}}
{{- if not .Values.gitea.podAnnotations -}}
  {{- $_ := set .Values.gitea "podAnnotations" dict -}}
{{- end -}}
{{- if not .Values.gitea.ssh -}}
  {{- $_ := set .Values.gitea "ssh" dict -}}
{{- end -}}
{{- end -}}