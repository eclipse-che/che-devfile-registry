{{- define "devfile.hostname" -}}
{{- .Values.hostnameOverride | default (printf "che-devfile-registry-%s" .Release.Namespace) -}}
{{- end -}}
