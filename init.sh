#!/bin/sh
set -ex

# Load environment variables from .env if it exists
if [ -f /app/.env ]; then
    export $(grep -v '^#' /app/.env | xargs)
fi

DATA_DIR=/data
DEVPI_HOST=${DEVPI_HOST:-0.0.0.0}
DEVPI_PORT=${DEVPI_PORT:-3141}
DEVPI_OUTSIDE_URL=${DEVPI_OUTSIDE_URL:-http://127.0.0.1:3141}
DEVPI_INTERNAL_URL="http://127.0.0.1:$DEVPI_PORT"

ROOT_USER=${DEVPI_ROOT_USER:-root}
ROOT_PASSWORD=${DEVPI_ROOT_PASSWORD:-root}

USER_NAME=${DEVPI_USER:-devpiuser}
USER_PASSWORD=${DEVPI_USER_PASSWORD:-devpi123}
USER_INDEX=${DEVPI_USER_INDEX:-devpiuser/dev}

# Initialize devpi-server if not already
if [ ! -f "$DATA_DIR/.serverversion" ]; then
    echo "Initializing devpi-server..."
    devpi-init --serverdir "$DATA_DIR"
fi

# Start devpi-server in background
devpi-server \
    --serverdir "$DATA_DIR" \
    --host "$DEVPI_HOST" \
    --port "$DEVPI_PORT" \
    --outside-url "$DEVPI_OUTSIDE_URL" &

PID=$!

# Wait for server to be ready
if command -v curl >/dev/null 2>&1; then
    echo "Waiting for devpi to start at $DEVPI_INTERNAL_URL ..."
    for i in $(seq 1 15); do
        if curl -sSf "$DEVPI_INTERNAL_URL/+api" >/dev/null 2>&1; then
            echo "✅ devpi is up"
            break
        fi
        echo "Retrying ($i/15)..."
        sleep 2
    done
else
    echo "⚠️ curl not found, skipping health check"
fi

# Bootstrap users and indices if not already created
devpi use "$DEVPI_INTERNAL_URL"

if ! devpi user -l | grep -q "$USER_NAME"; then
    echo "🔧 Bootstrapping users and indices..."

    # login as root
    devpi login "$ROOT_USER" --password=""

    # set root password
    devpi user -m "$ROOT_USER" password="$ROOT_PASSWORD"

    # create default user and index
    devpi user -c "$USER_NAME" password="$USER_PASSWORD"
    devpi index -c "$USER_INDEX" bases=
    echo "✅ Created user '$USER_NAME' and index '$USER_INDEX'"
fi

# Wait a moment to ensure all data persisted
sleep 3

# Stop background server (only if it was started for bootstrap)
kill $PID
wait $PID || true

# Start devpi-server in foreground
exec devpi-server \
    --serverdir "$DATA_DIR" \
    --host "$DEVPI_HOST" \
    --port "$DEVPI_PORT" \
    --outside-url "$DEVPI_OUTSIDE_URL"
