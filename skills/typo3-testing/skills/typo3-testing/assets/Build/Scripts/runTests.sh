#!/usr/bin/env bash

#
# TYPO3 Extension Test Runner
# Docker/podman-based test orchestration following TYPO3 core conventions.
#
# Template from: https://github.com/netresearch/typo3-testing-skill
# Reference: https://github.com/netresearch/t3x-nr-vault
#
# CUSTOMIZATION REQUIRED:
#   1. Replace 'my-extension' in NETWORK variable with your extension key
#   2. Set COMPOSER_ROOT_VERSION to your extension version
#   3. Adjust TYPO3_BASE_URL default for E2E tests
#   4. Remove mock OAuth section if not needed
#

trap 'cleanUp;exit 2' SIGINT

waitFor() {
    local HOST=${1}
    local PORT=${2}
    local TESTCOMMAND="
        COUNT=0;
        while ! nc -z ${HOST} ${PORT}; do
            if [ \"\${COUNT}\" -gt 10 ]; then
              echo \"Can not connect to ${HOST} port ${PORT}. Aborting.\";
              exit 1;
            fi;
            sleep 1;
            COUNT=\$((COUNT + 1));
        done;
    "
    ${CONTAINER_BIN} run ${CONTAINER_COMMON_PARAMS} --name wait-for-${SUFFIX} ${XDEBUG_MODE} -e XDEBUG_CONFIG="${XDEBUG_CONFIG}" ${IMAGE_ALPINE} /bin/sh -c "${TESTCOMMAND}"
    if [[ $? -gt 0 ]]; then
        kill -SIGINT -$$
    fi
}

waitForHttp() {
    local URL=${1}
    local MAX_ATTEMPTS=${2:-30}
    local TESTCOMMAND="
        COUNT=0;
        while ! wget -q --spider ${URL} 2>/dev/null; do
            if [ \"\${COUNT}\" -gt ${MAX_ATTEMPTS} ]; then
              echo \"HTTP endpoint ${URL} not available after ${MAX_ATTEMPTS} attempts. Aborting.\";
              exit 1;
            fi;
            sleep 1;
            COUNT=\$((COUNT + 1));
        done;
        echo \"HTTP endpoint ${URL} is ready.\";
    "
    ${CONTAINER_BIN} run ${CONTAINER_COMMON_PARAMS} --name wait-for-http-${SUFFIX} ${IMAGE_ALPINE} /bin/sh -c "${TESTCOMMAND}"
    if [[ $? -gt 0 ]]; then
        kill -SIGINT -$$
    fi
}

cleanUp() {
    ATTACHED_CONTAINERS=$(${CONTAINER_BIN} ps --filter network=${NETWORK} --format='{{.Names}}' 2>/dev/null)
    for ATTACHED_CONTAINER in ${ATTACHED_CONTAINERS}; do
        ${CONTAINER_BIN} rm -f ${ATTACHED_CONTAINER} >/dev/null 2>&1
    done
    ${CONTAINER_BIN} network rm ${NETWORK} >/dev/null 2>&1
}

cleanCacheFiles() {
    echo -n "Clean caches ... "
    rm -rf \
        .Build/.cache \
        .php-cs-fixer.cache \
        Tests/Build/.phpunit.cache
    echo "done"
}

handleDbmsOptions() {
    case ${DBMS} in
        mariadb)
            [ -z "${DATABASE_DRIVER}" ] && DATABASE_DRIVER="mysqli"
            if [ "${DATABASE_DRIVER}" != "mysqli" ] && [ "${DATABASE_DRIVER}" != "pdo_mysql" ]; then
                echo "Invalid combination -d ${DBMS} -a ${DATABASE_DRIVER}" >&2
                exit 1
            fi
            [ -z "${DBMS_VERSION}" ] && DBMS_VERSION="10.11"
            if ! [[ ${DBMS_VERSION} =~ ^(10.5|10.6|10.11|11.0|11.4)$ ]]; then
                echo "Invalid combination -d ${DBMS} -i ${DBMS_VERSION}" >&2
                exit 1
            fi
            ;;
        mysql)
            [ -z "${DATABASE_DRIVER}" ] && DATABASE_DRIVER="mysqli"
            if [ "${DATABASE_DRIVER}" != "mysqli" ] && [ "${DATABASE_DRIVER}" != "pdo_mysql" ]; then
                echo "Invalid combination -d ${DBMS} -a ${DATABASE_DRIVER}" >&2
                exit 1
            fi
            [ -z "${DBMS_VERSION}" ] && DBMS_VERSION="8.0"
            if ! [[ ${DBMS_VERSION} =~ ^(8.0|8.4|9.0)$ ]]; then
                echo "Invalid combination -d ${DBMS} -i ${DBMS_VERSION}" >&2
                exit 1
            fi
            ;;
        postgres)
            if [ -n "${DATABASE_DRIVER}" ]; then
                echo "Invalid combination -d ${DBMS} -a ${DATABASE_DRIVER}" >&2
                exit 1
            fi
            [ -z "${DBMS_VERSION}" ] && DBMS_VERSION="16"
            if ! [[ ${DBMS_VERSION} =~ ^(12|13|14|15|16|17)$ ]]; then
                echo "Invalid combination -d ${DBMS} -i ${DBMS_VERSION}" >&2
                exit 1
            fi
            ;;
        sqlite)
            if [ -n "${DATABASE_DRIVER}" ]; then
                echo "Invalid combination -d ${DBMS} -a ${DATABASE_DRIVER}" >&2
                exit 1
            fi
            ;;
        *)
            echo "Invalid option -d ${DBMS}" >&2
            exit 1
            ;;
    esac
}

