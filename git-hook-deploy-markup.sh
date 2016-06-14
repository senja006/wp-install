#!/bin/bash -e

#для верстки. после коммита для заливки на удаленный реп и обновления верстки
cat > .git/hooks/post-commit <<EOL
#!/bin/bash -e

git push origin $branch
#msg=`git log --oneline -1`
#cd server
#files=`ls | grep -v wp-remote-dev-pull.sh`
#rm -r $files
cd ..
cp -a `pwd`/dev/* `pwd`/server/
cd server
git add .
git commit -m "$msg"
git push origin $branch
sh wp-remote-dev-pull.sh
cd ..

EOL

chmod +x .git/hooks/post-commit
open -a "Sublime text" .git/hooks/post-commit
open -a "Sublime text" git-hook-deploy-markup.sh