#!/bin/bash
set -eu

MAIN_PROJECT="ArchiSteamFarm"
TESTS_PROJECT="${MAIN_PROJECT}.Tests"
SOLUTION="${MAIN_PROJECT}.sln"
CONFIGURATION="Release"
OUT="out/source"

CLEAN=0
SHARED_COMPILATION=1
TEST=1

cd "$(dirname "$(readlink -f "$0")")"

for ARG in "$@"; do
	case "$ARG" in
		release|Release) CONFIGURATION="Release" ;;
		debug|Debug) CONFIGURATION="Debug" ;;
		--clean) CLEAN=1 ;;
		--no-shared-compilation) SHARED_COMPILATION=0 ;;
		--no-test) TEST=0 ;;
		*) echo "Usage: $0 [--clean] [--no-shared-compilation] [--no-test] [debug/release]"; exit 1
	esac
done

trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM

if ! hash dotnet 2>/dev/null; then
	echo "ERROR: dotnet CLI tools are not installed!"
	exit 1
fi

dotnet --info

if [[ -d ".git" ]] && hash git 2>/dev/null; then
	git pull || true
fi

if [[ ! -f "$SOLUTION" ]]; then
	echo "ERROR: $SOLUTION could not be found!"
	exit 1
fi

SETUP_FLAGS=(-c "$CONFIGURATION" -o "$OUT")
BUILD_FLAGS=(--no-restore '/nologo' '/p:LinkDuringPublish=false')

if [[ "$SHARED_COMPILATION" -eq 0 ]]; then
	BUILD_FLAGS+=('/p:UseSharedCompilation=false')
fi

if [[ "$TEST" -eq 1 ]]; then
	if [[ "$CLEAN" -eq 1 ]]; then
		dotnet clean "${SETUP_FLAGS[@]}"
		rm -rf "${MAIN_PROJECT:?}/${OUT}" "${TESTS_PROJECT:?}/${OUT}"
	fi

	dotnet restore
	dotnet publish "${SETUP_FLAGS[@]}" "${BUILD_FLAGS[@]}"
	dotnet test "$TESTS_PROJECT" "${SETUP_FLAGS[@]}" --no-build "${BUILD_FLAGS[@]}"
else
	if [[ "$CLEAN" -eq 1 ]]; then
		dotnet clean "$MAIN_PROJECT" "${SETUP_FLAGS[@]}"
		rm -rf "${MAIN_PROJECT:?}/${OUT}"
	fi

	dotnet restore "$MAIN_PROJECT"
	dotnet publish "$MAIN_PROJECT" "${SETUP_FLAGS[@]}" "${BUILD_FLAGS[@]}"
fi

echo
echo "Compilation finished successfully! :)"
