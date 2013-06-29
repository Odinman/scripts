<?php
/*
  +----------------------------------------------------------------------+
  | Name:                                                                |
  +----------------------------------------------------------------------+
  | Comment:                                                             |
  +----------------------------------------------------------------------+
  | Author:Odin                                                          |
  +----------------------------------------------------------------------+
  | Created:2012-06-12 17:10:29                              |
  +----------------------------------------------------------------------+
  | Last-Modified:2013-05-31 10:52:41                        |
  +----------------------------------------------------------------------+
*/

$now=time();
$sevenDay=$now+86400*7;
for($i=$now;$i<=$sevenDay;$i+=86400) {
    if (date('w',$i)==0 || date('w',$i)==6) {
    //if (date('w',$i)==0 || date('w',$i)==6 || date('w',$i)==5) {
        $GLOBALS['cDate'][]=date('Ymd',$i);
    }
}
if (!isset($lastRun)) {
    $lastRun=0;
    $interval=20;   //20秒去看一眼
}
$loop=0;
try {
    $loginURL='http://114.242.121.99/login.aspx';
    $imgURL='http://114.242.121.99/tools/CreateCode.ashx?key=ImgCode&random=0.9396288357675076';
    $yuecheURL='http://114.242.121.99/ych2.aspx';
    $nowTime=date('Hi');
    $run=false;
    if ($nowTime>=$GLOBALS['runTime']['begin'] && $nowTime<=$GLOBALS['runTime']['end']) {
        $run=true;
    } else {
        _debug("[time_wrong:".date('Y-m-d H:i:s')."]",_DLV_ERROR);
    }
    while($run===true) {
        $ch = curl_init();
        //curl_setopt($ch, CURLOPT_CONNECTTIMEOUT_MS,3000);
        //curl_setopt($ch, CURLOPT_TIMEOUT_MS, 5000);

        $date=gmdate('D, d M Y H:i:s \G\M\T',time());
        $uas=array(
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/28.0.1496.0 Safari/537.36',
        );
        $ua=$uas[array_rand($uas)];
        //echo $signStr."\n";
        $headers=array(
            "Date: {$date}",
            "User-Agent: {$ua}",
            "Cookie: {$GLOBALS['loginOnCookie']}",
        );

        curl_setopt($ch, CURLOPT_URL, $yuecheURL);
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'GET');
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
        curl_setopt($ch, CURLOPT_HEADER, 1);
        $output = curl_exec($ch);
        $info = curl_getinfo($ch);
        //$infoStr=var_export($info,true);
        //$fp=@fopen("/tmp/yueche","w+");
        //fputs($fp,$output."\n");
        //fputs($fp,$infoStr);
        //fclose($fp);
        if ($info['http_code']==200) {
            $sendmail=false;
            $loop++;
            if (!empty($GLOBALS['cDate'])) {
                foreach($GLOBALS['cDate'] as $dStr) {
                    $yuecheinfo="yyrq='{$dStr}'\r\n.+yysd=\"15\">\r\n(.+)\r\n";
                    preg_match_all("/{$yuecheinfo}/",$output,$mats);
                    $left=trim($mats[1][0]);
                    $result[$dStr]=$left;
                    if ($left>0) {
                        $sendmail=true;
                        _debug("[$dStr][left:$left]",_DLV_ALERT);
                    } else {
                        _debug("[$dStr][left:$left]",_DLV_NOTICE);
                    }
                }
            }
            if ($sendmail===true) {
                //todo
                $subject="some day have car!!!";
                $message="";
                foreach($result as $d=>$l) {
                    $message.="$d:$l\n";
                }
                sendMail($message,$subject,$GLOBALS['addrs']);
                _debug("[sendmail:{$subject}]",_DLV_WARNING);
                $interval=600;  //间隔改为10分钟
            }
            pcntl_signal_dispatch();
            sleep($interval);
        } else {    //登录失败
            $GLOBALS['loginOnCookie']='';   //置空

            _loginSite($ua,$loginURL,$imgURL);

            _debug("[loginOnCookie: {$GLOBALS['loginOnCookie']}]",_DLV_WARNING);
        }
        curl_close($ch);
        $nowTime=date('Hi');
        if ($nowTime>=$GLOBALS['runTime']['begin'] && $nowTime<=$GLOBALS['runTime']['end']) {
            _debug("[time_right:".date('Y-m-d H:i:s')."]",_DLV_ERROR);
        } else {
            $run=false;
        }
        if ($loop>$GLOBALS['_yueche']['loop']) {
            $run=false;
        }
    }

    pcntl_signal_dispatch();

    sleep(1);
    //sleep($interval);
} catch (Exception $e) {
    _debug("[Caught Exception:".$e->getMessage()."]",_DLV_ERROR);
    sleep(5);
}
