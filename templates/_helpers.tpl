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
