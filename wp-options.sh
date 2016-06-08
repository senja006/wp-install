#!/bin/bash -e
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

wp comment delete 1 --force
wp post delete 1 2 --force