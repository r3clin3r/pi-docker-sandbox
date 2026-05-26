# Pi coding agent docker sandbox

VM-hypervised and -isolated, proxy-gated Docker containers for running the [pi](https://pi.dev/) agent locally.

Read the new docker sandbox [docs](https://www.docker.com/products/docker-sandboxes/) and install `sbx` using their instructions. There are several pre-reqs if your dev machine is running Linux.

Clone this repo to build your own sandbox.

Steps (assuming fresh start):

```bash
# Build according to Dockerfile.
# This creates a VM-hosted (!) ubuntu container sandbox, called a template, with pi agent installed.
docker build -D -t pi-docker-sandbox:latest .

# dump the image and load into sbx
# private images must be marshalled via tar or docker hub at time of writing
./load-sandbox-image.sh

# Create and run the bare pi agent sandbox using the template
# This drops you into a shell, invoke pi yourself and set up your config.
# Do not manually auth using an API key inside your worktree or the sandbox--pi saves the key to disk.
# Instead, rely on sbx injecting env vars from your dev machine ("host") into relevant requests. 
sbx run -t pi-docker-sandbox:latest shell

# Once you've manually configured pi the sandbox can be turned into a template
sbx template save shell-pi-docker-sandbox shell-pi-ready -o shell-pi-ready.tar
sbx template load shell-pi-ready.tar

# Now, start pi directly with your configured agent
sbx run -t shell-pi-ready shell -- -l -c pi
```

## Run pi-fireworks kit

Kits can be used to add config in bulk, rather than applying config manually as above.

First add `FIREWORKS_API_KEY` to the Docker sbx proxy that intercepts outbound calls and inject a dummy random value for the agent into sandboxes (globally):

```bash
sbx secret set-custom -g \
  --host api.fireworks.ai \
  --env FIREWORKS_API_KEY \
  --placeholder "fw-{rand}" \
  --value "${FIREWORKS_API_KEY@P}"
```

The agent never sees the real value.

The placeholder is necessary because the pi harness/client checks validity of the API_KEY format, otherwise one could use `environment.proxyManaged` in the kit spec.yaml file.

To enter straight into a sandboxed pi with the FIREWORKS_API_KEY injected via proxy, run:

```bash
sbx run pi-fireworks --kit ./kits/fireworks/
```

TODO:
 - Add session affinity plugin to kit (relies somewhat on https://github.com/docker/sbx-releases/issues/133)
 - Sourcing .bashrc in the kit commands might be superfluous, check it
