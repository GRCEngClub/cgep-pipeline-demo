# cgep-pipeline-demo

Reference repo for the GRC Engineering Club Practitioner course, lesson **04_03 — Building a GRC Evidence Pipeline**.

This repo exists to demonstrate the two-PR flow described in the slide deck and in section 5.5 of the lab guide:

1. A **green PR** that passes the GRC gate (terraform plan + Conftest + tfsec) and merges.
2. A **red PR** that removes the bucket encryption and is blocked by the gate with a named SC-28 violation.

Both runs upload a `grc-evidence-<run_id>` artifact, the same artifact pattern used in the capstone.

## Layout

```
.github/workflows/grc-gate.yml   # the pipeline (copied verbatim from lab 4.3)
policies/                        # SC-28, AC-3, CM-6 Rego policies
oidc/                            # bootstrap: OIDC provider + IAM role
terraform/                       # compliant baseline: KMS + S3 evidence bucket
```

## What "compliant baseline" means here

The Terraform in `terraform/` provisions a single S3 evidence bucket that satisfies all three policies out of the box:

- **SC-28** — `aws_s3_bucket_server_side_encryption_configuration` with a customer-managed `aws_kms_key`.
- **AC-3** — `aws_s3_bucket_public_access_block` with all four flags `true`.
- **CM-6** — provider `default_tags` set the four required tags (`Project`, `Environment`, `ManagedBy`, `ComplianceScope`) on every taggable resource.

A clean `terraform plan` produces zero policy violations. That's the precondition for the demo.

## Bootstrapping (one time)

```bash
cd oidc
terraform init
terraform apply -var=github_org=GRCEngClub -var=github_repo=cgep-pipeline-demo
# capture role_arn, then:
gh variable set AWS_ROLE_ARN --body "<role_arn>" --repo GRCEngClub/cgep-pipeline-demo
```

Branch protection on `main` requires the `grc-gate` check.

## Running the demo

See the **two-PR demonstration** in the [course lab guide](https://github.com/GRCEngClub/cgep-labs/blob/main/guides/04_03_grc_evidence_pipeline.md#55-the-two-pr-demonstration).

## License

MIT.
