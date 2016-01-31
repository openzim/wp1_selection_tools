mysql --defaults-file=~/replica.my.cnf --quick -e "SELECT page_title,
IF ( rd_from = page_id,
rd_title,
/*ELSE*/IF (pl_from = page_id,
pl_title,
/*ELSE*/
NULL -- Can't happen, due to WHERE clause below
))
FROM page, redirect, pagelinks
WHERE (rd_from = page_id OR pl_from = page_id)
AND page_is_redirect = 1
AND page_namespace = 0; /* main */
--ORDER BY page_id ASC;" -N -h enwiki.labsdb enwiki_p |
	 tr '\t' ' ' | # MySQL outputs tab-separated; file needs to be space-separated.
	 gzip > redirects_targets.gz

