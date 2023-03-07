#!make

# Copyright (c) 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

THEME=themes/redwood

dev: theme up

build: theme hugo

theme:
	cd $(THEME) && npm install

hugo:
	@hugo -D

up:
	@hugo server -D --disableFastRender
