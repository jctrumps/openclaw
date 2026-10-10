# ChatGPT Plus OAuth and OpenClaw model compatibility

ChatGPT Plus credentials are **not** equivalent to OpenAI API credentials. Use the supported **ChatGPT/Codex OAuth login**, not `OPENAI_API_KEY`, unless you intentionally want metered API billing.

## What is and is not guaranteed

- OpenClaw documents ChatGPT/Codex subscription OAuth; its provider id is `openai` for current releases.
- A successful OAuth login **does not guarantee** access to every named model. Actual authorization is enforced by OpenAI and depends on account, route and model availability.
- This project does **not** pre-select `gpt-6.1-sol`. The model previously working inside OpenCode does not prove the same model works inside OpenClaw/Codex runtime. Test a real completion.
- Your subscription's Codex usage limits apply, and additional third-party tools may carry separate charges.

## Device-code flow on the Ubuntu guest

SSH into the VM, then:

```bash
cd /opt/openclaw
docker compose run --rm --no-deps --entrypoint node openclaw-gateway \
  dist/index.js models auth login --provider openai --device-code
```

Follow the displayed login URL/code on a trusted browser and finish authentication. Credentials are persisted under `/srv/openclaw` via bind mounts, not inside your Git repository. Never copy credential files into docs or logs.

Check auth/catalog:

```bash
docker compose run --rm --no-deps --entrypoint node openclaw-gateway \
  dist/index.js models status
docker compose run --rm --no-deps --entrypoint node openclaw-gateway \
  dist/index.js models list --provider openai
```

Choose a model actually listed for your account, e.g. `openai/gpt-6-astra` if authorized:

```bash
docker compose run --rm --no-deps --entrypoint node openclaw-gateway \
  dist/index.js config set agents.defaults.model.primary openai/gpt-6-astra
docker compose up -d openclaw-gateway
```

Send a simple test question in the web UI; then try a modest tool-using task. If OpenClaw reports model not supported for ChatGPT sign-in, **do not confuse that with a failed OpenClaw deployment**: provider model permission is a separate boundary. Switch to a truly available model, inspect auth status and logs, and consult the official model page.

## OAuth expiration or an incorrect account

Re-run the device-code command from the VM. In recent versions, `openclaw models auth login --provider openai --force` is available to clear the selected provider profile and reauthenticate; **only use that if you intend to replace the saved OpenAI account**. Do not run `setup --baseline` against existing config to troubleshoot auth.

## Why it may differ from OpenCode

OpenCode and OpenClaw are separate client implementations, even when both say "ChatGPT login." Model discovery, transport selection, runtime policy, request headers and feature allowlists may differ. That explains why you must test the exact workload and model rather than assume compatibility based on your working OpenCode account.

## References

- <https://docs.openclaw.ai/providers/openai/setup>
- <https://docs.openclaw.ai/concepts/models>
- <https://docs.openclaw.ai/gateway/authentication>
