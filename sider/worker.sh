#!/bin/bash

#
# Here the magic happens ;)
#

#set -o xtrace
BASENAME="worker.sh"

_timestamp() {
	date "+%Y.%m.%d-%H.%M.%S"
}

_template() {
	local log_type="$1"; shift
	local msg="$1"; shift
	printf ":: %-5s [%s] %s %s\n" "$log_type" "$(_timestamp)" "$BASENAME" "$msg" >&2
}

log() {
	local msg="$1"; shift
	_template "LOG" "$msg"
}

error() {
	local msg="$1"; shift
	_template "ERROR" "$msg"
	exit 1
}

# Let's run, fools!

BASE="/work"
S3_OUTPUT="s3://siderp"
THREADS=10
REFERENCE="$REFERENCE"
ANNOTATION="$ANNOTATION"
DATA_DIR="data"
INPUT_TYPE="path"
PREFIX="sider"
MANIFEST="MANIFEST"
OUTPUT_DIR="$(date +%Y-%m-%d-)$(hexdump -n 16 -v -e '/1 "%02X"' -e '/16 "\n"' /dev/urandom)"

while getopts ":t:i:o:r:a:p:" OPTION; do
	case "$OPTION" in
		i)
			INPUT_TYPE="$OPTARG"
			;;
		o)
			S3_OUTPUT="$OPTARG"
			;;
		t)
			THREADS="$OPTARG"
			;;
		r)
			REFERENCE="$OPTARG"
			;;
		a)
			ANNOTATION="$OPTARG"
			;;
		p)
			PREFIX="$OPTARG"
			;;
		?)
			error "No such option '-$OPTARG'"
			;;
	esac
done

shift $(($OPTIND - 1))
[[ $# == 0 ]] && error "No s3 sider list file passed"
S3_MANIFEST="$1"

save_results() {
	log "Save results at $BASE/$OUTPUT_DIR to $S3_OUTPUT/$OUTPUT_DIR"
	if ls -A "$BASE/$OUTPUT_DIR" > /dev/null 2>&1; then
		aws s3 cp "$BASE/$OUTPUT_DIR" "$S3_OUTPUT/$OUTPUT_DIR" --recursive \
			|| error "Failed to save $BASE/$OUTPUT_DIR to $S3_OUTPUT"
	fi
}

trap "save_results" EXIT

exit_on_signal() {
	local sig="$1"; shift
	log "Caught signal SIG$(kill -l $sig)"
	exit "$sig"
}

for sig in 1 2 3 6 9 15; do
	trap "exit_on_signal $sig" "$sig"
done

log "WELCOME TO SIDER PIPELINE ON AWS"

log "Create base directories"
mkdir -p "$BASE/$OUTPUT_DIR" \
	|| error "Failed to create base directories"

aws s3 cp --quiet "$S3_MANIFEST" "$BASE/$MANIFEST" \
	|| error "Failed to download '$S3_MANIFEST'"

case "$INPUT_TYPE" in
	bucket)
		log ">> Assets from s3 bucket <<"

		log "Create '$BASE/$DATA_DIR' directory"
		mkdir -p "$BASE/$DATA_DIR" \
			|| error "Failed to create directory for s3 data"

		log "Download BAM files at '$S3_MANIFEST'"
		while read path; do
			s3_path="$path"

			if [[ ! "$s3_path" =~ ^s3 ]]; then
				s3_path="s3:/$path"
			fi

			log "Download $s3_path ..."
			aws s3 cp --quiet "$s3_path" "$BASE/$DATA_DIR/" \
				|| error "Failed to download file '$s3_path'"
		done < "$BASE/$MANIFEST"

		log "Create sider list from files at '$BASE/$DATA_DIR'"
		ls "$BASE/$DATA_DIR"/* | grep '\.\(bam\|cram\|sam\)$' > "$BASE/sider_list.txt" \
			|| error "Failed to create sider_list.txt"
		;;
	path)
		log ">> Assets from mounted path <<"

		log "Create sider_list.txt"
		while read path; do
			echo "$path" >> "$BASE/sider_list.txt" \
				|| error "Failed to create sider_list.txt"
		done < "$BASE/$MANIFEST"
		;;
	*)
		error "Invalid '$INPUT_TYPE' [bucket|path]"
		;;
esac

log "Run 'process-sample' step ..."
sider ps \
	-c 2000000 \
	-o "$BASE/$OUTPUT_DIR" \
	-p "$PREFIX" \
	-t $THREADS \
	-m 15000 \
	-F 0.9 \
	-Q 20 \
	-l "$BASE/$OUTPUT_DIR/ps.log" \
	-a "$ANNOTATION" \
	-i "$BASE/sider_list.txt" \
	|| error "Failed to run 'process-sample' step"

log "Run 'merge-call' step ..."
sider mc \
	-c 20000000 \
	-e 500 \
	-m 20 \
	-g 5 \
	-n 3 \
	-l "$BASE/$OUTPUT_DIR/mc.log" \
	-t $THREADS \
	-B "$ANNOTATION" \
	-Q 20 \
	-I "$BASE/$OUTPUT_DIR/$PREFIX.db" \
	|| error "Failed to run 'merge-call' step"

log "Run 'make-vcf' step ..."
sider vcf \
	-r "$REFERENCE" \
	-l "$BASE/$OUTPUT_DIR/vcf.log" \
	-o "$BASE/$OUTPUT_DIR" \
	-p "$PREFIX" \
	"$BASE/$OUTPUT_DIR/$PREFIX.db" \
	|| error "Failed to run 'make-vcf' step"
