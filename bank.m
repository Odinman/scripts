<?php
/*
  +----------------------------------------------------------------------+
  | Name:                                                                |
  +----------------------------------------------------------------------+
  | Comment:                                                             |
  +----------------------------------------------------------------------+
  | Author:Odin                                                          |
  +----------------------------------------------------------------------+
  | Created:2013-06-02 23:52:58                              |
  +----------------------------------------------------------------------+
  | Last-Modified:2013-06-02 23:58:48                        |
  +----------------------------------------------------------------------+
*/
$link = mysqli_init();
$link->options(MYSQLI_OPT_CONNECT_TIMEOUT, 10);
@$link->real_connect('127.0.0.1','root','','test');
if ($link->connect_errno) {
    //连接失败
    echo "error\n";
} else {
    echo "connected\n";
}
$json=file_get_contents('/Users/Odin/Downloads/QQ/Express.txt');
$ed=json_decode($json,true);
//print_r($ed['data'][0]['banks']);
$qks=$ed['data'][0]['banks'];
foreach($qks as $bd) {
    if ($bd['pay_bankacct_type']==0) {
    $quick_bank[$bd['bank_id']]['name']=$bd['bank_name'];
    }
}
//print_r($quick_bank);
$sql="select `bank_id`,`cardbin`,`card_length`,`extfld2` from cardbins";
$result=$link->query($sql);
while($row=$result->fetch_assoc()) {
    $cardbin=$row['cardbin'];
    $bank_id=$row['bank_id'];
    $card_length=(int)$row['card_length'];
    $bank_name=$row['extfld2'];
    if (isset($quick_bank[$bank_id])) {
        $quick=1;
    } else {
        $quick=0;
    }
    $bank_card=array(
        'bank_name' => $bank_name,
        'bank_code' => $bank_id,
        'cardbin' => $cardbin,
        'card_length' => $card_length,
        'quick' => $quick,
    );
    //printf("%s,%s,%s,%s,%s\n",$cardbin,$bank_id,$card_length,$bank_name,$quick);
    printf("%s\n",json_encode($bank_card));
}