loadHelp() {
    read -r -d '' HELP <<EOF
TYPO3 Extension test runner. Execute tests in Docker containers.

Usage: $0 [options] [file]

Options:
    -s <...>
        Specifies which test suite to run
            - cgl: PHP CS Fixer check/fix
            - clean: Clean temporary files
            - composer: Run composer commands
            - composerUpdate: Update dependencies
            - e2e: Playwright E2E tests (requires running TYPO3)
            - functional: PHP functional tests
            - functionalParallel: Parallel functional tests (faster)
            - functionalCoverage: Functional tests with coverage
            - lint: PHP linting
            - phpstan: PHPStan static analysis
            - unit: PHP unit tests (default)
            - unitCoverage: Unit tests with coverage
            - fuzz: Fuzz tests
            - mutation: Mutation testing

    -d <sqlite|mariadb|mysql|postgres>
        Database for functional tests (default: sqlite)

    -i version
        Database version (mariadb: 10.11, mysql: 8.0, postgres: 16)

    -p <8.2|8.3|8.4|8.5>
        PHP version (default: 8.5)

    -x
        Enable Xdebug for debugging

    -n
        Dry-run mode (for cgl, rector)

    -h
        Show this help

Examples:
    # Run unit tests
    ./Build/Scripts/runTests.sh -s unit

    # Run functional tests with MariaDB
    ./Build/Scripts/runTests.sh -s functional -d mariadb

    # Run E2E tests (requires ddev or TYPO3_BASE_URL)
    ddev start && ./Build/Scripts/runTests.sh -s e2e

E2E Tests:
    E2E tests require a running TYPO3 instance.
    Options:
        1. Start ddev: ddev start && ./Build/Scripts/runTests.sh -s e2e
        2. Set URL: TYPO3_BASE_URL=https://your-typo3.local ./Build/Scripts/runTests.sh -s e2e
EOF
}

# Check container runtime
if ! type "docker" >/dev/null 2>&1 && ! type "podman" >/dev/null 2>&1; then
    echo "This script requires docker or podman." >&2
    exit 1
fi

# Option defaults
TEST_SUITE="unit"
DATABASE_DRIVER=""
DBMS="sqlite"
DBMS_VERSION=""
PHP_VERSION="8.5"
PHP_XDEBUG_ON=0
PHP_XDEBUG_PORT=9003
CGLCHECK_DRY_RUN=0
CI_PARAMS="${CI_PARAMS:-}"
CONTAINER_BIN=""
CONTAINER_HOST="host.docker.internal"

