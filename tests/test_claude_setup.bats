#!/usr/bin/env bats

# claude-setup CLI tests

SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI="$REPO_DIR/bin/claude-setup"

# Use a temporary HOME for isolation
setup() {
  export ORIGINAL_HOME="$HOME"
  export TEST_HOME="$(mktemp -d)"
  export HOME="$TEST_HOME"
  export TEST_PROJECT="$(mktemp -d)"
}

teardown() {
  export HOME="$ORIGINAL_HOME"
  rm -rf "$TEST_HOME" "$TEST_PROJECT"
}

# ============================================================
# Help / Version
# ============================================================

@test "claude-setup without arguments shows usage" {
  run "$CLI"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
  [[ "$output" == *"install"* ]]
  [[ "$output" == *"init"* ]]
  [[ "$output" == *"update"* ]]
  [[ "$output" == *"status"* ]]
}

@test "claude-setup --help shows usage" {
  run "$CLI" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "claude-setup --version shows version" {
  run "$CLI" --version
  [ "$status" -eq 0 ]
  [[ "$output" == *"claude-setup v"* ]]
}

@test "claude-setup unknown command fails" {
  run "$CLI" foobar
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown command"* ]]
}

# ============================================================
# Install (core)
# ============================================================

@test "install creates core agents in ~/.claude/agents/" {
  run "$CLI" install
  [ "$status" -eq 0 ]

  [ -f "$HOME/.claude/agents/hearing-agent.md" ]
  [ -f "$HOME/.claude/agents/planning-agent.md" ]
  [ -f "$HOME/.claude/agents/tdd-agent.md" ]
  [ -f "$HOME/.claude/agents/test-agent.md" ]
  [ -f "$HOME/.claude/agents/code-review-agent.md" ]
  [ -f "$HOME/.claude/agents/commit-agent.md" ]
}

@test "install creates core skills in ~/.claude/skills/" {
  run "$CLI" install
  [ "$status" -eq 0 ]

  [ -f "$HOME/.claude/skills/hear/SKILL.md" ]
  [ -f "$HOME/.claude/skills/architect/SKILL.md" ]
  [ -f "$HOME/.claude/skills/implement/SKILL.md" ]
  [ -f "$HOME/.claude/skills/test/SKILL.md" ]
  [ -f "$HOME/.claude/skills/code-review/SKILL.md" ]
  [ -f "$HOME/.claude/skills/commit/SKILL.md" ]
}

@test "install creates user-level CLAUDE.md" {
  run "$CLI" install
  [ "$status" -eq 0 ]

  [ -f "$HOME/.claude/CLAUDE.md" ]
  grep -q "日本語で回答" "$HOME/.claude/CLAUDE.md"
  grep -q "planモード" "$HOME/.claude/CLAUDE.md"
}

@test "install creates metadata file" {
  run "$CLI" install
  [ "$status" -eq 0 ]

  [ -f "$HOME/.claude/.claude-setup-meta.json" ]
  # Verify JSON is valid
  python3 -c "import json; json.load(open('$HOME/.claude/.claude-setup-meta.json'))"
}

@test "install metadata includes CLAUDE.md checksum" {
  "$CLI" install
  python3 -c "
import json
meta = json.load(open('$HOME/.claude/.claude-setup-meta.json'))
assert 'CLAUDE.md' in meta['checksums'], 'CLAUDE.md checksum missing'
"
}

@test "install without --with-db does NOT install db agents" {
  run "$CLI" install
  [ "$status" -eq 0 ]

  [ ! -f "$HOME/.claude/agents/db-schema-agent.md" ]
  [ ! -f "$HOME/.claude/agents/db-review-agent.md" ]
}

@test "install --with-db installs db agents and skills" {
  run "$CLI" install --with-db
  [ "$status" -eq 0 ]

  [ -f "$HOME/.claude/agents/db-schema-agent.md" ]
  [ -f "$HOME/.claude/agents/db-review-agent.md" ]
  [ -f "$HOME/.claude/skills/db-schema/SKILL.md" ]
  [ -f "$HOME/.claude/skills/db-review/SKILL.md" ]
}

@test "install is idempotent - second run shows unchanged" {
  "$CLI" install
  run "$CLI" install
  [ "$status" -eq 0 ]
  [[ "$output" == *"[unchanged]"* ]]
}

@test "install --force overwrites modified files" {
  "$CLI" install
  echo "# modified locally" >> "$HOME/.claude/agents/tdd-agent.md"

  run "$CLI" install --force
  [ "$status" -eq 0 ]
  [[ "$output" == *"overwritten"* ]]
}

@test "install skips locally modified files without --force" {
  "$CLI" install
  echo "# modified locally" >> "$HOME/.claude/agents/tdd-agent.md"

  run "$CLI" install
  [ "$status" -eq 0 ]
  [[ "$output" == *"locally modified"* ]]
}

# ============================================================
# Init
# ============================================================

@test "init fails without prior install" {
  run "$CLI" init "$TEST_PROJECT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Run 'claude-setup install' first"* ]]
}

