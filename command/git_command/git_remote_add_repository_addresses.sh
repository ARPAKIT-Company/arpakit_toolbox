cd ../..

source .env

git remote remove origin

git remote remove git_main_repository_address
git remote add git_main_repository_address ${GIT_MAIN_REPOSITORY_ADDRESS}

git remote remove git_another_repository_address_1
git remote add git_another_repository_address_1 ${GIT_ANOTHER_REPOSITORY_ADDRESS_1}

git remote -v