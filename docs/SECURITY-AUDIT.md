# Security Audit Report — Kilo End-User Installer & Configuration

**Date:** 2026-05-19
**Scope:** `install.sh`, `config/kilo.jsonc`, `config/agents/assistant.md`, and related config files
**Repository:** u-r-ai/kilo-end-user

---

## Executive Summary

The installer and configuration contain **11 security findings** across critical, high, medium, and low severity. The most serious issues are: multiple curl-to-bash patterns (including a double-piped one), API key material stored in a plaintext config file with overly broad permissions, and a filesystem MCP server scoped to `$HOME` that gives the AI agent read/write access to the user's entire home directory. Combined with `bash: allow` and `edit: allow` permissions, the agent has unrestricted code execution on the host.

---

## Findings

### CRITICAL

#### C-1. Double curl-to-bash: NodeSource installer piped through sudo bash

**File:** `install.sh`, lines 158, 162, 169
**Pattern:**
```bash
curl -fsSL https://deb.nodesource.com/setup_lts.x | $SUDO bash -
curl -fsSL https://rpm.nodesource.com/setup_lts.x | $SUDO bash -
```

**Risk:** This is curl-to-bash run as root. If the NodeSource CDN is compromised, DNS is spoofed, or a MITM attack intercepts the connection, arbitrary root-level code runs on the host. The `-f` flag only checks for HTTP errors — it does not verify content integrity. There is no signature verification.

**Recommendation:** Pin to a specific NodeSource script version hash, or use distribution-native Node.js packages. At minimum, download the script to a temp file, verify its SHA256 against a hardcoded checksum, then execute it.

---

#### C-2. curl-to-bash: Kilo CLI installer

**File:** `install.sh`, line 253
**Pattern:**
```bash
curl -fsSL https://kilo.ai/cli/install | bash
```

**Risk:** Same as C-1 but without even `sudo` gating. Arbitrary code from kilo.ai runs as the current user. No integrity check.

**Recommendation:** Download to a temp file, verify checksum or GPG signature, then execute. Alternatively, install via npm (`npm install -g @kilo/cli`) which uses the npm registry's integrity guarantees.

---

#### C-3. curl-to-bash: Docker GPG key piped to sudo gpg

**File:** `install.sh`, line 195
**Pattern:**
```bash
curl -fsSL https://download.docker.com/linux/$DISTRO_ID/gpg | $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```

**Risk:** Network-sourced material written to a trusted APT keyring as root. While `gpg --dearmor` provides some sanitization (non-ASCII-armored input will fail), a malicious key could still trust unwanted repositories.

**Recommendation:** Verify the Docker GPG key fingerprint against a hardcoded expected value before writing it to the keyring.

---

### HIGH

#### H-1. API key stored in plaintext config file

**File:** `config/kilo.jsonc`, line 30; `install.sh`, line 424
**Pattern:**
```bash
jsonc_content="${jsonc_content//__API_KEY__/$API_KEY}"
echo "$jsonc_content" > "$KILO_CONFIG_DIR/kilo.jsonc"
```

The API key is written as a literal string in `kilo.jsonc`:
```json
"provider": {
  "deepseek": {
    "options": {
      "apiKey": "sk-xxxxxxxxxxxxxxxx"
    }
  }
}
```

**Risk:** The API key sits in a plaintext file at `~/.config/kilo/kilo.jsonc`. Any process running as the user, or any user-level malware, can read it. The file permissions are set to `644` (world-readable) by `set_permissions()` at line 452.

**Recommendation:**
1. Set config file permissions to `600` (owner-only read/write).
2. Consider storing the API key in the OS keychain (libsecret / keychain / credential manager) and referencing it by name.
3. At minimum, `chmod 600` the config file after writing it.

---

#### H-2. MCP filesystem server scoped to `$HOME`

**File:** `config/kilo.jsonc`, lines 6-9
**Pattern:**
```json
"filesystem": {
  "command": ["npx", "-y", "@modelcontextprotocol/server-filesystem", "$HOME"],
  "enabled": true
}
```

**Risk:** The filesystem MCP server gets full read/write access to the user's entire home directory. This includes `~/.ssh/`, `~/.gnupg/`, `~/.config/` (containing other API keys), `~/.bashrc`, `~/.zshrc`, browser configs, and any other sensitive files. Combined with `bash: allow` permission, the AI agent can exfiltrate any file in `$HOME`.

**Recommendation:** Scope to a project-specific directory like `$HOME/projects` or `$HOME/workspace`. Never point an MCP filesystem server at `$HOME` root. Add the scope to a dedicated `~/kilo-projects` or similar.

---

#### H-3. Overly permissive defaults: bash and edit set to allow

**File:** `config/kilo.jsonc`, lines 34-37; `config/agents/assistant.md`, lines 7-12
**Pattern:**
```json
"permission": {
  "bash": "allow",
  "edit": "allow"
}
```

The agent markdown also declares:
```yaml
permission:
  bash: allow
  edit: allow
```

**Risk:** With `bash: allow`, the agent can execute arbitrary shell commands without user confirmation. With `edit: allow`, it can modify any file in scope without confirmation. For non-technical end-users who may not understand the implications, this is a significant risk — a misinterpreted prompt could lead to destructive commands (e.g., `rm -rf`, overwriting system files).

**Recommendation:**
1. Change `bash` to `"ask"` for the initial setup. The agent can still run commands, but the user must approve each one.
2. Keep `edit: allow` only if scoped to a project directory (see H-2).
3. If `bash: allow` is kept, at minimum add a safety system prompt that blocks destructive commands (`rm -rf /`, `dd`, `mkfs`, etc.).

---

### MEDIUM

#### M-1. Sudo keep-alive loop can mask credential expiry

