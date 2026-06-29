#!/bin/sh
set -eu

vagrant cloud auth login --token "$(hcp auth print-access-token)"
