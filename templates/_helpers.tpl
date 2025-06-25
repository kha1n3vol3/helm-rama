{{/*
Generate a range of integers.
*/}}
{{- define "until" -}}
{{- $end := . -}}
{{- $result := slice -}}
{{- range $i, $e := until $end -}}
{{- $result = append $result $i -}}
{{- end -}}
{{- $result -}}
{{- end -}}

{{/*
Assert that the cluster k3s version meets the minimum requirement.
This check runs at template rendering time (pre-install/pre-upgrade).
*/}}
{{- define "assert.k3sVersion" -}}
{{- if .Values.k3s.minVersion }}
  {{- $required := .Values.k3s.minVersion -}}
  {{- $current := .Capabilities.KubeVersion.Version -}}
  {{- if semverCompare (printf "<%s" $required) $current }}
    {{- fail (printf "k3s version %s is less than required %s" $current $required) -}}
  {{- end -}}
{{- end -}}
{{- end -}}
