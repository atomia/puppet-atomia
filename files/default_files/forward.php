<?php
header("Content-Type: text/html; charset=UTF-8");

$data = array();

if (isset($_GET) && !empty($_GET)) {
    $data['title'] = isset($_GET['title']) ? $_GET['title'] : "" ;
    $data['kwords'] = isset($_GET['kwords']) ? $_GET['kwords'] : "" ;
    $data['desc'] = isset($_GET['desc']) ? $_GET['desc'] : "" ;
    $data['url'] = isset($_GET['url']) && filter_var($_GET['url'], FILTER_VALIDATE_URL) ? $_GET['url'] : "" ;
}

?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">

    <head>
        <meta http-equiv="X-UA-COMPATIBLE" content="IE=8" />
        <title><?php echo htmlentities(urldecode($data["title"]), ENT_QUOTES, "UTF-8") ?></title>
        <meta name="description" content="<?php echo htmlentities(urldecode($data["desc"]), ENT_QUOTES, "UTF-8") ?>" />
        <meta name="keywords" content="<?php echo htmlentities(urldecode($data["kwords"]), ENT_QUOTES, "UTF-8") ?>" />
        <meta http-equiv="content-type" content="text/html;charset=utf-8" />
        <link rel="stylesheet" href="css/screen.css" type="text/css" media="screen, projection" />
        <link rel="stylesheet" href="css/print.css" type="text/css" media="print" />
        <link rel="stylesheet" href="css/style.css" type="text/css" media="screen, projection" />
        <style type="text/css">
            html, body, iframe { margin:0; padding:0; height:100%; }
            iframe { display:block; width:100%; border:none; }
        </style>

        <!--[if IE 7]>
                <link rel="stylesheet" href="css/ie.css" type="text/css" media="screen, projection" />
        <![endif]-->
    </head>

    <body>
        <iframe name="ForwardFrameqAW52htK" src="<?php echo htmlentities($data['url'], ENT_QUOTES, "UTF-8");; ?>"></iframe>
    </body>
</html>