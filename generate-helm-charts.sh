#!/bin/bash
# Generate Helm charts for all services

set -e

SERVICES=("ca" "ra" "keymgr" "enroll" "ocsp" "crl" "policy" "auth" "audit" "notify")

for svc in "${SERVICES[@]}"; do
  echo "Generating Helm chart for $svc..."
  
  # Create directories
  mkdir -p "charts/$svc/templates"
  
  # Chart.yaml
  cat > "charts/$svc/Chart.yaml" <<EOF
apiVersion: v2
name: $svc
description: GigVault $svc service
type: application
version: 1.0.0
appVersion: "1.0.0"
EOF

  # values.yaml
  cat > "charts/$svc/values.yaml" <<EOF
replicaCount: 1

image:
  repository: gigvault/$svc
  tag: local
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 8080

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi

env:
  - name: CONFIG_PATH
    value: /config/config.yaml

database:
  host: postgresql
  port: 5432
  database: gigvault_$svc
  user: gigvault
  password: changeme
EOF

  # templates/deployment.yaml
  cat > "charts/$svc/templates/deployment.yaml" <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "chart.fullname" . }}
  labels:
    app: {{ .Chart.Name }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Chart.Name }}
  template:
    metadata:
      labels:
        app: {{ .Chart.Name }}
    spec:
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - containerPort: {{ .Values.service.port }}
        env:
        {{- range .Values.env }}
        - name: {{ .name }}
          value: {{ .value | quote }}
        {{- end }}
        - name: DB_HOST
          value: {{ .Values.database.host | quote }}
        - name: DB_PASSWORD
          value: {{ .Values.database.password | quote }}
        resources:
          {{- toYaml .Values.resources | nindent 10 }}
        livenessProbe:
          httpGet:
            path: /health
            port: {{ .Values.service.port }}
          initialDelaySeconds: 10
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /ready
            port: {{ .Values.service.port }}
          initialDelaySeconds: 5
          periodSeconds: 10
EOF

  # templates/service.yaml
  cat > "charts/$svc/templates/service.yaml" <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: {{ include "chart.fullname" . }}
  labels:
    app: {{ .Chart.Name }}
spec:
  type: {{ .Values.service.type }}
  ports:
  - port: {{ .Values.service.port }}
    targetPort: {{ .Values.service.port }}
    protocol: TCP
  selector:
    app: {{ .Chart.Name }}
EOF

  # templates/_helpers.tpl
  cat > "charts/$svc/templates/_helpers.tpl" <<'EOF'
{{- define "chart.fullname" -}}
{{- .Chart.Name -}}
{{- end -}}
EOF

  echo "✓ $svc chart generated"
done

echo "All Helm charts generated!"
EOF

