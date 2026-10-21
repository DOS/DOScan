#!/usr/bin/env bash
# Provisions the GCS staging bucket the testnet Deploy Config job uses to hand its config package
# to dos-testnet-r0. IAP data transfers from GitHub runners to r0 stall (see README.md), so the
# runner uploads the package here and r0 downloads it through a 10-minute V4 signed URL.
#
# Idempotent. Default mode is "plan" (prints the commands only). Run "apply" to execute and
# "verify" to read back the live settings. Requires owner approval: it changes GCP IAM.
set -euo pipefail

PROJECT="dos--ai"
LOCATION="asia-southeast1"
BUCKET="dos-doscan-testnet-staging-535583621422"
DEPLOY_SA="doscan-deploy@dos--ai.iam.gserviceaccount.com"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE="${1:-plan}"

run() {
  if [ "${MODE}" = "apply" ]; then
    "$@"
  else
    printf '+'
    printf ' %q' "$@"
    printf '\n'
  fi
}

case "${MODE}" in
  plan|apply)
    # Bucket: regional, uniform access, never public, no soft-delete retention (objects hold
    # NFT media credentials), objects deleted by lifecycle after 1 day as a backstop to the
    # workflow's own delete.
    if [ "${MODE}" = "plan" ] || ! gcloud storage buckets describe "gs://${BUCKET}" --project="${PROJECT}" >/dev/null 2>&1; then
      run gcloud storage buckets create "gs://${BUCKET}" \
        --project="${PROJECT}" \
        --location="${LOCATION}" \
        --uniform-bucket-level-access \
        --public-access-prevention \
        --soft-delete-duration=0
    fi
    run gcloud storage buckets update "gs://${BUCKET}" \
      --project="${PROJECT}" \
      --lifecycle-file="${HERE}/lifecycle.json"

    # The deploy identity may create, read and delete objects in this bucket only.
    run gcloud storage buckets add-iam-policy-binding "gs://${BUCKET}" \
      --project="${PROJECT}" \
      --member="serviceAccount:${DEPLOY_SA}" \
      --role="roles/storage.objectUser"

    # signBlob on itself, so it can mint V4 signed URLs without a key file. Bound on the
    # service account resource only, not the project.
    run gcloud iam service-accounts add-iam-policy-binding "${DEPLOY_SA}" \
      --project="${PROJECT}" \
      --member="serviceAccount:${DEPLOY_SA}" \
      --role="roles/iam.serviceAccountTokenCreator"
    ;;
  verify)
    gcloud storage buckets describe "gs://${BUCKET}" --project="${PROJECT}" \
      --format="yaml(name,location,uniform_bucket_level_access,public_access_prevention,soft_delete_policy,lifecycle_config)"
    gcloud storage buckets get-iam-policy "gs://${BUCKET}" --project="${PROJECT}" --format="yaml(bindings)"
    gcloud iam service-accounts get-iam-policy "${DEPLOY_SA}" --project="${PROJECT}" --format="yaml(bindings)"
    ;;
  *)
    echo "usage: $0 [plan|apply|verify]" >&2
    exit 2
    ;;
esac
