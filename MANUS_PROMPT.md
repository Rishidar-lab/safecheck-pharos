# Manus prompt — publish SafeCheck to GitHub

Copy everything below the line into Manus, and **attach the file
`safecheck-pharos.bundle`** (from `/home/parzival/safecheck-pharos.bundle`) to the message.

---

You are connected to my GitHub account. I'm attaching a **git bundle** named
`safecheck-pharos.bundle` that contains a complete git repository (full history, one commit
on the `main` branch). Please publish it to a new GitHub repository.

**Do exactly this:**

1. Save the attached `safecheck-pharos.bundle` to your working directory.
2. Reconstruct the repo from the bundle:
   ```bash
   git clone safecheck-pharos.bundle safecheck-pharos
   cd safecheck-pharos
   git checkout main
   ```
3. Create a **new public GitHub repository** under my account named **`safecheck-pharos`**
   with:
   - **Description:** `On-chain security guard skill + x402 agent-to-agent payment loop for the Pharos Agent Carnival`
   - **Topics:** `pharos`, `x402`, `ai-agent`, `web3-security`, `foundry`, `solidity`, `blockchain`, `hackathon`
   - Do **not** initialize it with a README, license, or .gitignore (the repo already has them; auto-init would cause a conflict).
4. Push the local `main` branch to the new repo and set it as the default branch:
   ```bash
   git remote add origin https://github.com/<my-username>/safecheck-pharos.git
   git push -u origin main
   ```
5. Verify: confirm the push succeeded, the `README.md` renders on the repo home page, and
   the commit is present on `main`.

**Important constraints:**
- Do **not** create, add, or commit any `.env` file or anything containing a private key.
  The repo intentionally omits them; keep it that way.
- Keep it a single commit exactly as bundled — do not squash, rebase, or rewrite history.
- If a repo named `safecheck-pharos` already exists, ask me before overwriting; do not force-push.

**Report back:** the full repository URL, its visibility, and confirmation that the README
renders and no secrets were committed.

---

## Fallback (if Manus cannot accept the bundle upload)

Ask Manus to only **create the empty public repo** (`safecheck-pharos`, same description and
topics, no auto-init) and return the HTTPS remote URL. Then I will push from my machine:

```bash
cd /home/parzival/pharos-carnival
git remote add origin https://github.com/<my-username>/safecheck-pharos.git
git push -u origin main
```
