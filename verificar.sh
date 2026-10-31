#!/usr/bin/env bash
# Comprueba si el login del laboratorio responde (200). No necesita sudo ni modifica
# nada. Termina con 0 solo si la web responde 200.
# Con "sh verificar.sh" se usaría dash, que no entiende la sintaxis de bash.
if [ -z "${BASH_VERSION:-}" ]; then
    exec /bin/bash "$0" "$@"
fi
set -euo pipefail

ORIGEN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ORIGEN
# shellcheck source=comun.sh
source "$ORIGEN/comun.sh"

if ! command -v curl >/dev/null 2>&1; then
    echo "ERROR: curl no está instalado." >&2
    exit 1
fi

codigo=$(codigo_http)
case $codigo in
200)
    printf '\033[1;32m[OK]\033[0m %s/login responde 200: el laboratorio funciona.\n' "$URL"
    exit 0
    ;;
000)
    printf '\033[1;31m[ERROR]\033[0m %s/login no responde: nginx o la aplicación no están en marcha.\n' "$URL" >&2
    ;;
5??)
    printf '\033[1;31m[ERROR]\033[0m %s/login responde %s: la aplicación no está respondiendo bien.\n' "$URL" "$codigo" >&2
    ;;
*)
    printf '\033[1;33m[AVISO]\033[0m %s/login responde %s.\n' "$URL" "$codigo" >&2
    ;;
esac
exit 1
