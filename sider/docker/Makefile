SHELL := bash
TAG := siderp:dev
ECR := 814951050926.dkr.ecr.us-east-1.amazonaws.com
FTP_FASTA := ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/GRCh38_reference_genome/GRCh38_full_analysis_set_plus_decoy_hla.fa
FASTA_FILE := /home/users/tmiller/projects_current/sider-pipeline/sider/docker/GRCh38_full_analysis_set_plus_decoy_hla.fa
GTF_FILE := /home/projects2/databases/gencode/release32/gencode.v32.annotation.gtf.gz
CACHE_DIR := /home/users/tmiller/projects_current/sider-pipeline/sider/docker/cache

.PHONY: all
all: login push logout

.PHONY: push
push: login build tag
	docker push $(ECR)/$(TAG)

.PHONY: tag
tag: build
	docker tag $(TAG) $(ECR)/$(TAG)

.PHONY: login
login:
	eval $$(aws ecr get-login | sed 's/-e none//')

.PHONY: logout
logout:
	docker logout $(ECR)

.PHONY: build
build: assets.tar fetch_and_run.sh Dockerfile
	docker build \
		--build-arg ASSETS=$< \
		--build-arg FASTA_FILE=/assets/$(notdir $(FASTA_FILE)).gz \
		--build-arg GTF_FILE=/assets/$(notdir $(GTF_FILE)) \
		--build-arg REF_PATH=/assets/$(notdir $(CACHE_DIR))/%2s/%2s/%s:http://www.ebi.ac.uk/ena/cram \
		--build-arg REF_CACHE=/assets/$(notdir $(CACHE_DIR))/%2s/%2s/%s \
		-t $(TAG) .

assets.tar: $(GTF_FILE) $(FASTA_FILE).gz | CACHE.stamp
	for file in $(^) $(CACHE_DIR); do \
		tar rf $@ -C $$(dirname $$file) $$(basename $$file); \
	done

CACHE.stamp: $(FASTA_FILE) | $(CACHE_DIR)
	perl seq_cache_populate.pl -root $(CACHE_DIR) $< && touch $@

$(CACHE_DIR):
	mkdir -p $@

$(FASTA_FILE).gz: $(FASTA_FILE)
	gzip -c --best $< > $@

$(FASTA_FILE):
	wget $(FTP_FASTA) -O $@

.PHONY: clean
clean:
	rm -f assets.tar
	rm -f $(FASTA_FILE)
	rm -f $(FASTA_FILE).gz
	rm -f -r $(CACHE_DIR)
