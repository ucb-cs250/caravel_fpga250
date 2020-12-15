#!/bin/bash

for ext in lef gds mag; do
    cp -v openlane/user_project_wrapper/runs/user_project_wrapper/results/magic/user_project_wrapper.${ext} ${ext}/ &
done
