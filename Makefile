export TF_AUTO_APPROVE="1"
.PHONY: doc docs README.adoc plan apply

doc docs README.adoc: .envrc
	@source .envrc && terraform-docs -c .terraform-docs.yml .

init plan apply: .envrc
	@source .envrc && terraform $(@F)

.envrc:
	@cp -v .envrc.example .envrc
