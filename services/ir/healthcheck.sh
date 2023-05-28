#!/bin/sh
set -x

/neofs-cli --verbose control healthcheck \
	--endpoint "$NEOFS_IR_CONTROL_GRPC_ENDPOINT" \
	--wallet /wallet01.key --ir
