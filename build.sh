set -e

APP_NAME=noise

mkdir -p bin
ca65 -g main.asm -o bin/main.o
ld65 -Ln bin/${APP_NAME}.lbl -m bin/${APP_NAME}.map -C lorom128.cfg -o bin/${APP_NAME}.smc bin/main.o
./create_debug_labels.sh bin/${APP_NAME}.lbl > bin/${APP_NAME}.cpu.sym