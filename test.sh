#!/bin/bash
export XY="ABC"
export PX="qwerty123"
export PID="abc123"

if [ -n "$PID" ]
then

  {
    jq '.parameters.aadClientSecret.value=env.PX' | \
    jq '.parameters.aadClientId.value=env.PID'
  } < azuredeploy0.parameters.json > azuredeploy-$XY.parameters.json

else
  echo "Uh oh! Houston, we've got a  problem!"
fi
