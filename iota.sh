#!/bin/bash

set -e

# TODO: Check prerequisites (docker, docker compose, jq)

COLOR_GREEN=$'\033[0;32m'
COLOR_LIGHT_GREEN=$'\033[1;32m'
COLOR_LIGHT_BLUE=$'\033[1;34m'
COLOR_RED=$'\033[0;31m'
COLOR_WHITE=$'\033[1;37m'
COLOR_GRAY=$'\033[0;90m'
COLOR_RESET=$'\033[0m'

print_info() {
    echo -e "🔵 ${COLOR_LIGHT_BLUE}$1${COLOR_RESET}\n"
}

print_success() {
    echo -e "🟢 ${COLOR_LIGHT_GREEN}$1${COLOR_RESET}\n"
}

print_error() {
    echo -e "🔴 ${COLOR_RED}$1${COLOR_RESET}\n"
}

# Set the working directory to the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Make sure to switch back to the previous directory after the script finishes
trap 'cd - > /dev/null' EXIT

print_usage() {
cat <<END
Usage: $0 [options] <command> [args...]

Commands:
  start                Start the IOTA network services
  stop                 Stop the IOTA network services
  reset                Reset the environment and start fresh

  show-balance [address]
                       Show the balance of a given address
                       (if no address is provided, a default test address
                       will be used)

  pay-iota <from-address> <to-address> <amount>
                       Pay IOTA from one address to another
                       (if the amount has a decimal point, it is assumed
                       to be in IOTA, otherwise it is assumed to be in NANOS)

  show-qr-code [words...]
                       Show a QR code for the given wallet recovery phrase

Options:
  --verbose            Enable verbose output
  --help               Show this help message
END
}

# Do not exit on unrecognized options
set +e

OPTIONS=$(getopt -o '' -l 'verbose,help' --name "$0" -q -- "$@")

if [[ $? -ne 0 ]]; then
    print_usage
    exit 1
fi

set -e

eval "set -- $OPTIONS"

OPT_VERBOSE=0

OUT='/dev/null'

while true; do
    case $1 in
        (--help)
            print_usage
            exit 0
            ;;
        (--verbose)
            OPT_VERBOSE=1
            OUT='/dev/stdout'
            shift
            ;;
        (--)
            shift
            break
            ;;
        (*)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

_run_iota_commands() {
    local COMMANDS=("$@")

    for COMMAND in "${COMMANDS[@]}"; do
        if [ -z "$COMMAND" ]; then
            continue
        fi

        # If a command starts with "!", do not output it even if verbose mode
        # is enabled (hidden command, irrelevant for the user)
        if [[ "$COMMAND" == \!* ]]; then
            COMMAND="${COMMAND:1}"
        else
            echo -e "${COLOR_GRAY}> ${COLOR_WHITE}${COMMAND}${COLOR_RESET}" \
                > "$OUT"
        fi

        # If stdout is a terminal, use a different color for the command output
        if [ -t 1 ]; then
            echo -ne "${COLOR_GRAY}" > /dev/stdout
        fi

        docker compose run --rm iota-tools sh -c "$COMMAND" 2>&1

        if [ -t 1 ]; then
            echo -ne "${COLOR_RESET}" > /dev/stdout
        fi

        if [ $? -ne 0 ]; then
            return 1
        fi
    done
}

init_genesis() {
    if [ ! -s ./iota/common/genesis.blob ]; then
        print_info "Genesis blob not found, generating a new one..."

        docker compose up --force-recreate iota-tools > /dev/null 2>&1

        if [ -s ./iota/common/genesis.blob ]; then
            print_success "Genesis blob generated successfully"
        else
            print_error "Failed to generate genesis blob"
            exit 1
        fi
    fi
}

start_services() {
    local SERVICES=(
        "iota-validator-node-1"
        "iota-validator-node-2"
        "iota-full-node-1"
        "iota-full-node-2"
    )

    # Check if the services are already running
    for SERVICE in "${SERVICES[@]}"; do
        if docker compose ps --format '{{.Service}}: {{.State}}' | \
                grep -q "$SERVICE: running";
        then
            return
        else
            print_info "Starting $SERVICE..."
            docker compose up -d "$SERVICE" > /dev/null 2>&1 || \
                docker compose restart "$SERVICE" > /dev/null 2>&1
        fi
    done

    print_info "Waiting for all services to be up and running..."

    local ATTEMPT=1

    while [ $ATTEMPT -le 4 ]; do
        if docker compose ps --format '{{.Service}}: {{.State}}' | \
                grep -qE 'iota-(validator|full)-node-[12]: running';
        then
            print_success "All services are running"
            return
        fi
        
        sleep 5
        
        ((ATTEMPT++))
    done

    print_error "Failed to start all services"
    exit 1
}

#
# Commands that are used to manage the environment
#

# Start the IOTA network services
start() {
    print_info "Starting IOTA network services..."

    # Do nothing, start will be handled by the main script
    true
}

# Stop the IOTA network services
stop() {
    print_info "Stopping all services..."

    docker compose down --remove-orphans > /dev/null 2>&1

    if [ $? -ne 0 ]; then
        print_error "Failed to stop services"
        exit 1
    fi

    print_success "All services stopped successfully"
}

