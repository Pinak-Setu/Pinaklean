.PHONY: ci/status ci/rerun ci/open

ci/status:
	@bash scripts/ci-status.sh

ci/rerun:
	@bash scripts/ci-rerun-latest-failed.sh

ci/open:
	@bash scripts/ci-open-latest.sh