# Parse options
OPTIND=1
while getopts "a:b:d:i:s:p:xy:nhu" OPT; do
    case ${OPT} in
        a) DATABASE_DRIVER=${OPTARG} ;;
        s) TEST_SUITE=${OPTARG} ;;
        b) CONTAINER_BIN=${OPTARG} ;;
        d) DBMS=${OPTARG} ;;
        i) DBMS_VERSION=${OPTARG} ;;
        p) PHP_VERSION=${OPTARG} ;;
        x) PHP_XDEBUG_ON=1 ;;
        y) PHP_XDEBUG_PORT=${OPTARG} ;;
        n) CGLCHECK_DRY_RUN=1 ;;
        h) loadHelp; echo "${HELP}"; exit 0 ;;
        u) TEST_SUITE=update ;;
        \?) exit 1 ;;
    esac
done

handleDbmsOptions

# CUSTOMIZE: Set your extension version
COMPOSER_ROOT_VERSION="1.x-dev"

HOST_UID=$(id -u)
USERSET=""
if [ $(uname) != "Darwin" ]; then
    USERSET="--user $HOST_UID"
fi

# Navigate to project root
THIS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
cd "$THIS_SCRIPT_DIR" || exit 1
cd ../../ || exit 1
ROOT_DIR="${PWD}"

# Create cache directories
mkdir -p .Build/.cache
mkdir -p .Build/web/typo3temp/var/tests

IMAGE_PREFIX="docker.io/"
TYPO3_IMAGE_PREFIX="ghcr.io/typo3/"
CONTAINER_INTERACTIVE="-it --init"

IS_CORE_CI=0
if [ "${CI}" == "true" ] || ! [ -t 0 ]; then
    IS_CORE_CI=1
    IMAGE_PREFIX=""
    CONTAINER_INTERACTIVE=""
fi

# Determine container binary
if [[ -z "${CONTAINER_BIN}" ]]; then
    if type "podman" >/dev/null 2>&1; then
        CONTAINER_BIN="podman"
    elif type "docker" >/dev/null 2>&1; then
        CONTAINER_BIN="docker"
    fi
fi

# Container images
IMAGE_PHP="${TYPO3_IMAGE_PREFIX}core-testing-$(echo "php${PHP_VERSION}" | sed -e 's/\.//'):latest"
IMAGE_ALPINE="${IMAGE_PREFIX}alpine:3.8"
IMAGE_MARIADB="docker.io/mariadb:${DBMS_VERSION}"
IMAGE_MYSQL="docker.io/mysql:${DBMS_VERSION}"
IMAGE_POSTGRES="docker.io/postgres:${DBMS_VERSION}-alpine"
IMAGE_PLAYWRIGHT="mcr.microsoft.com/playwright:v1.57.0-noble"
# Optional: Mock OAuth server for OAuth integration tests
# IMAGE_MOCK_OAUTH="ghcr.io/navikt/mock-oauth2-server:3.0.1"

shift $((OPTIND - 1))

# CUSTOMIZE: Replace 'my-extension' with your extension key
SUFFIX=$(echo $RANDOM)
NETWORK="my-extension-${SUFFIX}"
${CONTAINER_BIN} network create ${NETWORK} >/dev/null

if [ ${CONTAINER_BIN} = "docker" ]; then
    CONTAINER_COMMON_PARAMS="${CONTAINER_INTERACTIVE} --rm --network ${NETWORK} --add-host "${CONTAINER_HOST}:host-gateway" ${USERSET} -v ${ROOT_DIR}:${ROOT_DIR} -w ${ROOT_DIR}"
else
    CONTAINER_HOST="host.containers.internal"
    CONTAINER_COMMON_PARAMS="${CONTAINER_INTERACTIVE} ${CI_PARAMS} --rm --network ${NETWORK} -v ${ROOT_DIR}:${ROOT_DIR} -w ${ROOT_DIR}"
fi

if [ ${PHP_XDEBUG_ON} -eq 0 ]; then
    XDEBUG_MODE="-e XDEBUG_MODE=off"
    XDEBUG_CONFIG=" "
