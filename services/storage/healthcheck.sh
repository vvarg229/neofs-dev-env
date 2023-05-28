#!/bin/sh
set -x

/neofs-cli --verbose control healthcheck -c /cli-cfg.yml \
	--endpoint "$NEOFS_CONTROL_GRPC_ENDPOINT" |
	grep "Health status: READY"