@test "init creates .claude/settings.json" {
  "$CLI" install

  run "$CLI" init "$TEST_PROJECT"
  [ "$status" -eq 0 ]
  [ -f "$TEST_PROJECT/.claude/settings.json" ]
}

@test "init creates workflow CLAUDE.md in .claude/" {
  "$CLI" install

  run "$CLI" init "$TEST_PROJECT"
  [ "$status" -eq 0 ]
  [ -f "$TEST_PROJECT/.claude/CLAUDE.md" ]

  # Tier 2: workflow/skill knowledge
  grep -q "/implement" "$TEST_PROJECT/.claude/CLAUDE.md"
  grep -q "/hear" "$TEST_PROJECT/.claude/CLAUDE.md"
  grep -q "ワークフロー順序" "$TEST_PROJECT/.claude/CLAUDE.md"
}

@test "init creates project CLAUDE.md at root" {
  "$CLI" install

  run "$CLI" init "$TEST_PROJECT"
  [ "$status" -eq 0 ]
  [ -f "$TEST_PROJECT/CLAUDE.md" ]

  # Tier 3: project-specific, universal content
  grep -q "TDDの原則" "$TEST_PROJECT/CLAUDE.md"
  grep -q "コミットメッセージ規約" "$TEST_PROJECT/CLAUDE.md"
  grep -q "禁止事項" "$TEST_PROJECT/CLAUDE.md"
}

@test "init root CLAUDE.md does NOT contain skill references" {
  "$CLI" install

  run "$CLI" init "$TEST_PROJECT"
  [ "$status" -eq 0 ]

  # Tier 3 should not reference specific skills
  ! grep -q "/implement" "$TEST_PROJECT/CLAUDE.md"
  ! grep -q "/hear" "$TEST_PROJECT/CLAUDE.md"
  ! grep -q "/architect" "$TEST_PROJECT/CLAUDE.md"
}

@test "init workflow CLAUDE.md excludes DB section without --with-db" {
  "$CLI" install

  run "$CLI" init "$TEST_PROJECT"
  [ "$status" -eq 0 ]

  ! grep -q "データベースワークフロー" "$TEST_PROJECT/.claude/CLAUDE.md"
  ! grep -q "db-schema" "$TEST_PROJECT/.claude/CLAUDE.md"
}

@test "init --with-db includes DB section in workflow CLAUDE.md" {
  "$CLI" install --with-db

  run "$CLI" init "$TEST_PROJECT" --with-db
  [ "$status" -eq 0 ]

  grep -q "データベースワークフロー" "$TEST_PROJECT/.claude/CLAUDE.md"
  grep -q "db-schema" "$TEST_PROJECT/.claude/CLAUDE.md"
  # Marker comments should be removed
  ! grep -q "DB_WORKFLOW_START" "$TEST_PROJECT/.claude/CLAUDE.md"
  ! grep -q "DB_WORKFLOW_END" "$TEST_PROJECT/.claude/CLAUDE.md"
}

@test "init creates required directories" {
  "$CLI" install

  run "$CLI" init "$TEST_PROJECT"
  [ "$status" -eq 0 ]

  [ -d "$TEST_PROJECT/docs/context" ]
  [ -d "$TEST_PROJECT/docs/plans" ]
}

@test "init does NOT create src/tests directories (deferred to /architect)" {
  "$CLI" install

  run "$CLI" init "$TEST_PROJECT"
  [ "$status" -eq 0 ]

  [ ! -d "$TEST_PROJECT/src" ]
  [ ! -d "$TEST_PROJECT/tests" ]
}

