#!/usr/bin/env bash

lsof -c Emacs | grep "emacs501" | tr -s " " | cut -d' ' -f8
