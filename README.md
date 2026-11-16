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

Credentials are injected by the sandbox proxy. The real key stays on the host;
the container only ever sees a proxy-managed sentinel.

```bash
printf '%s' "$FIREWORKS_API_KEY" | sbx secret set fireworks
```

`sbx` gives the sandbox a sentinel shaped like a fireworks key (`fw_...`) and
swaps it for the real value on requests to `api.fireworks.ai`. The agent never
sees the real key.

<details>
<summary>Fallback: custom secret with an explicit placeholder</summary>

If an older `sbx` produces a sentinel that pi's format check rejects, key the
secret to the host and environment variable directly, with a fireworks-shaped
placeholder:

```bash
printf '%s' "$FIREWORKS_API_KEY" | sbx secret set-custom -g \
  --host api.fireworks.ai \
  --env FIREWORKS_API_KEY \
  --placeholder "fw_{rand}" \
  --value-stdin
```

The proxy substitutes the placeholder on outbound requests to the configured
host. In this mode the kit's `credential@1` entry is optional and is skipped
when no `fireworks` service secret is bound, so remove any stored `fireworks`
service secret (`sbx secret rm fireworks`) to avoid two secrets claiming the
same environment variable.

</details>

## Run the sandbox

From the directory you want the agent to work on, build the local kit and start
pi:

```bash
sbx run --name pi-fireworks /path/to/pi-docker-sandbox/kits/fireworks
```

`sbx` builds the kit on first use (reusing the build cache afterwards), mounts
your current directory as the workspace, and launches pi. Approve the kit's
credential request when prompted.

Choose a model or thinking level when creating the sandbox:

```bash
sbx run --name pi-fireworks \
  --kit-arg model=accounts/fireworks/models/deepseek-v4p1-flash \
  --kit-arg thinkingLevel=high \
  /path/to/pi-docker-sandbox/kits/fireworks
```

Restarting an existing sandbox reuses the kit configuration it was created
with. To pick up kit edits or different arguments, create a sandbox under a
different name.

## What the kit configures

`kits/fireworks/fireworks.yaml` is the v3 workload descriptor:

- **Base image** — the companion `fireworks.dockerfile` starts `FROM
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
  and thinking level), installs a `fireworks-session-affinity` extension that
  pins each session to one backend for prompt-cache reuse, and points npm at
  the sandbox proxy.
- **Agent context** — `~/.pi/agent/AGENTS.md` describing the proxy-mediated
  auth, skills, and package installation.

## Publish the kit (optional)

Build and push the kit as an OCI artifact so others can run it without the
source directory:

```bash
docker login
docker buildx build ./kits/fireworks -f ./kits/fireworks/fireworks.yaml \
  -t docker.io/<NAMESPACE>/pi-fireworks:1.0.0 --push
```

Then run it by reference:

```bash
sbx run docker.io/<NAMESPACE>/pi-fireworks:1.0.0
```

The build needs a builder that supports the OCI exporter (the `sbx` kit
builder, or a `docker-container` Buildx driver); the default `docker` driver
does not.