@test "init CLAUDE.md does not contain template placeholders" {
  "$CLI" install

  run "$CLI" init "$TEST_PROJECT"
  [ "$status" -eq 0 ]

  ! grep -q '{{SRC_DIR}}' "$TEST_PROJECT/CLAUDE.md"
  ! grep -q '{{TEST_DIR}}' "$TEST_PROJECT/CLAUDE.md"
}

@test "init with --with-db creates db directories" {
  "$CLI" install --with-db

  run "$CLI" init "$TEST_PROJECT" --with-db
  [ "$status" -eq 0 ]

  [ -d "$TEST_PROJECT/database/schemas" ]
  [ -d "$TEST_PROJECT/database/migrations" ]
  [ -d "$TEST_PROJECT/database/context" ]
  [ -d "$TEST_PROJECT/docs/database/schemas" ]
  [ -d "$TEST_PROJECT/docs/database/reviews" ]
  [ -d "$TEST_PROJECT/docs/database/migrations" ]
}

@test "init creates settings without hooks section" {
  "$CLI" install

  run "$CLI" init "$TEST_PROJECT"
  [ "$status" -eq 0 ]

  ! grep -q '"hooks"' "$TEST_PROJECT/.claude/settings.json"
}

@test "init skips existing files without --force" {
  "$CLI" install
  mkdir -p "$TEST_PROJECT/.claude"
  echo '{"custom": true}' > "$TEST_PROJECT/.claude/settings.json"
  echo "# custom workflow" > "$TEST_PROJECT/.claude/CLAUDE.md"
  echo "# custom project" > "$TEST_PROJECT/CLAUDE.md"

  run "$CLI" init "$TEST_PROJECT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"skip - exists"* ]]

  # Verify original content preserved
  grep -q '"custom"' "$TEST_PROJECT/.claude/settings.json"
  grep -q "# custom workflow" "$TEST_PROJECT/.claude/CLAUDE.md"
  grep -q "# custom project" "$TEST_PROJECT/CLAUDE.md"
}

@test "init --force overwrites existing files" {
  "$CLI" install
  mkdir -p "$TEST_PROJECT/.claude"
  echo '{"custom": true}' > "$TEST_PROJECT/.claude/settings.json"

  run "$CLI" init "$TEST_PROJECT" --force
  [ "$status" -eq 0 ]

  # Verify content was overwritten
  ! grep -q '"custom"' "$TEST_PROJECT/.claude/settings.json"
}

@test "init is idempotent for directories" {
  "$CLI" install
  "$CLI" init "$TEST_PROJECT"

  run "$CLI" init "$TEST_PROJECT" --force
  [ "$status" -eq 0 ]
  [[ "$output" == *"[exists]"* ]]
}

# ============================================================
# Update
# ============================================================

@test "update fails without prior install" {
  run "$CLI" update
  [ "$status" -eq 1 ]
  [[ "$output" == *"Run 'claude-setup install' first"* ]]
}

@test "update refreshes unchanged files" {
  "$CLI" install
  run "$CLI" update
  [ "$status" -eq 0 ]
  [[ "$output" == *"Update complete"* ]]
}

@test "update includes CLAUDE.md" {
  "$CLI" install
  run "$CLI" update
  [ "$status" -eq 0 ]
  [[ "$output" == *"CLAUDE.md"* ]]
}

@test "update --add-db adds db components" {
  "$CLI" install

  # Verify no DB components
  [ ! -f "$HOME/.claude/agents/db-schema-agent.md" ]

  run "$CLI" update --add-db
  [ "$status" -eq 0 ]
  [ -f "$HOME/.claude/agents/db-schema-agent.md" ]
  [ -f "$HOME/.claude/agents/db-review-agent.md" ]
}

@test "update --remove-db removes db components" {
  "$CLI" install --with-db
  [ -f "$HOME/.claude/agents/db-schema-agent.md" ]

  run "$CLI" update --remove-db
  [ "$status" -eq 0 ]
  [ ! -f "$HOME/.claude/agents/db-schema-agent.md" ]
  [ ! -f "$HOME/.claude/agents/db-review-agent.md" ]
}

@test "update --add-db and --remove-db conflict" {
  "$CLI" install
  run "$CLI" update --add-db --remove-db
  [ "$status" -eq 1 ]
  [[ "$output" == *"Cannot use --add-db and --remove-db together"* ]]
}

# ============================================================
# Status
# ============================================================

