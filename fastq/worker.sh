#!/usr/bin/env bash

set -euo pipefail

region=${AWS_REGION}
queue=${SQS_QUEUE_URL}

# Fetch messages and render them until the queue is drained.
while [ /bin/true ]; do
	# Fetch the next message and extract the S3 URL to fetch the POV-Ray source ZIP from.
	echo "Fetching messages from SQS queue: ${queue}..."
	result=$( \
		aws sqs receive-message \
			--queue-url ${queue} \
			--region ${region} \
			--wait-time-seconds 20 \
			--query Messages[0].[Body,ReceiptHandle] \
		| sed -e 's/^"\(.*\)"$/\1/'\
	)

	if [ -z "${result}" ]; then
		echo "No messages left in queue. Exiting."
		exit 0
	fi

	echo "Message: ${result}."

	receipt_handle=$(echo ${result} | sed -e 's/^.*"\([^"]*\)"\s*\]$/\1/')
	echo "Receipt handle: ${receipt_handle}."

	bucket=$(echo ${result} | sed -e 's/^.*arn:aws:s3:::\([^\\]*\)\\".*$/\1/')
	echo "Bucket: ${bucket}."

	output_bucket=$(echo ${result} | sed -e 's/^.*\\"s3_output_bucket\\":\s*\\"\([^\\]*\)\\".*$/\1/')
	echo "Output Bucket: ${output_bucket}."

	threads=$(echo ${result} | sed -e 's/^.*\\"threads\\":\s*\\"\([^\\]*\)\\".*$/\1/')
	echo "Threads: ${threads}"

	key=$(echo ${result} | sed -e 's/^.*\\"key\\":\s*\\"\([^\\]*\)\\".*$/\1/')
	echo "Key: ${key}."

	base=${key%.*}
	ext=${key##*.}

	if [ \
		-n "${result}" -a \
		-n "${receipt_handle}" -a \
		-n "${key}" -a \
		-n "${base}" -a \
		-n "${ext}" -a \
		"${ext}" = "bam" \
	]; then
		mkdir -p work
		pushd work

		echo "Copying ${key} from S3 bucket ${bucket} ..."
		aws s3 cp s3://${bucket}/${key} . --region ${region}

		echo "Extract fastq from ${base}..."
		samtools collate -f -O -@ ${threads} ${key} \
			| samtools fastq - -c 6 -1 r1.fastq.gz -2 r2.fastq.gz

		echo "Archive r1.fastq and r2.fastq to ${base}.tar ..."
		tar cvf ${base}.tar r1.fastq.gz r2.fastq.gz

		echo "Copying result tarbal ${base}.tar to s3://${output_bucket} ..."
		aws s3 cp ${base}.tar s3://${output_bucket}/${base}.tar

		echo "Cleaning up..."
		popd
		rm -rf work

		echo "Deleting ${key} from s3://${bucket} ..."
		aws s3 rm s3://${bucket}/${key}

		echo "Deleting message..."
		aws sqs delete-message \
			--queue-url ${queue} \
			--region ${region} \
			--receipt-handle "${receipt_handle}"

	else
		echo "ERROR: Could not extract S3 bucket and key from SQS message."
	fi
done
