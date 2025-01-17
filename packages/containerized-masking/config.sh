#!/usr/bin/env bash
#
# Copyright 2021 Delphix
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# shellcheck disable=SC2034

#
# This package has the same Git URL as the 'masking' package. In general we
# probably don't want to have multiple packages with the same URL, since tools
# like git-ab-pre-push expect that there is a 1:1 correspondence between
# packages and URLs. However, this is OK in this case because git-ab-pre-push
# only works with packages that are included in the appliance, which this one
# isn't.
#
DEFAULT_PACKAGE_GIT_URL="https://github.com/delphix/dms-core-gate.git"

PACKAGE_DEPENDENCIES="adoptopenjdk"
SKIP_COPYRIGHTS_CHECK=true

function prepare() {
	logmust install_pkgs "$DEPDIR"/adoptopenjdk/*.deb
}

function build() {
	export JAVA_HOME
	JAVA_HOME=$(cat "$DEPDIR/adoptopenjdk/JDK_PATH") ||
		die "Failed to read $DEPDIR/adoptopenjdk/JDK_PATH"

	logmust cd "$WORKDIR/repo"

	if [[ "$SECRET_DB_AWS_ENDPOINT" ]]; then
		export SECRET_DB_AWS_ENDPOINT="$SECRET_DB_AWS_ENDPOINT"
	fi

	# Using secrets proxy
	if [[ "$SECRET_DB_USE_JUMPBOX" ]]; then
		export SECRET_DB_USE_JUMPBOX="$SECRET_DB_USE_JUMPBOX"
	fi
	if [[ "$SECRET_DB_JUMP_BOX_HOST" ]]; then
		export SECRET_DB_JUMP_BOX_HOST="$SECRET_DB_JUMP_BOX_HOST"
	fi
	if [[ "$SECRET_DB_JUMP_BOX_USER" ]]; then
		export SECRET_DB_JUMP_BOX_USER="$SECRET_DB_JUMP_BOX_USER"
	fi
	if [[ "$SECRET_DB_JUMP_BOX_PRIVATE_KEY" ]]; then
		export SECRET_DB_JUMP_BOX_PRIVATE_KEY="$SECRET_DB_JUMP_BOX_PRIVATE_KEY"
	fi

	# Using master/eng-secret-user
	if [[ "$SECRET_DB_AWS_PROFILE" ]]; then
		export SECRET_DB_AWS_PROFILE="$SECRET_DB_AWS_PROFILE"
	fi
	if [[ "$SECRET_DB_AWS_REGION" ]]; then
		export SECRET_DB_AWS_REGION="$SECRET_DB_AWS_REGION"
	fi

	logmust ./gradlew --no-daemon --stacktrace \
		-Porg.gradle.configureondemand=false \
		-PenvironmentName=linuxappliance \
		:tools:docker:packageMaskingKubernetes

	logmust cp -v tools/docker/build/masking-kubernetes*.zip \
		"$WORKDIR/artifacts/"
}
