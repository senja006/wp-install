wp core download --locale=ru_RU --allow-root
cat >> wp-config-sample.php <<EOL
// disable revisions
define( 'WP_POST_REVISIONS', 3 );
 
// autosave interval
define( 'AUTOSAVE_INTERVAL', 240 ); // the value should be in seconds
 
// disable editing theme/plugin files from wp-admin
define( 'DISALLOW_FILE_EDIT', true );
 
// enabling "trash" for media items
define( 'MEDIA_TRASH', true );
 
// moving wp-content
// define( 'WP_CONTENT_DIR', dirname( __FILE__ ) . '/stuff' );
// define( 'WP_CONTENT_URL', 'http://exam.pl/stuff' );
 
// moving uploads
// define( 'UPLOADS', 'files' );
 
// change "emtpy trash" settings
define( 'EMPTY_TRASH_DAYS', 10 ); // 10 days

// при обновлении Wordpress пропустить обновление тем или появление после удаления
define( 'CORE_UPGRADE_SKIP_NEW_BUNDLED', true );

// ключ Wordpress
// define( 'WPCOM_API_KEY', 'YourKeyHere' );

// установка темы по умолчанию
// define( 'WP_DEFAULT_THEME', 'default-theme-folder-name' );

// запрет автоматического обновления
define( 'AUTOMATIC_UPDATER_DISABLED', true );

define('WP_MEMORY_LIMIT', '512M');
define('WP_MAX_MEMORY_LIMIT', '512M');
EOL
cat >> .htaccess <<EOL

#protect wpconfig.php
<files wp-config.php>
    order allow,deny
    deny from all
</files>
EOL

#после установки wp
wp option update blogdescription '' --allow-root
wp option update category_base '/category' --allow-root
wp option update tag_base '/tag' --allow-root
wp option update default_comment_status 'closed' --allow-root
wp option update use_trackback '' --allow-root
wp option update default_ping_status 'closed' --allow-root
wp option update default_pingback_flag '' --allow-root
wp option update permalink_structure '/%postname%/' --allow-root
wp option update use_smilies '' --allow-root
wp option update blog_public '0' --allow-root
wp option update rss_use_excerpt '1' --allow-root
wp rewrite flush --allow-root
wp comment delete 1 --force --allow-root
wp post delete 1 2 --force --allow-root
wp plugin delete hello --allow-root
wp plugin delete akismet --allow-root
wp theme install https://github.com/senja006/start_theme_wordpress/archive/master.zip --allow-root
mv wp-content/themes/start_theme_wordpress-master wp-content/themes/main --allow-root
cat > wp-content/themes/main/style.css <<EOL
/*
Theme Name: Main
Author: Sergey Yarkevich
Author URI: http://yarkevich.ru/
*/
EOL
wp theme activate main --allow-root
wp plugin install cyr3lat --activate --allow-root