@test "status shows not installed when no installation" {
  run "$CLI" status
  [[ "$output" == *"not installed"* ]]
}

@test "status shows installed after install" {
  "$CLI" install
  run "$CLI" status
  [ "$status" -eq 0 ]
  [[ "$output" == *"installed"* ]]
  [[ "$output" == *"[ok]"* ]]
}

@test "status shows CLAUDE.md status" {
  "$CLI" install
  run "$CLI" status
  [ "$status" -eq 0 ]
  [[ "$output" == *"CLAUDE.md"* ]]
}

# ============================================================
# Init defaults to current directory
# ============================================================

@test "init without DIR uses current directory" {
  "$CLI" install
  cd "$TEST_PROJECT"

  run "$CLI" init
  [ "$status" -eq 0 ]
  [ -f "$TEST_PROJECT/CLAUDE.md" ]
  [ -f "$TEST_PROJECT/.claude/settings.json" ]
  [ -f "$TEST_PROJECT/.claude/CLAUDE.md" ]
}

# ============================================================
# Agent content verification
# ============================================================

@test "tdd-agent.md does not contain hardcoded src/ tests/ paths" {
  ! grep -q 'Write: src/\*\*' "$REPO_DIR/.claude/agents/tdd-agent.md"
  ! grep -q 'Edit: src/\*\*' "$REPO_DIR/.claude/agents/tdd-agent.md"
  ! grep -q 'テストを tests/ に作成' "$REPO_DIR/.claude/agents/tdd-agent.md"
  ! grep -q 'コードを src/ に作成' "$REPO_DIR/.claude/agents/tdd-agent.md"
  ! grep -q 'src/, tests/ 以外' "$REPO_DIR/.claude/agents/tdd-agent.md"
}

@test "tdd-agent.md references current-state.json for directory info" {
  grep -q 'current-state.json' "$REPO_DIR/.claude/agents/tdd-agent.md"
  grep -q 'src_dir' "$REPO_DIR/.claude/agents/tdd-agent.md"
  grep -q 'test_dir' "$REPO_DIR/.claude/agents/tdd-agent.md"
  grep -q 'ディレクトリ確認' "$REPO_DIR/.claude/agents/tdd-agent.md"
  grep -q 'ソースディレクトリ' "$REPO_DIR/.claude/agents/tdd-agent.md"
  grep -q 'テストディレクトリ' "$REPO_DIR/.claude/agents/tdd-agent.md"
}

@test "code-review-agent.md references current-state.json for directory info" {
  grep -q 'current-state.json' "$REPO_DIR/.claude/agents/code-review-agent.md"
  grep -q 'src_dir' "$REPO_DIR/.claude/agents/code-review-agent.md"
  grep -q 'test_dir' "$REPO_DIR/.claude/agents/code-review-agent.md"
}

# ============================================================
# Template content verification
# ============================================================

@test "Tier 1 template contains user-level settings" {
  grep -q "日本語で回答" "$REPO_DIR/templates/user/CLAUDE.md.tmpl"
  grep -q "planモード" "$REPO_DIR/templates/user/CLAUDE.md.tmpl"
  grep -q "コメント" "$REPO_DIR/templates/user/CLAUDE.md.tmpl"
}

@test "Tier 2 template contains workflow knowledge" {
  grep -q "/hear" "$REPO_DIR/templates/project/workflow-CLAUDE.md.tmpl"
  grep -q "/implement" "$REPO_DIR/templates/project/workflow-CLAUDE.md.tmpl"
  grep -q "ワークフロー順序" "$REPO_DIR/templates/project/workflow-CLAUDE.md.tmpl"
  grep -q "コード生成ポリシー" "$REPO_DIR/templates/project/workflow-CLAUDE.md.tmpl"
}

@test "Tier 3 template contains project-universal content" {
  grep -q "TDDの原則" "$REPO_DIR/templates/project/CLAUDE.md.tmpl"
  grep -q "コミットメッセージ規約" "$REPO_DIR/templates/project/CLAUDE.md.tmpl"
  grep -q "禁止事項" "$REPO_DIR/templates/project/CLAUDE.md.tmpl"
  # Should NOT contain skill references
  ! grep -q "/implement" "$REPO_DIR/templates/project/CLAUDE.md.tmpl"
  ! grep -q "/hear" "$REPO_DIR/templates/project/CLAUDE.md.tmpl"
}
