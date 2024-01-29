#! /bin/bash

randstr=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
project=constructionbots
containerid=$project-build-$randstr
imageid=$project-build-$(id -u)

mkdir -p $PWD/output/
podman run --rm \
    --name $containerid \
    -v "$PWD/output:/ConstructionBots/output" \
    -v "/usr/share/ldraw:/usr/share/ldraw" \
    $project \
    julia --project=. -e "using ConstructionBots; ConstructionBots.run_lego_demo(;ldraw_file=\"$1\", base_results_path=\".\", results_path=\"output\", save_milp_solution=true, save_animation=true)"
