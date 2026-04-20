# Terragrunt helpers — requires terragrunt + terraform on PATH
TG_SCRIPT := ./scripts/tg.sh
LIVE_DEV  := live/dev

.PHONY: help tg-clean tg-init tg-validate tg-plan tg-apply tg-graph tg-env-check tg-fmt

help:
	@$(TG_SCRIPT) help

tg-clean:
	@$(TG_SCRIPT) clean-cache

tg-init:
	@$(TG_SCRIPT) init-all

tg-validate:
	@$(TG_SCRIPT) validate-all

tg-plan:
	@$(TG_SCRIPT) plan-all

tg-apply:
	@$(TG_SCRIPT) apply-all

tg-graph:
	@$(TG_SCRIPT) graph

tg-env-check:
	@$(TG_SCRIPT) env-check

# Format Terraform modules, stacks, and Terragrunt HCL under live/dev
tg-fmt:
	terraform fmt -recursive modules terraform
	terragrunt hclfmt --working-dir=$(LIVE_DEV)
