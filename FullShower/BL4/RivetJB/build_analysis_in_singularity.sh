source ~/herwigSetup.sh

files=(
  preCompiled_FO_5_5
  preCompiled_RS_5_5
  preCompiled_FO_woPS_5_5
  preCompiled_RS_One_5_5
)

for dir in "${files[@]}"; do
  echo ">>> Building in $dir"
  cd "$dir"
  rivet-build Rivet.so RAnalysis.cc
  cd ..
done
