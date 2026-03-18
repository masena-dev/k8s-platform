# Backups

CNPG backups consist of base backups (`Backup` objects) and WAL segments archived to object storage. A complete restore needs both.

**Prerequisites:** CNPG must be enabled (`cnpg: true` under `components:` in `clusters/<cluster>/values.yaml`) and object storage must be enabled in Stage 1 (`enable_object_storage = true` in cluster `terraform.tfvars`).

## Where backup settings live

- `values/cnpg/cluster/values.yaml`: shared defaults
- `values/cnpg/cluster/values-{cloud}.yaml`: cloud-specific storage and auth
- `clusters/{name}/cnpg-values.yaml`: per-cluster enablement and schedule

Example:

```yaml
backup:
  enabled: true
  schedule: "0 0 2 * * *"
```

`ScheduledBackup.spec.schedule` is six-field cron (seconds first). The example runs daily at 02:00 UTC. Use a frequent schedule during validation (e.g. `"0 */5 * * * *"`), then adjust to production schedule.

## Backup credentials

For the public OVH and Hetzner starter paths, CNPG backups use static
S3-compatible credentials from `cnpg-backup-credentials`.

That synced secret should contain:

- `REGION`
- `ACCESS_KEY_ID`
- `ACCESS_SECRET_KEY`


## OVH

With `enable_object_storage = true`, Terraform provisions `loki-chunks`, `loki-ruler`, and `cnpg-backups` buckets, writes OVH S3 credentials to 1Password, and `bootstrap-secrets` syncs them to `monitoring/loki-storage-credentials` and `database/cnpg-backup-credentials`.

Enable backups and set the schedule in `clusters/{name}/cnpg-values.yaml`.

## Hetzner

With `enable_object_storage = true`, Terraform provisions `loki-chunks`, `loki-ruler`, and `cnpg-backups` buckets. The Object Storage endpoint and region are exported from Stage 1 and passed into ArgoCD for both Loki and CNPG, avoiding stale `fsn1` placeholders when running in `nbg1` or `hel1`.

Synced secrets are the same as OVH: `monitoring/loki-storage-credentials` and `database/cnpg-backup-credentials`.

Enable backups and set the schedule in `clusters/{name}/cnpg-values.yaml`, and set `cnpg_enabled = true` in addons `terraform.tfvars`.

## Validation workflow

Check control-plane objects:

```bash
kubectl get scheduledbackup -n database
kubectl describe scheduledbackup postgres-daily -n database
kubectl get backup -n database
kubectl get cluster postgres -n database -o yaml | grep -A10 'lastSuccessfulBackup\|firstRecoverabilityPoint\|conditions'
```

Create a test record in the primary to verify restore recovers to a known point:

```bash
MARKER="$(date -u +%Y%m%dT%H%M%SZ)"
PRIMARY_POD="$(KUBECONFIG=./kubeconfig kubectl get cluster -n database postgres -o jsonpath='{.status.currentPrimary}')"
DB_USER="$(KUBECONFIG=./kubeconfig kubectl get secret -n database postgres-app-bootstrap -o jsonpath='{.data.username}' | base64 -d)"
DB_PASSWORD="$(KUBECONFIG=./kubeconfig kubectl get secret -n database postgres-app-bootstrap -o jsonpath='{.data.password}' | base64 -d)"

KUBECONFIG=./kubeconfig kubectl exec -n database "$PRIMARY_POD" -- \
  env "PGPASSWORD=$DB_PASSWORD" \
  psql -v ON_ERROR_STOP=1 -h localhost -U "$DB_USER" -d app -P pager=off \
  -c "CREATE TABLE IF NOT EXISTS backup_validation (marker TEXT PRIMARY KEY, inserted_at TIMESTAMPTZ NOT NULL DEFAULT now()); \
      INSERT INTO backup_validation (marker) VALUES ('$MARKER') ON CONFLICT (marker) DO NOTHING; \
      SELECT marker, inserted_at FROM backup_validation WHERE marker = '$MARKER';"
```

If you need an immediate extra base backup during validation, create one
explicitly:

```bash
MANUAL_BACKUP="manual-backup-$(date +%Y%m%d-%H%M%S)"

kubectl apply -f - <<EOF
apiVersion: postgresql.cnpg.io/v1
kind: Backup
metadata:
  name: ${MANUAL_BACKUP}
  namespace: database
spec:
  cluster:
    name: postgres
EOF

kubectl get backup -n database
kubectl describe backup -n database "${MANUAL_BACKUP}"
```

For OVH, data bucket credentials differ from the state bucket credentials in `.env`. Retrieve them from Stage 1 output:

