build:
    go build -o bin/novanet-validator src/main.go

run:
    ./bin/novanet-validator

stop:
    pkill -f novanet-validator

restart:
    make stop && make run
