# JunoAI Backend + Code Audit Report

**Date:** 2026-02-17  
**Scope:** Terraform IaC, Cloud Functions/Run/Scheduler/BigQuery/Storage/PubSub/Monitoring in:
- `junoplus-dev`
- `juno-9dfb6` (prod)

---

## 1) Executive Summary

The backend is deployed in both environments. Scheduler authentication issues have now been fixed, but some functions still return runtime/data errors.

Important context: production (`juno-9dfb6`) currently has little/no business data yet, so some missing-table/missing-registry failures are expected until base datasets/tables are initialized.

### Critical outcomes
- ✅ Core resources exist (Functions, Scheduler jobs, datasets, buckets, topics/subscriptions).
- ✅ Scheduler auth path is fixed (latest successful `200` calls observed for scheduler-to-function invocations).
- ⚠️ Some jobs still fail with runtime/data errors (non-auth related), especially `quality-check` and `ml-snapshot`.
- ⚠️ Terraform control is currently unreliable in local workflow (`terraform state list` returns `0` in current workspace state context).
- ⚠️ One API function (`predict-tens-level`) is publicly invokable in dev.
- ⚠️ Code has several environment-coupling/brittle-path issues that can break production behavior.

---

## 2) Confirmed Live Findings (gcloud)

## 2.1 Scheduler authentication (UPDATED)
Scheduler-to-Cloud Run authentication was corrected by:
- Granting Scheduler service agent token/impersonation permissions on target invocation service account.
- Ensuring `run.invoker` on pipeline services for the invocation service account.
- Setting explicit OIDC audience on scheduler jobs.

Result: latest scheduler attempts now include successful `200` responses for pipeline invocations.

## 2.2 Current runtime failures (non-auth)
Current errors are now mainly code/data dependency issues:
- `quality-check-{env}`: `FileNotFoundError` for `/workspace/sql/quality_layer_setup.sql`.
- `ml-snapshot-dev`: BigQuery error about `dataset_registry` schema mismatch (missing `snapshot_id`).
- `ml-snapshot-prod`: missing base tables/registry (`ml_training_base_v2`, `dataset_registry`).
- `refresh-gold-dev`: semantic refresh error tied to dataset/table dependency mismatch.

These are application/data readiness issues, not scheduler authentication issues.

## 2.3 Public endpoint risk (dev)
- `predict-tens-level` in `junoplus-dev` has `roles/run.invoker` for `allUsers`.
- This means anyone with URL access can invoke it.

## 2.4 Monitoring present
Both projects have alert policies:
- Cloud Function Failures
- Cloud Function Long Execution

## 2.5 Production data readiness context
Because production does not yet have complete business data and some expected base tables/registry artifacts are not initialized, part of the current prod failures are expected at this stage.

Action: treat this as a phased rollout state, not purely an infra failure.

---

## 3) Code + IaC Findings

## 3.1 Scheduler OIDC configuration is incomplete (root cause)
Scheduler jobs include `oidc_token` using the analytics service account, but IAM does not include the necessary token-minting relationship for Cloud Scheduler service agent.

**Files:**
- `terraform/modules/scheduler/main.tf`
- `terraform/modules/iam/main.tf`

## 3.2 Potential IaC drift / state-management issue
In current local context, Terraform workspace `dev` has no tracked resources in state (`terraform state list | wc -l => 0`) while resources clearly exist in GCP.

Implication: plan/apply from current local context can be misleading and dangerous (recreate/conflict risk).

## 3.2.1 Status update for 3.1
The scheduler auth issue is remediated live, but Terraform state reconciliation is still needed to make this durable and fully managed by IaC.

## 3.3 `quality_check` function uses brittle absolute file path
Function reads SQL using `/workspace/sql/quality_layer_setup.sql`, but packaged source is only function directory.

**File:**
- `bigquery_medallion_migration/functions/quality_check/main.py`

## 3.4 `refresh_gold` has environment/data coupling issues
- Hardcoded semantic dataset name (`junoplus_analytics_semantic`) instead of env-driven value.
- Broken fallback string for `SILVER_DATASET_ID` (`'{DATASET_SILVER}_dev'`).

**File:**
- `bigquery_medallion_migration/functions/refresh_gold/main.py`

