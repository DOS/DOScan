# Testnet deploy staging bucket

The `deploy-testnet` job of `Deploy Config` hands its configuration package to
`dos-testnet-r0` through this bucket instead of IAP.

## Why

Since 2026-08-23 every testnet upload over IAP failed. The scp debug trace
(run 39307307642) shows SSH auth and the sftp subsystem succeeding, after which
the bulk data channel from GitHub runners to r0 never progresses. Every variant
tried stalled:

- scp with the default transport and with the numpy transport;
- legacy scp (`-O`) and sftp;
- 64 KiB chunks (DOS/DOScan#263, #264);
- a single ~22 KB SSH env request (#266).

Small SSH control commands always pass. Mainnet uploads to `doscan-mainnet` from
the same runners work, and a workstation scp to r0 works.

## Design

| Item | Value |
|---|---|
| Bucket | `gs://dos-doscan-testnet-staging-535583621422` (`asia-southeast1`) |
| Access | uniform bucket-level access, public access prevention enforced |
| Retention | soft delete disabled; lifecycle deletes objects after 1 day; the workflow deletes its object at the end of the step |
| Writer | `doscan-deploy@dos--ai.iam.gserviceaccount.com`: `roles/storage.objectUser` on this bucket only |
| Signer | `doscan-deploy` holds `roles/iam.serviceAccountTokenCreator` on itself (service-account resource, not project) to mint V4 signed URLs without a key file |
| Reader | none. r0 downloads with a 10-minute signed GET URL. The URL travels in an SSH `LC_*` env request, not on the command line |

The VMs' default compute service account is shared by every VM in the project,
so granting it bucket read would expose the package to all of them. The signed
URL avoids any new reader identity.

## Provision (owner approval required: GCP IAM change)

```bash
bash infra/gcp/testnet-deploy-staging/provision.sh plan    # print the commands
bash infra/gcp/testnet-deploy-staging/provision.sh apply   # execute
bash infra/gcp/testnet-deploy-staging/provision.sh verify  # read back settings and IAM
```

`apply` is idempotent and creates the bucket only if it is missing.

## Rollback

```bash
gcloud iam service-accounts remove-iam-policy-binding doscan-deploy@dos--ai.iam.gserviceaccount.com \
  --project=dos--ai --member=serviceAccount:doscan-deploy@dos--ai.iam.gserviceaccount.com \
  --role=roles/iam.serviceAccountTokenCreator
gcloud storage rm --recursive gs://dos-doscan-testnet-staging-535583621422
gcloud storage buckets delete gs://dos-doscan-testnet-staging-535583621422
```
