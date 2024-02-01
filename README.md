# workflow.pacta.report

# Description

The Dockerfile in this repository creates an image containing a freshly
cloned copy of `workflow.pacta.report`. It also installs the relevant PACTA R
packages that it depends on.

# Notes

Running PACTA also requires pacta-data, which needs to be mounted into the
container at run-time.

# Using Docker images pushed to GHCR automatically by GH Actions

``` {.bash}

tag_name=main
image_name=ghcr.io/rmi-pacta/workflow.pacta.report:$tag_name
data_dir=~/Downloads/2022Q4_transition_monitor_inputs_2023-07-11/
input_dir=./input_dir
output_dir=./output_dir

# Build
docker build . -t $image_name

# Run
docker run --rm \
  --network none \
  --platform linux/amd64 \
  --env LOG_LEVEL=DEBUG \
  --mount type=bind,readonly,source=${data_dir},target=/pacta-data \
  --mount type=bind,source=${output_dir},target=/output_dir \
  --mount type=bind,source=${input_dir},target=/input_dir \
  $image_name

```

```sh

# Run R in container
docker run -it --rm \
  --network none \
  --platform linux/amd64 \
  --env LOG_LEVEL=TRACE \
  --mount type=bind,readonly,source=${data_dir},target=/pacta-data \
  --mount type=bind,source=${output_dir},target=/output_dir \
  --mount type=bind,source=${input_dir},target=/input_dir \
  --entrypoint R
  $image_name

```