## 3.5 `tens_prediction_api` has maintainability and safety issues
- Hardcoded project/model paths (`junoplus-dev...`).
- Duplicate `level_query` block.
- Mixed prediction logic and heuristic fallback in same flow.
- Not managed by Terraform (configuration drift risk).

**File:**
- `tens_prediction_api/main.py`

---

## 4) Prioritized Action Plan (Implement One-by-One)

Use this as your execution checklist.

## P0 — Restore pipeline execution (today)

### Step 1: Fix Scheduler -> Function auth chain ✅ COMPLETED
Completed in live environment:
1. Added Scheduler service-agent permissions (`serviceAccountTokenCreator` + `serviceAccountUser`) on invocation SA.
2. Added/verified `roles/run.invoker` on pipeline Cloud Run services.
3. Set explicit OIDC audience and validated successful `200` scheduler invocations.

### Step 2: Lock down public endpoint (if not intentionally public)
1. Remove `allUsers` invoker from `predict-tens-level` in dev.
2. Put API behind one of:
   - API Gateway + auth
   - IAP
   - Signed identity (service-to-service)

---

## P1 — Stabilize IaC and runtime correctness (this week)

### Data-readiness note for prod
Because prod has no/low data yet, run these in order:
1. Ensure foundational gold tables/registry exist.
2. Then validate `ml-snapshot-prod`.
3. Treat missing-table errors as expected until initialization is done.

### Step 3: Repair Terraform state workflow
1. Re-initialize Terraform with correct backend config for each environment.
2. Validate active workspace and backend bucket/prefix.
3. Import existing resources if state is missing.
4. Re-run plan until it reflects true drift only.

### Step 4: Fix `quality_check` SQL dependency packaging
Choose one:
- Preferred: package SQL files with function source and load via relative path.
- Alternative: store SQL script in GCS and fetch at runtime.

### Step 5: Fix `refresh_gold` config bugs
1. Replace broken fallback for silver dataset env var.
2. Make semantic dataset env-driven (e.g., `SEMANTIC_DATASET_ID`).
3. Keep all dataset names controlled by Terraform/env vars only.

### Step 6: Refactor `tens_prediction_api`
1. Externalize project/dataset/model IDs into env vars.
2. Remove duplicate query block.
3. Keep one deterministic prediction path.
4. Add explicit error handling for model-not-found and invalid schema.

---

## P2 — Security and least privilege hardening

### Step 7: Minimize IAM scope
Current SA has project-level roles like `roles/bigquery.dataEditor`.

Move to narrower permissions where feasible:
- Dataset-level BigQuery permissions per layer.
- Bucket-level, object-level storage permissions only where needed.
- Separate service accounts by function responsibility.

### Step 8: Add operational guardrails
1. Add alert for Scheduler failures (`status.code != 0`).
2. Add alert for Cloud Run auth failures (`403` spikes).
3. Add canary/manual health check function invocation schedule.
4. Add dead-letter/notification path for repeated failures.

---

## 5) Recommended Implementation Order (Fastest Safe Path)

1. **Close public `predict-tens-level` access** unless intentionally public.
2. **Repair Terraform backend/state alignment** before any broad apply.
3. **Patch `quality_check` file-path dependency**.
4. **Patch `refresh_gold` env/dataset handling**.
5. **Initialize prod base tables/registry**, then validate `ml-snapshot-prod`.
6. **Least-privilege + alerts hardening**.

---

## 6) Verification Checklist (after each step)

- [ ] `gcloud scheduler jobs describe ...` no failing status on latest run.
- [ ] Cloud Run logs no longer show `unauthenticated`/`403` for scheduler invocations.
- [ ] `terraform plan` matches expected minimal drift.
- [ ] No hardcoded project IDs in function source.
- [ ] `predict-tens-level` IAM policy has no `allUsers` (unless intentional).
- [ ] Alerting detects and notifies on scheduler/auth regressions.

---

## 7) Notes

- This report reflects observed live state on 2026-02-17 and repository state at review time.
- Fixing Terraform state/backends is mandatory before trusting future plans/applies.
- Scheduler authentication issue has been remediated in live GCP; remaining errors are primarily code/data readiness.
- Production currently has no/limited data, so some missing-table failures are expected until initialization is complete.
- You can execute this report top-to-bottom as a runbook.
