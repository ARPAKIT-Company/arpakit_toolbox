cd ../..

source .env

git remote remove origin
git remote add origin ${GIT_ORIGIN_URL}

git remote remove mirror_1
git remote add mirror_1 ${GIT_MIRROR_1_URL}

git remote -v