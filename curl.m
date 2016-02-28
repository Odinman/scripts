<?php
/*
  +----------------------------------------------------------------------+
  | Name:                                                                |
  +----------------------------------------------------------------------+
  | Comment:                                                             |
  +----------------------------------------------------------------------+
  | Author:Odin                                                          |
  +----------------------------------------------------------------------+
  | Created:TIMESTAMP                              |
  +----------------------------------------------------------------------+
  | Last-Modified:TIMESTAMP                        |
  +----------------------------------------------------------------------+
*/
$ch = curl_init();

$headers=array(
    "targetcomp_id: 40000010",
    "sendercomp_id: 91000",
);

$data='bank_id=03080000&occur_balance=300&partner_id=40000010&partner_serial_no=WjUTC85HR4qd5o84XYNviS&partner_trans_date=20151013&partner_trans_time=214658&pickup_url=http%3A%2F%2Fbeta.qinhudai.com%2Fucp%2Fbilling%2Fresult&receive_url=http%3A%2F%2Fbeta.qinhudai.com%2Fbank%2Fgateway&cert_sign=MDdmNjJjYzA4NTEzMDVjZTAwODdmMmQxOWRjZjE2YmRiNmVmYjE1ODNmYjEwZGRlNWFmY2NkODcxMTUxYTcwYzFmYWJhOTRkOThlMTNkMGJjMGQ3YmY2MjgxZTJiM2Q3MmZiYTMxYTQzODA5NGRjNjBmZjVlNjFkZjUzN2M4MGQyOGMxOTFhNGJmNzNhYzg3ZDRhY2U3Mzk5ODlkNjMzYzdlOWU4N2M4NTE2YTllMDA5NDUzNGJiODFmZDUxN2JkZjY2NjU0YjAzNWExZWM3NTEzYWYxNjBjZWEzYzM2NzNlNDA4ODhkNjJiMjBkYjI2NzlmMGMxNmVmOGM5NTBlYQ==';

curl_setopt($ch, CURLOPT_URL, "http://121.43.73.48:5080/eis/yunpay/epay_gateway_pay");
curl_setopt($ch, CURLOPT_POST, 1);
curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
//curl_setopt($ch, CURLOPT_HEADER, 1);
$output = curl_exec($ch);
$info = curl_getinfo($ch);
print_r($info);
$fp=@fopen("/tmp/yueche","w+");
fputs($fp,$output."\n");
fclose($fp);
$data=preg_replace('/\t/', '\t', trim($output));
$rt=json_decode($data,true);
print_r($rt);
