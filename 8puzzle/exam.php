<?php
/*
  +----------------------------------------------------------------------+
  | Name: exam.php                                                       |
  +----------------------------------------------------------------------+
  | Comment: 8 puzzle 考试作业                                           |
  +----------------------------------------------------------------------+
  | Author: Xiaodao                                                      |
  +----------------------------------------------------------------------+
  | Created: 2016-03-02 15:13:17                                         |
  +----------------------------------------------------------------------+
  | Last-Modified: 2016-03-02 15:13:31                                   |
  +----------------------------------------------------------------------+
*/
// 思路1: 暴力穷举, 先实现, 再优化(而且3x3没什么好优化的)
error_reporting(1);

/* {{{ function getChecksum($matrix)
 * 获取一个matrix的checksum, 变成字符串后再md5
 */
function getChecksum($matrix) {
    $rt=false;

    try {
        $rt=crc32(json_encode($matrix));
    } catch (Exception $e) {
        //printf("Exception: %s", $e->getMessage());
    }

    return $rt;
}

/* }}} */

/* {{{ function isGoal($matrix)
 *
 */
function isGoal($matrix) {
    $rt=false;

    $goal=[
        [ 1, 2, 3 ],
        [ 4, 5, 6 ],
        [ 7, 8, 0 ]
    ];

    try {
        if ($matrix==$goal) {
            $rt=true;
        }
    } catch (Exception $e) {
        //printf("Exception: %s", $e->getMessage());
    }

    return $rt;
}

/* }}} */

/* {{{ function move($puzzle,$moves)
 * 移动格子, 返回所有新的移动后的状态
 */
function move($puzzle,$moves) {
    $rt=false;

    try {
        $matrix=$puzzle['matrix'];
        $path=$puzzle['path'];
        if (count($path)>$moves) { //最小步数之前没达到
            throw new Exception("nice try!\n");
        }
        foreach($matrix as $i => $js) {    //第一维
            foreach($js as $j => $v) { // 第二维
                if ($v==0) {
                    if (0<=($ni=$i-1) && 0<=($nj=$j)) {   //上, 动作是down
                        $tmp=$matrix;
                        $tmp[$i][$j]=$matrix[$ni][$nj];
                        $tmp[$ni][$nj]=0;
                        $cs=getChecksum($tmp);
                        if (!isset($GLOBALS['moved'][$cs])) {   //没有来过
                            $GLOBALS['moved'][$cs]=true;
                            $tp['matrix']=$tmp;
                            $tp['path']=$path;
                            $tp['path'][]=sprintf("%s down", $tmp[$i][$j]);
                            $rt[]=$tp;
                            unset($tp);
                        }
                    }
                    if (count($matrix)>($ni=$i+1) && 0<=($nj=$j)) {   //下,动作是up
                        $tmp=$matrix;
                        $tmp[$i][$j]=$matrix[$ni][$nj];
                        $tmp[$ni][$nj]=0;
                        $cs=getChecksum($tmp);
                        if (!isset($GLOBALS['moved'][$cs])) {   //没有来过
                            $GLOBALS['moved'][$cs]=true;
                            $tp['matrix']=$tmp;
                            $tp['path']=$path;
                            $tp['path'][]=sprintf("%s up", $tmp[$i][$j]);
                            $rt[]=$tp;
                            unset($tp);
                        }
                    }
                    if (0<=($ni=$i) && 0<=($nj=$j-1)) {   //左, 动作是right
                        $tmp=$matrix;
                        $tmp[$i][$j]=$matrix[$ni][$nj];
                        $tmp[$ni][$nj]=0;
                        $cs=getChecksum($tmp);
                        if (!isset($GLOBALS['moved'][$cs])) {   //没有来过
                            $GLOBALS['moved'][$cs]=true;
                            $tp['matrix']=$tmp;
                            $tp['path']=$path;
                            $tp['path'][]=sprintf("%s right", $tmp[$i][$j]);
                            $rt[]=$tp;
                            unset($tp);
                        }
                    }
                    if (0<=($ni=$i) && count($js)>($nj=$j+1)) {   //右, 动作是left
                        $tmp=$matrix;
                        $tmp[$i][$j]=$matrix[$ni][$nj];
                        $tmp[$ni][$nj]=0;
                        $cs=getChecksum($tmp);
                        if (!isset($GLOBALS['moved'][$cs])) {   //没有来过
                            $GLOBALS['moved'][$cs]=true;
                            $tp['matrix']=$tmp;
                            $tp['path']=$path;
                            $tp['path'][]=sprintf("%s left", $tmp[$i][$j]);
                            $rt[]=$tp;
                            unset($tp);
                        }
                    }
                }
            }
        }
    } catch (Exception $e) {
        //printf("Exception: %s", $e->getMessage());
    }

    return $rt;
}

/* }}} */

/* {{{ function find($puzzle)
 * 递归寻找
 */
function find($puzzle,$moves=0) {
    $rt=false;

    try {
        if (isGoal($puzzle['matrix'])) {  //达到目标
            $rt=$puzzle;
        } else if (false!=($nexts=move($puzzle,$moves))) {
            foreach($nexts as $p) {
                if (false!=($tmp=find($p,$moves))) {   //
                    $rt=$tmp;
                    break;
                }
            }
        } else {
            $rt=false;
        }
    } catch (Exception $e) {
        printf("Exception: %s", $e->getMessage());
    }

    return $rt;
}

/* }}} */


// main
// read from stdin
while($line = fgets(STDIN)){
    if (!empty($line)) {
        list($a, $b, $c)=explode(' ',trim($line));
        $input['matrix'][]=[(int)$a, (int)$b, (int)$c];
    }
}
// 最大移动数, 假设超过这个数字, 基本就没希望了, 设置为数组维度平方*2+1(这个需要后续验证, 3x3维度下这应该是个安全的数)
$maxMoves=count($input['matrix'])*count($input['matrix'])*2+1;

while($moves<$maxMoves && false==$result=find($input,$moves)) {
    $moves++;
    unset($GLOBALS['moved']);
}
if (false!=$result) {
    foreach($result['path'] as $p) {
        printf("%s\n",$p);
    }
} else {
    printf("unsolvable\n");
}

