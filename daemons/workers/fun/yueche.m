<?php
/*
  +----------------------------------------------------------------------+
  | Name:                                                                |
  +----------------------------------------------------------------------+
  | Comment:                                                             |
  +----------------------------------------------------------------------+
  | Author:Odin                                                          |
  +----------------------------------------------------------------------+
  | Created:2013-05-13 18:10:23                              |
  +----------------------------------------------------------------------+
  | Last-Modified:2013-05-16 09:56:03                        |
  +----------------------------------------------------------------------+
*/
function _loginSite($ua,$loginURL,$imgURL) {
    $date=gmdate('D, d M Y H:i:s \G\M\T',time());
    $headers=array(
        "Date: {$date}",
        "User-Agent: {$ua}",
    );

    //访问登录页面
    $och = curl_init();
    curl_setopt($och, CURLOPT_URL, $loginURL);
    curl_setopt($och, CURLOPT_CUSTOMREQUEST, 'GET');
    curl_setopt($och, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($och, CURLOPT_HTTPHEADER, $headers);
    curl_setopt($och, CURLOPT_COOKIEJAR, "/tmp/logincookiefile"); 
    $loginHtml = curl_exec($och);
    curl_close($och);
    if ($logincookies=_curl_parse_cookiefile("/tmp/logincookiefile")) {
        foreach($logincookies as $k=>$v) {
            _debug("[".__FUNCTION__."]logincookie][$k: $v]",_DLV_WARNING);
        }
    }
    $view=_findProperty($loginHtml,'__VIEWSTATE');
    $env=_findProperty($loginHtml,'__EVENTVALIDATION');
    _debug("[".__FUNCTION__."]__EVENTVALIDATION:{$env}][__VIEWSTATE:{$view}]",_DLV_WARNING);

    $date=gmdate('D, d M Y H:i:s \G\M\T',time());
    $headers=array(
        "Date: {$date}",
        "User-Agent: {$ua}",
    );
    if (!empty($logincookies['ASP.NET_SessionId'])) {
        $headers[]="Cookie: ASP.NET_SessionId={$logincookies['ASP.NET_SessionId']};";
    }
    //获取验证码
    $loginStatus=false;
    while($loginStatus===false) {
        $lch = curl_init();
        $gifFp=@fopen('/tmp/login.gif',"w+");
        curl_setopt($lch, CURLOPT_URL, $imgURL);
        curl_setopt($lch, CURLOPT_CUSTOMREQUEST, 'GET');
        curl_setopt($lch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($lch, CURLOPT_HTTPHEADER, $headers);
        curl_setopt($lch, CURLOPT_COOKIEJAR, "/tmp/cookiefile"); 
        //curl_setopt($lch, CURLOPT_HEADER, 1);
        curl_setopt($lch, CURLOPT_FILE, $gifFp);
        //$loginHeader = curl_exec($lch);
        curl_exec($lch);
        $info = curl_getinfo($lch);
        curl_close($lch);
        fclose($gifFp);
        //$infoStr=var_export($info,true);
        //$fp=@fopen("/tmp/login","w+");
        //fputs($fp,$output."\n");
        //fputs($fp,$infoStr);
        //fclose($fp);
        //sendmail warning
        //if ($cookies=_findCookie($loginHeader)) {
        if ($cookies=_curl_parse_cookiefile("/tmp/cookiefile")) {
            foreach($cookies as $k=>$v) {
                _debug("[".__FUNCTION__."]cookie][$k: $v]",_DLV_WARNING);
            }
        }
        //read gif
        $cmd="{$GLOBALS['_OCR']} -m 4 /tmp/login.gif 2>>/dev/null";
        $verStr=@exec($cmd);
        if (preg_match("/^[0-9a-zA-Z]{4}$/",$verStr)) {
            _debug("[".__FUNCTION__."]verify:{$verStr}][maybe_right]",_DLV_WARNING);
            // login!!
            $date=gmdate('D, d M Y H:i:s \G\M\T',time());
            $headers=array(
                "Date: {$date}",
                "User-Agent: {$ua}",
                "Cookie: ASP.NET_SessionId={$logincookies['ASP.NET_SessionId']}; ImgCode={$cookies['ImgCode']};",
            );
            $data=array(
                '__VIEWSTATE' => $view,
                '__EVENTVALIDATION' => $env,
                'txtUserName' => '620103197910152620',
                'txtPassword' => '1015',
                'txtIMGCode' => $verStr,
                'BtnLogin' => urldecode('%E7%99%BB++%E5%BD%95'),
                'rcode' => '',
            );
            $och = curl_init();
            curl_setopt($och, CURLOPT_URL, $loginURL);
            curl_setopt($och, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($och, CURLOPT_POST, 1); 
            curl_setopt($och, CURLOPT_POSTFIELDS, $data); 
            curl_setopt($och, CURLOPT_HTTPHEADER, $headers);
            curl_setopt($och, CURLOPT_COOKIEJAR, "/tmp/passcookiefile"); 
            curl_exec($och);
            $info = curl_getinfo($och);
            curl_close($och);
            if ($info['http_code']==302) {
                _debug("[".__FUNCTION__."]login_success!!]",_DLV_WARNING);
                $loginStatus=true;
                if ($LoginOnCookies=_curl_parse_cookiefile("/tmp/passcookiefile")) {
                    foreach($LoginOnCookies as $k=>$v) {
                        _debug("[".__FUNCTION__."]LoginOnCookies][$k: $v]",_DLV_WARNING);
                    }
                }
                $GLOBALS['loginOnCookie']="ASP.NET_SessionId={$logincookies['ASP.NET_SessionId']}; ImgCode={$cookies['ImgCode']}; LoginOn={$LoginOnCookies['LoginOn']};";
            } else {
                _debug("[".__FUNCTION__."]login_failed]",_DLV_WARNING);
            }
        } else {
            _debug("[".__FUNCTION__."]verify:{$verStr}][wrong]",_DLV_WARNING);
        }
        sleep(1);
        //time
        $nowTime=date('Hi');
        if ($nowTime>=$GLOBALS['runTime']['begin'] && $nowTime<=$GLOBALS['runTime']['end']) {
            _debug("[".__FUNCTION__."][time_right:".date('Y-m-d H:i:s')."]",_DLV_INFO);
        } else {
            _debug("[".__FUNCTION__."][time_wrong:".date('Y-m-d H:i:s')."]",_DLV_INFO);
            break;
        }
    }
}

/* {{{ _findCookie
 */
function _findCookie($response) {
    $ret=array();

    do {
        if (empty($response)) {
            break;
        }
        $cookieinfo="^Set-Cookie:\s*([^;]*)";
        preg_match_all("/{$cookieinfo}/mi",$response,$mats);
        if (!empty($mats[1])) {
            foreach($mats[1] as $cookieStr) {
                $off=strpos($cookieStr,'=');
                $cKey=substr($cookieStr,0,$off);
                $cValue=substr($cookieStr,$off+1);
                //echo "$cKey:$cValue\n";
                $ret[$cKey]=$cValue;
            }
        }
    } while(false);

    return $ret;
}
/* }}} */

function _curl_parse_cookiefile($file) { 
    $aCookies = array(); 
    $aLines = file($file); 
    foreach($aLines as $line){ 
        //if('#'==$line{0}) continue; 
        $arr = explode("\t", $line); 
        if(isset($arr[5]) && isset($arr[6])) 
            $aCookies[trim($arr[5])] = trim($arr[6]);
    } 

    return $aCookies; 
}

function _findProperty($response,$name) {
    $ret='';

    do {
        if (empty($response)) {
            break;
        }
        $info="id=\"{$name}\".+value=\"(.+)\"";
        //echo $info."\n";
        preg_match("/{$info}/mi",$response,$mats);
        if (!empty($mats[1])) {
            $ret=$mats[1];
        }
    } while(false);

    return $ret;
}
