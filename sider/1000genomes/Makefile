SHELL := bash

1000G_BUCKET := s3://1000genomes
1000G_BUCKET_DIR := 1000G_2504_high_coverage
POP_INDEX := 1000G_2504_high_coverage.sequence.index
BASE_DIR := 1000genomes
POP_LIST := POP
BLACKLIST := BLACKLIST
SIDER_BUCKET := s3://siderp
THREADS := 18
ECS_CLUSTER := sider
TASK_DEFINITION := sider

POP := $(addsuffix .pop, $(shell comm -23 <(sort $(POP_LIST)) <(sort $(BLACKLIST))))
TASK := $(addsuffix .json, $(POP))
RUN := $(addsuffix .run, $(TASK))

all: upload-sider-list $(RUN)

$(RUN): %.pop.json.run: %.pop.json
	aws ecs run-task \
		--cluster $(ECS_CLUSTER) \
		--task-definition $(TASK_DEFINITION) \
		--placement-strategy type='spread',field='host' \
		--overrides $$(cat $<) > $@

$(TASK): %.pop.json: %.pop
	printf "%s:%s,%s\n" \
		'{"containerOverrides":[{"name":"siderp","command"' \
		'["task_run.sh","-t","$(THREADS)","-p","$*","-i","bucket"' \
		'"$(SIDER_BUCKET)/$<"]}]}' > $@

.PHONY: upload-sider-list
upload-sider-list: $(POP)
	for pop in $(^); do \
		aws s3 cp --quiet $$pop $(SIDER_BUCKET)/; \
	done

$(POP): %.pop: $(POP_INDEX)
	awk -F '\t' \
		'$$11 == "$*" { \
			n = split($$1, h, "/"); \
			print "/$(BASE_DIR)/$(1000G_BUCKET_DIR)/data/"h[n-1]"/"h[n]; \
			print "/$(BASE_DIR)/$(1000G_BUCKET_DIR)/data/"h[n-1]"/"h[n]".crai"; \
		}' $< > $@

$(POP_INDEX):
	aws s3 cp --quiet $(1000G_BUCKET)/$(1000G_BUCKET_DIR)/$@ $@

.PHONY: clean
clean:
	rm -f *.pop
	rm -f *.json
	rm -f *.run
