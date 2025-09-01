.PHONY: ci/status ci/rerun ci/open

ci/status:
	@bash scripts/ci-status.sh

ci/rerun:
	@bash scripts/ci-rerun-latest-failed.sh

ci/open:
	@bash scripts/ci-open-latest.sh

.PHONY: ci/dash
ci/dash:
	gh dash

# MCP servers (requires Node/npm for npx and uvx for Python-based servers)
.PHONY: mcp/filesystem mcp/memory mcp/git
mcp/filesystem:
	npx -y @modelcontextprotocol/server-filesystem .

mcp/memory:
	npx -y @modelcontextprotocol/server-memory

mcp/git:
	uvx mcp-server-git --repository ./

.PHONY: ui/diagram
ui/diagram:
	npx -y @mermaid-js/mermaid-cli -i ui.mmd -o ui.png

