# 📋 JunoPlus Data Platform - Remaining Tasks

## 🔴 Priority 1: Critical stabilization
- [ ] **Alerting System**: Configure Cloud Monitoring alerts for Quality Layer failures (Pub/Sub → Email/Slack).
- [ ] **Data Retention**: Set up BigQuery partition expiration for Bronze `_changelog` tables to manage costs.

## 🟡 Priority 2: Automation & Scaling
- [ ] **ML Automation**: Migrate manual retraining notebooks to Vertex AI Pipelines or scheduled Cloud Functions.
- [ ] **Model Monitoring**: Implement drift detection for the prediction API.

## 🟢 Priority 3: Insights & UI
- [ ] **BI Integration**: Connect `user_health_dashboard_v1` to Looker Studio.
- [ ] **User Feedback Loop**: Create a Gold table specifically for tracking user feedback sentiment over time.
