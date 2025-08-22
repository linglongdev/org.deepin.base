#!/bin/bash
source version.bash
ll-builder list | grep "$APPID/$VERSION" | xargs ll-builder remove
ll-builder import-dir output/binary
ll-builder import-dir output/develop

