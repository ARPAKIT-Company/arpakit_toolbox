cd ../..

git remote -v
git remote | xargs -r -n1 git remote remove
git remote -v