cd ../..

source .env

git remote remove primary
git remote add primary ${GIT_PRIMARY_REMOTE_URL}

git remote remove mirror_1
git remote add mirror_1 ${GIT_MIRROR_1_REMOTE_URL}

git remote -v