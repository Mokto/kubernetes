apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: pelias-interpolation
spec:
  replicas: {{ .Values.interpolation.replicas }}
  minReadySeconds: {{ .Values.interpolation.minReadySeconds }}
  strategy:
    rollingUpdate:
      maxSurge: {{ .Values.interpolation.maxSurge }}
      maxUnavailable: {{ .Values.interpolation.maxUnavailable }}
  template:
    metadata:
      labels:
        app: pelias-interpolation
      annotations:
{{- if .Values.interpolation.annotations }}
{{ toYaml .Values.interpolation.annotations | indent 8 }}
{{- end }}
    spec:
      initContainers:
        - name: download
          image: busybox
          command: [ "sh", "-c",
            "mkdir -p /data/interpolation/ &&\n
             wget -O - {{ .Values.interpolation.downloadPath }}/street.db.gz | gunzip > /data/interpolation/street.db &\n
             wget -O - {{ .Values.interpolation.downloadPath }}/address.db.gz | gunzip > /data/interpolation/address.db" ]
          volumeMounts:
            - name: data-volume
              mountPath: /data
          resources:
            limits:
              memory: 3Gi
              cpu: 2
            requests:
              memory: 512Mi
              cpu: 0.1
      containers:
        - name: pelias-interpolation
          image: pelias/interpolation:{{ .Values.interpolation.dockerTag }}
          volumeMounts:
            - name: data-volume
              mountPath: /data
          resources:
            limits:
              memory: 3Gi
              cpu: 2
            requests:
              memory: 2Gi
              cpu: 0.1
      volumes:
        - name: data-volume
        {{- if .Values.interpolation.pvc.create }}
          persistentVolumeClaim:
          claimName: {{ .Values.interpolation.pvc.name }}
        {{- else }}
          emptyDir: {}
        {{- end }}