**File:** `install.sh`, line 46
**Pattern:**
```bash
while true; do sudo -n true; sleep 60; kill -0 "$SCRIPT_PID" 2>/dev/null || exit; done 2>/dev/null &
```

**Risk:** The background loop continuously refreshes the sudo timestamp for the entire duration of the install. If the user walks away during install, any subsequent code in the script continues to run with cached sudo privileges. The loop also suppresses all errors (`2>/dev/null`).

**Recommendation:** This is a common pattern and relatively low risk for an installer. Document the behavior. Consider adding a timeout (e.g., 30 minutes max).

---

#### M-2. Source-ing /etc/os-release without validation

**File:** `install.sh`, line 55
**Pattern:**
```bash
. /etc/os-release
```

**Risk:** `/etc/os-release` is sourced directly into the shell. While this file is a standard freedesktop.org spec and normally safe, a compromised or malformed file could inject shell code. Variables like `$ID`, `$ID_LIKE` are used unsanitized in `echo` statements and `case` patterns.

**Recommendation:** Read the file with `grep`/`awk` instead of sourcing it, or at minimum validate that the extracted values match expected patterns (alphanumeric + hyphens only).

---

#### M-3. API key leaked in shell history

**File:** `install.sh`, line 327-329
**Pattern:**
```bash
read -rp "Masukkan API Key: " API_KEY
```

**Risk:** If the installer is run in an interactive shell, the `read` command stores user input in the shell variable without suppressing history. While `read` itself does not write to bash history, the API key variable is used in subsequent commands that might appear in debug output or error messages.

**Recommendation:** Use `read -rs` (silent mode) to prevent shoulder-surfing. Ensure the API key is not logged or echoed in error paths.

---

#### M-4. Config downloaded over HTTPS without integrity check

**File:** `install.sh`, lines 419-439
**Pattern:**
```bash
jsonc_content=$(curl -fsSL "$REPO_RAW/config/kilo.jsonc")
curl -fsSL "$REPO_RAW/config/agents/assistant.md" > "$KILO_CONFIG_DIR/agents/assistant.md"
# ... more curl downloads
```

**Risk:** All config files are downloaded from GitHub raw URLs over HTTPS. While TLS prevents MITM, there is no integrity verification against a known hash. If the GitHub repo is compromised, malicious config (e.g., a modified agent prompt that instructs the AI to exfiltrate data) would be deployed.

**Recommendation:** Pin to a specific Git commit SHA in the download URL instead of `main` branch:
```
https://raw.githubusercontent.com/u-r-ai/kilo-end-user/COMMIT_SHA/config/kilo.jsonc
```
This ensures immutable, auditable deployments.

---

### LOW

#### L-1. Docker group membership grants container escape path

**File:** `install.sh`, lines 227-239
**Pattern:**
```bash
$SUDO usermod -aG docker "$USER"
```

**Risk:** Adding the user to the `docker` group is equivalent to granting root access. Any user in the `docker` group can escalate to root by mounting `/` in a container. This is well-known and necessary for the tool to work, but should be documented explicitly for non-technical users.

**Recommendation:** Add a clear warning in the installer output and README explaining this implication.

---

#### L-2. Config file permissions set to 644 (world-readable)

**File:** `install.sh`, lines 450-452
**Pattern:**
```bash
find "$KILO_CONFIG_DIR" -type f -exec chmod 644 {} \; 2>/dev/null || true
```

**Risk:** The config file containing the API key is set to `644`, making it readable by any user on the system. On shared machines or multi-user systems, this leaks the API key.

**Recommendation:** Set `kilo.jsonc` to `600` specifically. The `find` command should apply `644` to non-sensitive files and `600` to the main config.

---

## Summary Table

| ID   | Severity | Category              | File              | Finding                                          |
|------|----------|-----------------------|-------------------|--------------------------------------------------|
| C-1  | Critical | Remote Code Execution | install.sh:158    | NodeSource curl-to-bash as root                  |
| C-2  | Critical | Remote Code Execution | install.sh:253    | Kilo CLI curl-to-bash as user                    |
| C-3  | Critical | Supply Chain          | install.sh:195    | Docker GPG key from network to root keyring      |
| H-1  | High     | Credential Exposure   | kilo.jsonc:30     | API key in plaintext, world-readable file        |
| H-2  | High     | Excessive Scope       | kilo.jsonc:8      | MCP filesystem scoped to `$HOME`                 |
| H-3  | High     | Privilege Escalation  | kilo.jsonc:35-36  | bash:allow + edit:allow without scoping           |
| M-1  | Medium   | Privilege Persistence | install.sh:46     | Sudo keep-alive loop with no timeout             |
| M-2  | Medium   | Shell Injection       | install.sh:55     | Unvalidated sourcing of /etc/os-release          |
| M-3  | Medium   | Credential Exposure   | install.sh:327    | API key visible in terminal input                |
| M-4  | Medium   | Supply Chain          | install.sh:419    | Config from mutable branch, no integrity check   |
| L-1  | Low      | Privilege Escalation  | install.sh:236    | Docker group = root-equivalent, not documented   |
| L-2  | Low      | Credential Exposure   | install.sh:452    | Config file permissions 644, should be 600       |

---

## Recommended Priority Fixes

1. **Pin download URLs to a commit SHA** (addresses C-1, C-2, C-3, M-4) — switch from `.../main/` to `.../<sha>/` URLs.
2. **Restrict MCP filesystem scope** (H-2) — change `$HOME` to a dedicated project directory.
3. **Tighten config file permissions** (H-1, L-2) — `chmod 600 ~/.config/kilo/kilo.jsonc`.
4. **Reconsider bash:allow default** (H-3) — at minimum for non-technical end-users, default to `ask`.
5. **Add integrity checks** for all remote scripts before execution (C-1, C-2).
