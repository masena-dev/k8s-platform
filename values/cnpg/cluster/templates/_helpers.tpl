{{/*
Auto-tune PostgreSQL parameters based on memory limits.
Auto-tuning based on standard PostgreSQL best practices.

Formula:
  shared_buffers = 25% of memory
  effective_cache_size = 75% of memory
  maintenance_work_mem = 5% of memory (capped at 2GB)
  work_mem = 4% of memory / max_connections
*/}}

{{- define "cnpg.autoTuneParams" -}}
{{- $memoryStr := .Values.cluster.resources.limits.memory | default .Values.cluster.resources.requests.memory | default "1Gi" -}}
{{- $memoryMi := 0 -}}
{{- if hasSuffix "Gi" $memoryStr -}}
  {{- $memoryMi = mul (trimSuffix "Gi" $memoryStr | int) 1024 -}}
{{- else if hasSuffix "Mi" $memoryStr -}}
  {{- $memoryMi = trimSuffix "Mi" $memoryStr | int -}}
{{- else if hasSuffix "G" $memoryStr -}}
  {{- $memoryMi = mul (trimSuffix "G" $memoryStr | int) 1024 -}}
{{- else if hasSuffix "M" $memoryStr -}}
  {{- $memoryMi = trimSuffix "M" $memoryStr | int -}}
{{- else -}}
  {{- $memoryMi = 1024 -}}
{{- end -}}
{{- $sharedBuffers := max 128 (div (mul $memoryMi 25) 100) -}}
{{- $effectiveCache := max 512 (div (mul $memoryMi 75) 100) -}}
{{- $maintenanceWorkMem := min 2048 (max 64 (div (mul $memoryMi 5) 100)) -}}
shared_buffers: {{ printf "%dMB" $sharedBuffers | quote }}
effective_cache_size: {{ printf "%dMB" $effectiveCache | quote }}
maintenance_work_mem: {{ printf "%dMB" $maintenanceWorkMem | quote }}
{{- end -}}
