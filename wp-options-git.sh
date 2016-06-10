#!/bin/bash -e

#настройка репозитория
echo "URL удаленного репозитория?: "
read -e gitremote

echo "Скачивание .gitignore..."
curl -L -o '.gitignore' https://raw.githubusercontent.com/github/gitignore/master/WordPress.gitignore
cat >> .gitignore <<EOL
.DS_Store
._.DS_Store
.idea
EOL

echo "Инициализация репозитория..."
git init

#бекап базы данных при каждом коммите
echo "Установка локального git хука pre-commit..."
cat > .git/hooks/pre-commit <<EOL
#!/bin/bash -e
wp db export wp-db.sql
git add wp-db.sql
EOL
chmod +x .git/hooks/pre-commit

#добавление ssh доступа на хостинг
echo "Введите строку подключения ssh к хостингу"
read -e sshoptions
	sshoptions=${sshoptions:-senja006@sra.webhost1.ru -p '9999'}
#ssh-keygen -t rsa
echo "Добавить ключи на хостинг для ssh доступа? (y/n): "
read -e addkey
if [ "$addkey" == y ] ; then
	ssh-copy-id -i /Users/senja006/.ssh/id_rsa.pub senja006@sra.webhost1.ru -p '9999'
fi

#заливка проекта
echo "Push в удаленный репозиторий..."
echo $themename >> README.md
git add .
git commit -m "Старт проекта"
git remote add origin $gitremote
git push -u origin master