```bash
terraform -chdir=terraform/clusters/ovh-starter/cluster output object_storage_access_key
terraform -chdir=terraform/clusters/ovh-starter/cluster output object_storage_secret_key
```

Then list the bucket contents:

```bash
AWS_ACCESS_KEY_ID=<from-output> AWS_SECRET_ACCESS_KEY=<from-output> \
  aws --endpoint-url https://s3.gra.perf.cloud.ovh.net s3 ls s3://<cnpg-backups-bucket>/postgres/ --recursive
```

OVH uses different S3 endpoint tiers: state bucket uses `s3.gra.io.cloud.ovh.net` (standard), data buckets use `s3.gra.perf.cloud.ovh.net` (high-performance).

For Hetzner Object Storage, use the region-specific endpoint from Stage 1:

```bash
aws --endpoint-url https://<fsn1|nbg1|hel1>.your-objectstorage.com \
  s3 ls s3://<cnpg-backups-bucket>/postgres/ --recursive
```

Expected layout looks like:

```text
postgres/
├── base/
│   └── 20260311T172501/
│       ├── backup.info
│       └── data.tar.bz2
└── wals/
    └── 0000000100000000/
        ├── 000000010000000000000009.bz2
        └── 00000001000000000000000A.bz2
```

## Restore testing

Seed a row, restore into a temporary CNPG cluster, and verify the row exists.

Useful checks during restore:

```bash
kubectl get cluster -n database postgres-restore
kubectl describe cluster -n database postgres-restore
kubectl get pods -n database -l cnpg.io/cluster=postgres-restore
kubectl logs -n database -l cnpg.io/cluster=postgres-restore --tail=200
```

If restore fails with missing WAL errors, the base backup exists but required WAL segments are not yet in object storage. Check the restore cluster logs and the `wals/` prefix in the backup bucket. To force additional WAL archival:

```bash
PRIMARY_POD="$(KUBECONFIG=./kubeconfig kubectl get cluster -n database postgres -o jsonpath='{.status.currentPrimary}')"
DB_USER="$(KUBECONFIG=./kubeconfig kubectl get secret -n database postgres-app-bootstrap -o jsonpath='{.data.username}' | base64 -d)"
DB_PASSWORD="$(KUBECONFIG=./kubeconfig kubectl get secret -n database postgres-app-bootstrap -o jsonpath='{.data.password}' | base64 -d)"

KUBECONFIG=./kubeconfig kubectl exec -n database "$PRIMARY_POD" -- \
  env "PGPASSWORD=$DB_PASSWORD" \
  psql -v ON_ERROR_STOP=1 -h localhost -U "$DB_USER" -d app -P pager=off \
  -c "SELECT pg_switch_wal(); CHECKPOINT;"
```

### Point-in-time recovery (PITR)

To restore to a specific timestamp, create a recovery cluster:

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: postgres-restore
  namespace: database
spec:
  instances: 1
  storage:
    size: 20Gi
  bootstrap:
    recovery:
      source: postgres
      recoveryTarget:
        targetTime: "2026-03-14T12:00:00Z"
  externalClusters:
    - name: postgres
      barmanObjectStore:
        destinationPath: "s3://<cnpg-backups-bucket>/postgres/"
        endpointURL: "https://<endpoint>"
        s3Credentials:
          region:
            name: cnpg-backup-credentials
            key: REGION
          accessKeyId:
            name: cnpg-backup-credentials
            key: ACCESS_KEY_ID
          secretAccessKey:
            name: cnpg-backup-credentials
            key: ACCESS_SECRET_KEY
```

Once the restore cluster is healthy, promote it by deleting the source reference and updating your application's database connection.

## PostgreSQL tuning

The CNPG chart auto-tunes PostgreSQL from pod memory limits:

| Parameter | Formula | Minimum |
|-----------|---------|---------|
| `shared_buffers` | 25% of memory limit | 128 MB |
| `effective_cache_size` | 75% of memory limit | 512 MB |
| `maintenance_work_mem` | 5% of memory limit | 64 MB |

Computed in `values/cnpg/cluster/templates/_helpers.tpl`. These three parameters cannot be overridden directly — they are always calculated from the memory limit. To change them, increase `cluster.resources.limits.memory` in `values/cnpg/cluster/values.yaml` or per-cluster cnpg-values.

The default memory limit is 2Gi, giving 512MB shared_buffers and 1536MB effective_cache_size. Increase the limit to scale up automatically.

Other parameters (WAL tuning, replica protection) can be set in `cluster.postgresql.parameters`. See `values/cnpg/cluster/values.yaml` for commented production tuning snippets.

To enable `pg_stat_statements` for query performance tracking, uncomment the `pg_stat_statements.*` parameters in the values file. CNPG automatically adds the extension to `shared_preload_libraries` and creates it in the database.
