#!/bin/bash -e
echo "Установка настроек..."
wp option update blogdescription ''
wp option update category_base '/category'
wp option update tag_base '/tag'
wp option update default_comment_status 'closed'
wp option update use_trackback ''
wp option update default_ping_status 'closed'
wp option update default_pingback_flag ''
wp option update permalink_structure '/%postname%/'
wp option update uploads_use_yearmonth_folders ''
wp option update use_smilies ''
wp option update blog_public '0'
wp option update rss_use_excerpt '1'

wp rewrite flush

echo "Удаление постов и комментариев..."
wp comment delete 1 --force
wp post delete 1 2 --force

echo "Удаление плагинов..."
wp plugin delete hello
wp plugin delete akismet

#установка стартовой темы
echo "Установка стартовой темы"

echo "Название темы"
read -e themename
echo "Название для папки темы"
read -e foldername
wp theme install https://github.com/senja006/start_theme_wordpress/archive/master.zip
mv wp-content/themes/start_theme_wordpress-master wp-content/themes/$foldername
cat > wp-content/themes/$foldername/style.css <<EOL
/*
Theme Name: $themename
Author: Sergey Yarkevich
Author URI: http://yarkevich.ru/
*/
EOL
wp theme activate $foldername

#установка дефолтной темы
echo "Установка дефолтной темы..."
cat >> wp-config.php <<EOL
define('WP_DEFAULT_THEME', $foldername);
EOL

#установка необходимых плагинов
echo "Установка необходимых плагинов..."
wp plugin install cyr3lat --activate
wp plugin install jetpack-widget-visibility --activate

#удаление файла
echo "Удалить файл настройки? (y/n): "
read -e isdelete
if [ "$isdelete" == y ] ; then
	rm wp-options.sh
fi


