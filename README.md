# Pi coding agent docker sandbox

See the new docker sandbox [docs](https://www.docker.com/products/docker-sandboxes/), install `sbx` using their instructions (there are pre-reqs if your dev machine is running Linux).

Steps (assuming fresh start):

```bash
# build according to Dockerfile: this creates a VM-hosted (!) ubuntu container sandbox, called a template, with pi agent installed
docker build -D -t pi-docker-sandbox:latest .

# dump the image and load into sbx (private images must be marshalled via tar at time of writing)
./load-sandbox-image.sh

# run the bare pi agent sandbox using the template (to shell only, invoke pi yourself)
sbx run -t pi-docker-sandbox:latest shell
```

## Run pi-fireworks kit

Add FIREWORKS_API_KEY to the proxy that intercepts service calls and inject a dummy rand value into sandboxes globally:

```bash
sbx secret set-custom -g \
  --host api.fireworks.ai \
  --env FIREWORKS_API_KEY \
  --placeholder "fw-{rand}" \
  --value "${FIREWORKS_API_KEY@P}"
```

This is necessary because the pi harness/client checks validity of API_KEY format, otherwise one could use environment.proxyManaged in the kit spec.yaml file.

To enter straight into a sandboxed pi with the real FIREWORKS_API_KEY injected via proxy, run:

```bash
sbx run pi-fireworks --kit ./kits/fireworks/
```

TODO:
 - Add session affinity plugin (relies somewhat on https://github.com/docker/sbx-releases/issues/133)
 - Sourcing .bashrc in the kit commands might be superfluous, check it
