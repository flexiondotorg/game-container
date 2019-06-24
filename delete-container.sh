#!/usr/bin/env bash

delete-container() {
  lxc stop game-container --force
  lxc delete game-container --force
  lxc profile delete game-container
  lxc alias remove ubuntu
}

delete-container