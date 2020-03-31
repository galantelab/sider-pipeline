S3_INPUT_URL := s3://1000genomes/1000G_2504_high_coverage/data
S3_INPUT_BUCKET := 1000genomes
S3_OUTPUT_BUCKET := siderp
EC2_NUM_INSTANCES := 10

task_list := $(addprefix task_list, $(shell seq 0 $$(($(EC2_NUM_INSTANCES) - 1))))

.PHONE: upload-worder
upload-worder: worker.sh create-bucket
	aws s3 cp $< s3://$(S3_OUTPUT_BUCKET)/$<

.PHONE: create-bucket
create-bucket:
	aws s3api create-bucket --bucket $(S3_OUTPUT_BUCKET)

.DEFAULT_GOAL := split-cram-list

.PHONE: split-cram-list
split-cram-list: $(task_list)

task_list%: cram_list.txt
	split --number=l/$(EC2_NUM_INSTANCES) --suffix-length=1 -d $< task_list

cram_list.txt:
	aws s3 ls $(S3_INPUT_URL)/ --recursive | \
		awk '/\.cram$$/ {print "$(S3_INPUT_BUCKET)/"$$NF}' > $@

.PHONE: clean
clean:
	rm -f task_list*
	rm -f cram_list.txt