else
    XDEBUG_MODE="-e XDEBUG_MODE=debug -e XDEBUG_TRIGGER=foo"
    XDEBUG_CONFIG="client_port=${PHP_XDEBUG_PORT} client_host=${CONTAINER_HOST}"
fi

# PHP performance options
PHP_OPCACHE_OPTS="-d opcache.enable_cli=1 -d opcache.jit=1255 -d opcache.jit_buffer_size=128M"

# Suite execution
case ${TEST_SUITE} in
    cgl)
        if [ "${CGLCHECK_DRY_RUN}" -eq 1 ]; then
            COMMAND="php ${PHP_OPCACHE_OPTS} -dxdebug.mode=off .Build/bin/php-cs-fixer fix -v --dry-run --diff"
        else
            COMMAND="php ${PHP_OPCACHE_OPTS} -dxdebug.mode=off .Build/bin/php-cs-fixer fix -v"
        fi
        ${CONTAINER_BIN} run ${CONTAINER_COMMON_PARAMS} --name cgl-${SUFFIX} -e COMPOSER_CACHE_DIR=.Build/.cache/composer -e COMPOSER_ROOT_VERSION=${COMPOSER_ROOT_VERSION} ${IMAGE_PHP} /bin/sh -c "${COMMAND}"
        SUITE_EXIT_CODE=$?
        ;;
    clean)
        cleanCacheFiles
        ;;
    composer)
        COMMAND=(composer "$@")
        ${CONTAINER_BIN} run ${CONTAINER_COMMON_PARAMS} --name composer-${SUFFIX} -e COMPOSER_CACHE_DIR=.Build/.cache/composer -e COMPOSER_ROOT_VERSION=${COMPOSER_ROOT_VERSION} ${IMAGE_PHP} "${COMMAND[@]}"
        SUITE_EXIT_CODE=$?
        ;;
    composerUpdate)
        rm -rf .Build/bin/ .Build/vendor ./composer.lock
        COMMAND=(composer install --no-ansi --no-interaction --no-progress)
        ${CONTAINER_BIN} run ${CONTAINER_COMMON_PARAMS} --name composer-${SUFFIX} -e COMPOSER_CACHE_DIR=.Build/.cache/composer -e COMPOSER_ROOT_VERSION=${COMPOSER_ROOT_VERSION} ${IMAGE_PHP} "${COMMAND[@]}"
        SUITE_EXIT_CODE=$?
        ;;
    e2e)
        # CUSTOMIZE: Set your default TYPO3 URL
        if [ -n "${TYPO3_BASE_URL:-}" ]; then
            echo "Using TYPO3_BASE_URL from environment: ${TYPO3_BASE_URL}"
        elif type "ddev" >/dev/null 2>&1 && ddev describe >/dev/null 2>&1; then
            TYPO3_BASE_URL="https://my-extension.ddev.site"
            echo "Using ddev TYPO3 URL: ${TYPO3_BASE_URL}"
        else
            TYPO3_BASE_URL="https://my-extension.ddev.site"
            echo "Warning: No TYPO3 instance detected."
            echo "E2E tests require a running TYPO3 instance."
            echo "  1. Start ddev: ddev start"
            echo "  2. Or set: TYPO3_BASE_URL=https://your-typo3.local $0 -s e2e"
        fi

        mkdir -p .Build/.cache/npm
        mkdir -p node_modules

        # Check for permission issues (root-owned files from previous container runs)
        if [ -d "node_modules" ] && [ "$(find node_modules -maxdepth 1 -user root 2>/dev/null | head -1)" ]; then
            echo "Error: node_modules contains root-owned files."
            echo "Please remove and retry: sudo rm -rf node_modules"
            exit 1
        fi

        # Connect to ddev network if available
        DDEV_PARAMS=""
        if type "ddev" >/dev/null 2>&1 && ddev describe >/dev/null 2>&1; then
            ROUTER_IP=$(${CONTAINER_BIN} inspect ddev-router --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null)
            if [ -n "${ROUTER_IP}" ]; then
                DDEV_PARAMS="--network ddev_default"
                # CUSTOMIZE: Add your ddev hostnames
                DDEV_PARAMS="${DDEV_PARAMS} --add-host my-extension.ddev.site:${ROUTER_IP}"
                echo "Connecting to ddev network (router IP: ${ROUTER_IP})"
            fi
        fi

        COMMAND="npm ci && npx playwright test $*"
        ${CONTAINER_BIN} run ${CONTAINER_COMMON_PARAMS} ${DDEV_PARAMS} --name e2e-${SUFFIX} \
            -e TYPO3_BASE_URL="${TYPO3_BASE_URL}" \
            -e CI="${CI:-}" \
            -e npm_config_cache="${ROOT_DIR}/.Build/.cache/npm" \
            ${IMAGE_PLAYWRIGHT} /bin/bash -c "${COMMAND}"
        SUITE_EXIT_CODE=$?
        ;;
    functional)
        COMMAND=(php ${PHP_OPCACHE_OPTS} -dxdebug.mode=off .Build/bin/phpunit -c Tests/Build/FunctionalTests.xml --exclude-group not-${DBMS} "$@")

        case ${DBMS} in
            mariadb)
                echo "Using driver: ${DATABASE_DRIVER}"
                ${CONTAINER_BIN} run --rm ${CI_PARAMS} --name mariadb-func-${SUFFIX} --network ${NETWORK} -d -e MYSQL_ROOT_PASSWORD=funcp --tmpfs /var/lib/mysql/:rw,noexec,nosuid ${IMAGE_MARIADB} >/dev/null
                waitFor mariadb-func-${SUFFIX} 3306
                CONTAINERPARAMS="-e typo3DatabaseDriver=${DATABASE_DRIVER} -e typo3DatabaseName=func_test -e typo3DatabaseUsername=root -e typo3DatabaseHost=mariadb-func-${SUFFIX} -e typo3DatabasePassword=funcp"
                ${CONTAINER_BIN} run ${CONTAINER_COMMON_PARAMS} --name functional-${SUFFIX} ${XDEBUG_MODE} -e XDEBUG_CONFIG="${XDEBUG_CONFIG}" ${CONTAINERPARAMS} ${IMAGE_PHP} "${COMMAND[@]}"
                SUITE_EXIT_CODE=$?
                ;;
            mysql)
                echo "Using driver: ${DATABASE_DRIVER}"
                ${CONTAINER_BIN} run --rm ${CI_PARAMS} --name mysql-func-${SUFFIX} --network ${NETWORK} -d -e MYSQL_ROOT_PASSWORD=funcp --tmpfs /var/lib/mysql/:rw,noexec,nosuid ${IMAGE_MYSQL} >/dev/null
                waitFor mysql-func-${SUFFIX} 3306
                CONTAINERPARAMS="-e typo3DatabaseDriver=${DATABASE_DRIVER} -e typo3DatabaseName=func_test -e typo3DatabaseUsername=root -e typo3DatabaseHost=mysql-func-${SUFFIX} -e typo3DatabasePassword=funcp"
                ${CONTAINER_BIN} run ${CONTAINER_COMMON_PARAMS} --name functional-${SUFFIX} ${XDEBUG_MODE} -e XDEBUG_CONFIG="${XDEBUG_CONFIG}" ${CONTAINERPARAMS} ${IMAGE_PHP} "${COMMAND[@]}"
                SUITE_EXIT_CODE=$?
                ;;
            postgres)
                ${CONTAINER_BIN} run --rm ${CI_PARAMS} --name postgres-func-${SUFFIX} --network ${NETWORK} -d -e POSTGRES_PASSWORD=funcp -e POSTGRES_USER=funcu --tmpfs /var/lib/postgresql/data:rw,noexec,nosuid ${IMAGE_POSTGRES} >/dev/null
                waitFor postgres-func-${SUFFIX} 5432
                CONTAINERPARAMS="-e typo3DatabaseDriver=pdo_pgsql -e typo3DatabaseName=bamboo -e typo3DatabaseUsername=funcu -e typo3DatabaseHost=postgres-func-${SUFFIX} -e typo3DatabasePassword=funcp"
                ${CONTAINER_BIN} run ${CONTAINER_COMMON_PARAMS} --name functional-${SUFFIX} ${XDEBUG_MODE} -e XDEBUG_CONFIG="${XDEBUG_CONFIG}" ${CONTAINERPARAMS} ${IMAGE_PHP} "${COMMAND[@]}"
                SUITE_EXIT_CODE=$?
                ;;
            sqlite)
                mkdir -p "${ROOT_DIR}/.Build/web/typo3temp/var/tests/functional-sqlite-dbs/"
                CONTAINERPARAMS="-e typo3DatabaseDriver=pdo_sqlite --tmpfs ${ROOT_DIR}/.Build/web/typo3temp/var/tests/functional-sqlite-dbs/:rw,noexec,nosuid"
                ${CONTAINER_BIN} run ${CONTAINER_COMMON_PARAMS} --name functional-${SUFFIX} ${XDEBUG_MODE} -e XDEBUG_CONFIG="${XDEBUG_CONFIG}" ${CONTAINERPARAMS} ${IMAGE_PHP} "${COMMAND[@]}"
                SUITE_EXIT_CODE=$?
                ;;
        esac
        ;;
    functionalParallel)
        # Parallel functional tests using xargs
        # Each test file runs in isolation with its own SQLite database
        mkdir -p "${ROOT_DIR}/.Build/web/typo3temp/var/tests/functional-sqlite-dbs/"

        # CI: fixed jobs for predictable resource usage
        # Local: half of available CPUs
        if [ "${CI}" == "true" ]; then
            PARALLEL_JOBS=4
        else
            PARALLEL_JOBS="\$(((\$(nproc) + 1) / 2))"
        fi

        COMMAND="find Tests/Functional -name '*Test.php' | xargs -P${PARALLEL_JOBS} -I{} php ${PHP_OPCACHE_OPTS} -dxdebug.mode=off .Build/bin/phpunit -c Tests/Build/FunctionalTests.xml {}"
        CONTAINERPARAMS="-e typo3DatabaseDriver=pdo_sqlite --tmpfs ${ROOT_DIR}/.Build/web/typo3temp/var/tests/functional-sqlite-dbs/:rw,noexec,nosuid"
        ${CONTAINER_BIN} run ${CONTAINER_COMMON_PARAMS} --name functional-parallel-${SUFFIX} ${XDEBUG_MODE} -e XDEBUG_CONFIG="${XDEBUG_CONFIG}" ${CONTAINERPARAMS} ${IMAGE_PHP} /bin/sh -c "${COMMAND}"
        SUITE_EXIT_CODE=$?
        ;;
    functionalCoverage)
        mkdir -p .Build/coverage
        COMMAND=(php -d opcache.enable_cli=1 .Build/bin/phpunit -c Tests/Build/FunctionalTests.xml --coverage-clover=.Build/coverage/functional.xml --coverage-html=.Build/coverage/html-functional --coverage-text "$@")
        mkdir -p "${ROOT_DIR}/.Build/web/typo3temp/var/tests/functional-sqlite-dbs/"
        CONTAINERPARAMS="-e typo3DatabaseDriver=pdo_sqlite --tmpfs ${ROOT_DIR}/.Build/web/typo3temp/var/tests/functional-sqlite-dbs/:rw,noexec,nosuid"
        ${CONTAINER_BIN} run ${CONTAINER_COMMON_PARAMS} --name functional-coverage-${SUFFIX} -e XDEBUG_MODE=coverage ${CONTAINERPARAMS} ${IMAGE_PHP} "${COMMAND[@]}"
        SUITE_EXIT_CODE=$?
        ;;
    lint)
        COMMAND="find . -name \\*.php ! -path \"./.Build/\\*\" -print0 | xargs -0 -n1 -P\$(nproc) php ${PHP_OPCACHE_OPTS} -dxdebug.mode=off -l >/dev/null"
        ${CONTAINER_BIN} run ${CONTAINER_COMMON_PARAMS} --name lint-${SUFFIX} ${IMAGE_PHP} /bin/sh -c "${COMMAND}"
        SUITE_EXIT_CODE=$?
        ;;
    phpstan)
        COMMAND="php ${PHP_OPCACHE_OPTS} -dxdebug.mode=off .Build/bin/phpstan analyse"
        ${CONTAINER_BIN} run ${CONTAINER_COMMON_PARAMS} --name phpstan-${SUFFIX} -e COMPOSER_ROOT_VERSION=${COMPOSER_ROOT_VERSION} ${IMAGE_PHP} /bin/sh -c "${COMMAND}"
        SUITE_EXIT_CODE=$?
        ;;
    unit)
        COMMAND=(php ${PHP_OPCACHE_OPTS} -dxdebug.mode=off .Build/bin/phpunit -c Tests/Build/phpunit.xml --testsuite Unit "$@")
        ${CONTAINER_BIN} run ${CONTAINER_COMMON_PARAMS} --name unit-${SUFFIX} ${XDEBUG_MODE} -e XDEBUG_CONFIG="${XDEBUG_CONFIG}" ${IMAGE_PHP} "${COMMAND[@]}"
        SUITE_EXIT_CODE=$?
        ;;
    unitCoverage)
        mkdir -p .Build/coverage
        COMMAND=(php -d opcache.enable_cli=1 .Build/bin/phpunit -c Tests/Build/phpunit.xml --testsuite Unit --coverage-clover=.Build/coverage/unit.xml --coverage-html=.Build/coverage/html-unit --coverage-text "$@")
        ${CONTAINER_BIN} run ${CONTAINER_COMMON_PARAMS} --name unit-coverage-${SUFFIX} -e XDEBUG_MODE=coverage ${IMAGE_PHP} "${COMMAND[@]}"
        SUITE_EXIT_CODE=$?
        ;;
    fuzz)
        COMMAND=(php ${PHP_OPCACHE_OPTS} -dxdebug.mode=off .Build/bin/phpunit -c Tests/Build/phpunit.xml --testsuite Fuzz "$@")
        ${CONTAINER_BIN} run ${CONTAINER_COMMON_PARAMS} --name fuzz-${SUFFIX} ${XDEBUG_MODE} -e XDEBUG_CONFIG="${XDEBUG_CONFIG}" ${IMAGE_PHP} "${COMMAND[@]}"
        SUITE_EXIT_CODE=$?
        ;;
    mutation)
        COMMAND=(php -d opcache.enable_cli=1 .Build/bin/infection --configuration=infection.json5 --threads=4 "$@")
        ${CONTAINER_BIN} run ${CONTAINER_COMMON_PARAMS} --name mutation-${SUFFIX} -e XDEBUG_MODE=coverage ${IMAGE_PHP} "${COMMAND[@]}"
        SUITE_EXIT_CODE=$?
        ;;
    update)
        echo "> Updating ${TYPO3_IMAGE_PREFIX}core-testing-* images..."
        ${CONTAINER_BIN} images "${TYPO3_IMAGE_PREFIX}core-testing-*" --format "{{.Repository}}:{{.Tag}}" | xargs -I {} ${CONTAINER_BIN} pull {}
        ;;
    *)
        loadHelp
        echo "Invalid -s option: ${TEST_SUITE}" >&2
        echo "${HELP}" >&2
        exit 1
        ;;
esac

cleanUp

# Print summary
echo "" >&2
echo "###########################################################################" >&2
echo "Result of ${TEST_SUITE}" >&2
echo "Container runtime: ${CONTAINER_BIN}" >&2
if [[ ${IS_CORE_CI} -eq 1 ]]; then
    echo "Environment: CI" >&2
else
    echo "Environment: local" >&2
fi
echo "PHP: ${PHP_VERSION}" >&2
if [[ ${TEST_SUITE} =~ ^functional ]]; then
    echo "DBMS: ${DBMS}" >&2
fi
if [[ ${SUITE_EXIT_CODE} -eq 0 ]]; then
    echo "SUCCESS" >&2
else
    echo "FAILURE" >&2
fi
echo "###########################################################################" >&2
echo "" >&2

exit $SUITE_EXIT_CODE
