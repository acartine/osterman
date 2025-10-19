**High-Risk Categories (Require Approval or Pair Programmer)**
- Terraform applies; kubectl apply/delete to non-kind contexts; helm upgrade in prod
- Production DB schema/data changes, backfills, purges, or retention tasks
- Secret/key rotations; IAM policy/role scope increases; SSO/OAuth scope changes
- DNS/SSL/TLS certificate updates; CDN/WAF/Firewall rule changes
- Cost-impacting scale-ups; provisioning new managed services
- Data migrations and ETL impacting PII/regulated data

**Moderate-Risk (Autonomy allowed with caution + summary)**
- Non-prod infra changes with plan-only verification and rollbacks
- CI/CD pipeline edits that are revertible and have test coverage
- Container image base updates with security patches

**Notes**
- Always attach plan/diff summaries and rollback steps for review.
- Default to Pair Programmer mode when uncertain about blast radius.
