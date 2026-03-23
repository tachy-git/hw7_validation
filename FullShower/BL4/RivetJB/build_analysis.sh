source preCompile.sh
source ~/.bashrc

singularity exec \
  --env LC_ALL=C \
  --bind "$(pwd):$(pwd)" \
  --bind /cms/ldap_home/taehee/HerwigWD/:/cms/ldap_home/taehee/HerwigWD/ \
  --bind /cms_scratch/taehee/:/cms_scratch/taehee/ \
  ~/osgvo-ubuntu-20.04_latest.sif \
  bash build_analysis_in_singularity.sh
