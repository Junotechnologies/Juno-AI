# JunoPlus Medallion Data Architecture
**Status:** ✅ PRODUCTION READY | **Last Updated:** Feb 5, 2026

## 🎯 Architecture Overview
A production-grade BigQuery data platform for JunoAI, transforming raw Firestore data into analytics-ready insights.

### 🥉 Bronze Layer (Raw)
- **Dataset:** `junoplus_analytics`
- **Source:** Real-time Firestore Sync (CDC Extension).
- **Format:** Raw JSON documents with full change history.

### 🥈 Silver Layer (Standardized)
- **Dataset:** `junoplus_analytics_silver`
- **Refresh:** Automated via Cloud Function `refresh_silver`.
- **Tables:**
    - `silver_therapy_sessions`: Deduplicated sessions with pain metrics and device info.
    - `silver_user_profiles`: Standardized user attributes and health data.
    - `silver_medications`: Flattened medication history.
    - `silver_period_tracking`: Normalized cycle tracking snapshots.

### 🥇 Gold Layer (Analytics & ML)
- **Dataset:** `junoplus_analytics_gold`
- **Refresh:** Automated via Cloud Function `refresh_gold`.
- **Key Tables:**
    - `ml_training_base_v2`: Integrated feature set for model training.
    - `user_analytics_v1`: Deep-dive user behavior metrics.
    - `daily_metrics_v1`: Operational KPIs and health trends.
    - `gold_therapy_effectiveness`: Longitudinal analysis of TENS/Heat impact.

### 💎 Semantic Layer (Presentation)
- **Dataset:** `junoplus_analytics_semantic`
- **Views:** `user_health_dashboard_v1` (Unified reporting view).

### 🛡️ Quality Layer (Monitoring)
- **Dataset:** `junoplus_analytics_quality`
- **Features:** Automated checks for data freshness, null rates, and row count anomalies.

## 🚀 Key Achievements
- ✅ **Standardization**: All layers now use consistent snake_case naming and partitioned/clustered tables.
- ✅ **Data Accuracy**: Correctly mapping sub-collections (Sessions) using Firestore `path_params`.
- ✅ **Performance**: Implemented partitioning on `session_date` and clustering per `user_id`.
- ✅ **Automation**: Daily and Weekly pipelines are fully live in GCP.
