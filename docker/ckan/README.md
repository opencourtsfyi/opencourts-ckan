# OpenCourts CKAN Docker Setup

This directory contains the custom Docker configuration for the OpenCourts CKAN instance.

## Structure

- `Dockerfile.dev` - Custom development image that extends `ckan/ckan-dev:2.11` with ckanext-scheming
- `docker-entrypoint.d/` - Optional custom initialization scripts (copied into container at build time)

## Building

The image is built via `docker-compose.dev.override.yml` which references this directory as the build context.
