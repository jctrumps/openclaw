# Built-in OpenClaw automations

OpenClaw includes a Gateway-backed automation/cron scheduler. You do not need Paperclip, Hermes, external cron, n8n or a browser tab open to run eligible scheduled agent tasks. The OpenClaw Gateway container must remain running and model authentication must remain valid.

**Before enabling automatic code changes** confirm Cloudflare Access, the Gateway token, GitHub token scopes, and actual ChatGPT inference. Start with reporting jobs before autonomous repository modifications.

## 1. Explore the current scheduler syntax

On the guest:

```bash
cd /opt/openclaw
docker compose run --rm openclaw-cli automations --help
# `cron` is a compatibility alias:
docker compose run --rm openclaw-cli cron --help
```

## 2. Create a low-risk test job

Documented current syntax puts the cron expression first, followed by the prompt. This example runs every weekday at 09:00 in the **Gateway's configured timezone**, `Etc/UTC`:

```bash
docker compose run --rm openclaw-cli \
  automations create '0 9 * * 1-5' \
  'Summarize one useful maintenance check to perform on my GitHub projects. Do not run commands or change files.' \
  --name 'Weekday maintenance suggestion'
```

Review the command's `--help` if your pinned OpenClaw release has changed flags. This job is intentionally advisory. A cron schedule does not necessarily produce an external notification: delivery requires a supported channel or you can inspect runs in the UI/CLI.

## 3. List and inspect jobs

```bash
docker compose run --rm openclaw-cli automations list
docker compose run --rm openclaw-cli automations --help
```

For run/edit/delete/disable commands, rely on `--help` for the exact installed version and **use the job identifier obtained from `list`**, not a guessed ID. An operator/admin permission may be required by the Gateway.

## 4. Graduation path for code automation

First: scheduled report only. Next: clone a test repository, run linter/tests and report findings. Then: create a branch with a proposed fix and open a PR requiring manual review. Only later allow actions with broader repository access. Keep one non-overlapping schedule at first, set timeouts, and track usage to prevent repeated loops on failed models.

## 5. Timezone and DST

The container receives `OPENCLAW_TZ=Etc/UTC`, but different scheduler versions can interpret timezone and session locality differently. Check CLI output and run history around DST changes. Use explicit timezone configuration in the scheduler if supported and verified for your release.

## 6. Stop runaway automation

If you observe unexpected repeated work, first stop/disable the offending job through the automation UI/CLI. If that's not possible, on the VM:

```bash
cd /opt/openclaw
docker compose stop openclaw-gateway
```

Stopping the gateway disables the scheduler until restarted. Investigate logs and model errors before resuming; automated retries can consume subscription usage without producing results.

## Reference

<https://docs.openclaw.ai/cli/cron>