# Reset the environment and start fresh
reset() {
    print_info "Resetting the environment..."

    docker compose down --remove-orphans > /dev/null 2>&1

    if [ $? -ne 0 ]; then
        print_error "Failed to stop services"
        exit 1
    fi

    rm -f ./iota/common/genesis.blob

    print_success "Environment reset successfully"
}

TEST_1_ADDRESS="0x6e7e7f006415396c89f30ad0482f5a580e18f23af808f3e81bb2f7185f2c0cf6"
TEST_2_ADDRESS="0x83c86688e0d2dbbd68dd8f3caf4634b0b0fe9d2e9229f2260ae21598683bfa67"

#
# Commands that are used to interact with the IOTA network
#

# Show the balance of a given address
show_balance() {
    local ADDRESS="$1"

    if [ -z "$ADDRESS" ]; then
        print_info "No address provided, using default wallet address"
        ADDRESS="$TEST_1_ADDRESS"
    fi

    print_info "Checking balance for address: $ADDRESS"

    _run_iota_commands "iota client balance \"$ADDRESS\""

    if [ $? -ne 0 ]; then
        print_error "Failed to retrieve balance for $NODE_NAME"
        exit 1
    fi
}

show_qr_code() {
    local WORDS="$@"

    if [ -z "$WORDS" ]; then
        print_error "No words provided for QR code generation"
        exit 1
    fi

    docker compose run --rm iota-tools \
        qrencode -o - -t ANSIUTF8 "$WORDS"

    if [ $? -ne 0 ]; then
        print_error "Failed to generate QR code"
        exit 1
    fi
}

pay_iota() {
    local FROM_ADDRESS="$1"
    local TO_ADDRESS="$2"
    local AMOUNT="$3"

    local IOTA
    local NANOS

    # If amount has a decimal point, assume it is in IOTA and convert to nanos
    if [[ "$AMOUNT" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        IOTA=$AMOUNT
        NANOS=$(printf "%.0f" $(echo "$AMOUNT * 1000000000" | bc))
    else
        IOTA=$(printf "%.2f" $(($AMOUNT / 1000000000)))
        NANOS=$AMOUNT
    fi

    if [ -z "$FROM_ADDRESS" ] || [ -z "$TO_ADDRESS" ] || [ -z "$AMOUNT" ]; then
        print_error "Usage: pay-iota <from_address> <to_address> <amount>"
        exit 1
    fi

    PAYMENT="$IOTA IOTA ($NANOS NANOS)"

    print_info "Attempting to pay $PAYMENT from $FROM_ADDRESS to $TO_ADDRESS..."

    if [ "$OPT_VERBOSE" -eq 1 ]; then
        # Run this only for illustration purposes
        _run_iota_commands \
            "iota client switch --address $FROM_ADDRESS" \
            "iota client gas"
    fi

    GAS_JSON=$(
        _run_iota_commands \
            "!iota client switch --address $FROM_ADDRESS > /dev/null" \
            "!iota client gas --json"
    )

    if [ $? -ne 0 ]; then
        print_error "Failed to get gas objects owned by $FROM_ADDRESS"
        exit 1
    fi

    # Get the gasCoinId of the item with the highest nanosBalance
    INPUT_COINS=$(echo "$GAS_JSON" | \
        jq -r 'sort_by(.nanosBalance) | reverse | .[0].gasCoinId')

    if [ -z "$INPUT_COINS" ]; then
        print_error "No gas coins found for $FROM_ADDRESS"
        exit 1
    fi

    _run_iota_commands \
        "!iota client switch --address $FROM_ADDRESS > /dev/null" \
        "iota client pay-iota --input-coins $INPUT_COINS --recipients $TO_ADDRESS --amounts $NANOS --gas-budget 100000000" \
            > $OUT

    if [ $? -ne 0 ]; then
        print_error "Failed to pay $PAYMENT from $FROM_ADDRESS to $TO_ADDRESS"
        exit 1
    fi

    print_success "Successfully paid $PAYMENT from $FROM_ADDRESS to $TO_ADDRESS"
}

COMMAND="$1"

# If no command is provided, show the usage
if [ -z "$COMMAND" ]; then
    print_usage
    exit 1
fi

shift

case "$COMMAND" in
    ("start")
        start
        COMMAND="nop"
        ;;
    ("stop")
        stop
        exit 0
        ;;
    ("reset")
        reset
        COMMAND="nop"
        ;;
    ("show-qr-code")
        SKIP_SERVICES=1
        ;;
esac

if [ -z "$SKIP_SERVICES" ]; then
    init_genesis

    start_services
fi

case "$COMMAND" in
    ("pay-iota")
        pay_iota "$@"
        ;;
    ("show-balance")
        show_balance "$@"
        ;;
    ("show-qr-code")
        show_qr_code "$@"
        ;;
    ("nop")
        # No operation, just exit successfully
        exit 0
        ;;
    (*)
        # Should not happen
        print_usage        
        ;;
esac
