# Pi coding agent Docker sandbox (fireworks.ai)

VM-hypervised and -isolated, proxy-gated Docker sandboxes for running the
[pi](https://pi.dev/) coding agent with [fireworks.ai](https://fireworks.ai/).

The sandbox is a **v3 workload kit** built on Docker's official hardened pi
image (`docker.io/sbx/pi`). The kit declares the fireworks network policy and
credential, and removes the official image's embedded kit descriptor so the
sandbox carries no bundled-provider (Anthropic) configuration.

Read the [Docker Sandboxes docs](https://docs.docker.com/ai/sandboxes/) and
install `sbx` using their instructions. There are several pre-reqs if your dev
machine is running Linux. Docker with Buildx is needed to build kits.

## Store the fireworks key

Credentials are injected by the sandbox proxy.

```bash
printf '%s' "$FIREWORKS_API_KEY" | sbx secret set fireworks
```

`sbx` gives the sandbox a fake key like a fireworks key (`fw_...`) and
swaps it on the host for the real value on requests to `api.fireworks.ai`. The agent never
sees the real key.

## Run the sandbox

From the directory you want the agent to work on, build the local kit and start
pi:

```bash
sbx run --name pi-myproject /path/to/pi-docker-sandbox/kits/pi-fireworks
```

`sbx` builds the kit on first use (reusing the build cache afterwards), mounts
your current directory as the workspace, and launches pi. Approve the kit's
credential request when prompted.

Choose a model or thinking level when creating the sandbox:

```bash
sbx run --name pi-fireworks \
  --kit-arg model=accounts/fireworks/models/deepseek-v4p1-flash \
  --kit-arg thinkingLevel=low \
  /path/to/pi-docker-sandbox/kits/pi-fireworks
```

Restarting an existing sandbox reuses the kit configuration it was created
with. To pick up kit edits or different arguments, create a sandbox under a
different name.

## What the kit configures

`kits/pi-fireworks/pi-fireworks.yaml` is the v3 workload descriptor:

- **Base image** — the companion `pi-fireworks.dockerfile` starts `FROM
  docker.io/sbx/pi:latest` and deletes `/usr/share/sandbox/kit/pi`, the
  official descriptor that declares Anthropic network access and an Anthropic
  credential.
- **Network policy** — egress to `api.fireworks.ai` (and `*.fireworks.ai`),
  plus pi's metadata/update host, pi's runtime npm registry, and the base
  image's apt mirrors. Everything else is denied by default.
- **Credential** — the `fireworks` service with a proxy-managed
  `FIREWORKS_API_KEY`, injected as `Authorization: Bearer <key>` on requests
  to `api.fireworks.ai`.
- **Session control** — headless and interactive pi session verbs.
- **Setup** — seeds `~/.pi/agent/settings.json` (project trust, optional model
  and thinking level) and points npm at the sandbox proxy.
- **Agent context** — `~/.pi/agent/AGENTS.md` describing the proxy-mediated
  auth, skills, and package installation.
