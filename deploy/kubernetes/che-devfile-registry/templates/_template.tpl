{{- define "devfile.hostname" -}}
{{- .Values.hostnameOverride | default (printf "devfile-registry-%s" .Release.Namespace) -}}
{{- end -}}
