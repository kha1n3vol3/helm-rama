{{- define "shared.initContainer.copyRelease" }}
- name: copy-release
  image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
  imagePullPolicy: "{{ .Values.image.pullPolicy }}"
  command: ["/bin/sh"]
  args:
    - "-c"
    - >-
      [ -f /data/rama/rama ] || (mkdir -p /data/rama &&
      cp /home/rama/rama-{{ .Values.image.tag }}.zip /data/rama/ &&
      cd /data/rama &&
      unzip rama-{{ .Values.image.tag }}.zip)
  volumeMounts:
  - name: rama-data
    mountPath: /data/rama
{{- end }}
