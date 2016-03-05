// Package main provides 8-puzzle resolver
// reference: https://www.cs.princeton.edu/courses/archive/spr10/cos226/assignments/8puzzle.html
package main

import (
	"bufio"
	"container/heap"
	"errors"
	"fmt"
	"math"
	"os"
	"strconv"
	"strings"
	"time"
)

var push, pop int

// 盘面数据结构, 一个3x3 array
type board [3][3]int

// 目标, 也是一种盘面状态
var Goal board = [3][3]int{{1, 2, 3}, {4, 5, 6}, {7, 8, 0}}

//已经走过的盘面状态
var pass map[float64]int

// 一步
type Step struct {
	Current       board    // 当前布局
	Checksum      float64  // checksum, 每种布局都有唯一值
	InverseNumber int      // 逆序数
	Hamming       int      // 与目标不同的位置总和(越少越好)
	Manhattan     int      // 距离目标的距离总和(越短越好)
	ZeroPos       [2]int   // 0的坐标
	Journey       []string // 旅程, 走过的路(格式为数字+方向, 如数字6向右移动, 为`6 right`), 这个字段的长度也代表depth
	Success       bool     // 是否成功
	index         int      // for heap interface
}

/* {{{ func abs(i int) int
 * math的Abs是float64的，我们只需要int的
 */
func abs(i int) int {
	if i < 0 {
		return -i
	}
	return i
}

/* }}} */

/* {{{ func NewStep(b board) (s *Step,err error)
 * 新建步
 */
func NewStep(b board) (s *Step, err error) {
	s = new(Step)
	s.Current = b
	//计算各种值...
	s.calculate()
	return
}

/* }}} */

/* {{{ func (s *Step) calculate() (err error)
 * 计算各种值
 */
func (s *Step) calculate() (err error) {
	if len(s.Current) == 0 {
		err = errors.New("critical error")
		return
	}
	for i, ns := range s.Current {
		for j, n := range ns {
			// checksum
			s.Checksum += float64(n) * math.Pow10(i*3+j)
			// hamming
			if n != Goal[i][j] {
				s.Hamming++
			}
			// manhattan
			for gi, gns := range Goal {
				for gj, gn := range gns {
					if n == gn {
						s.Manhattan += (abs(i-gi) + abs(j-gj))
					}
				}
			}
			// zero pos
			if n == 0 {
				s.ZeroPos = [2]int{i, j}
			}
			// Inverse number, 求逆序数
			for ii := i*3 + j + 1; ii < 9; ii++ { //从比当前更大的序号开始
				tn := s.Current[ii/3][ii%3]
				if n != 0 && tn != 0 && n > tn { //前面的数大于后面的数, 逆序(注意0应该忽略)
					s.InverseNumber++
				}
			}
		}
	}
	return
}

/* }}} */

/* {{{ func (s *Step) TryMoves()
 * 尝试所有可能移动(push到队列, 忽略已经pass的)
 */
func (s *Step) TryMoves() {
	pass[s.Checksum] = len(s.Journey)
	zi, zj := s.ZeroPos[0], s.ZeroPos[1]
	//左
	if zj-1 >= 0 {
		b := s.Current
		b[zi][zj-1] = 0
		b[zi][zj] = s.Current[zi][zj-1]
		ns, _ := NewStep(b)
		//if depth, ok := pass[ns.Checksum]; !ok || depth > len(s.Journey)+1 {
		if _, ok := pass[ns.Checksum]; !ok {
			md := fmt.Sprintf("%d right", b[zi][zj])
			if len(s.Journey) == 0 {
				ns.Journey = []string{md}
			} else {
				ns.Journey = append(s.Journey, md)
			}
			//fmt.Printf("push: %s, hamming: %d, Manhattan: %d, total: %d\n", ns.Journey, ns.Hamming, ns.Manhattan, ns.Hamming+ns.Manhattan)
			heap.Push(&que, ns)
			push++
		}
	}
	// 上
	if zi-1 >= 0 {
		b := s.Current
		b[zi-1][zj] = 0
		b[zi][zj] = s.Current[zi-1][zj]
		ns, _ := NewStep(b)
		//if depth, ok := pass[ns.Checksum]; !ok || depth > len(s.Journey)+1 {
		if _, ok := pass[ns.Checksum]; !ok {
			md := fmt.Sprintf("%d down", b[zi][zj])
			if len(s.Journey) == 0 {
				ns.Journey = []string{md}
			} else {
				ns.Journey = append(s.Journey, md)
			}
			//fmt.Printf("push: %s, hamming: %d, Manhattan: %d, total: %d\n", ns.Journey, ns.Hamming, ns.Manhattan, ns.Hamming+ns.Manhattan)
			heap.Push(&que, ns)
			push++
		}
	}
	// 右
	if zj+1 < 3 {
		b := s.Current
		b[zi][zj+1] = 0
		b[zi][zj] = s.Current[zi][zj+1]
		ns, _ := NewStep(b)
		//if depth, ok := pass[ns.Checksum]; !ok || depth > len(s.Journey)+1 {
		if _, ok := pass[ns.Checksum]; !ok {
			md := fmt.Sprintf("%d left", b[zi][zj])
			if len(s.Journey) == 0 {
				ns.Journey = []string{md}
			} else {
				ns.Journey = append(s.Journey, md)
			}
			//fmt.Printf("push: %s, hamming: %d, Manhattan: %d, total: %d\n", ns.Journey, ns.Hamming, ns.Manhattan, ns.Hamming+ns.Manhattan)
			heap.Push(&que, ns)
			push++
		}
	}
	// 下
	if zi+1 < 3 {
		b := s.Current
		b[zi+1][zj] = 0
		b[zi][zj] = s.Current[zi+1][zj]
		ns, _ := NewStep(b)
		//if depth, ok := pass[ns.Checksum]; !ok || depth > len(s.Journey)+1 {
		if _, ok := pass[ns.Checksum]; !ok {
			md := fmt.Sprintf("%d up", b[zi][zj])
			if len(s.Journey) == 0 {
				ns.Journey = []string{md}
			} else {
				ns.Journey = append(s.Journey, md)
			}
			//fmt.Printf("push: %s, hamming: %d, Manhattan: %d, total: %d\n", ns.Journey, ns.Hamming, ns.Manhattan, ns.Hamming+ns.Manhattan)
			heap.Push(&que, ns)
			push++
		}
	}
}

/* }}} */

/* {{{ func (s *Step) isGoal() bool
 * 是否目标状态
 */
func (s *Step) isGoal() bool {
	if len(s.Current) == 0 {
		return false
	}
	for i := 0; i < 3; i++ {
		for j := 0; j < 3; j++ {
			if s.Current[i][j] != Goal[i][j] {
				return false
			}
		}
	}
	return true
}

/* }}} */

/* {{{ 队列(priority queue) */
type PQueue []*Step

var que PQueue

// implements heap.Interface
func (pq PQueue) Len() int {
	return len(pq)
}

func (pq PQueue) Less(i, j int) bool {
	// 三个值的和决定优先级
	return pq[i].Hamming+pq[i].Manhattan+len(pq[i].Journey) < pq[j].Hamming+pq[j].Manhattan+len(pq[j].Journey)
}

func (pq PQueue) Swap(i, j int) {
	pq[i], pq[j] = pq[j], pq[i]
	pq[i].index = i
	pq[j].index = j
}

func (pq *PQueue) Push(x interface{}) {
	n := len(*pq)
	step := x.(*Step)
	step.index = n
	*pq = append(*pq, step)
}

func (pq *PQueue) Pop() interface{} {
	old := *pq
	n := len(old)
	step := old[n-1]
	step.index = -1 // for safety
	*pq = old[0 : n-1]
	return step
}

/* }}} */

func main() {
	var initial board
	//从stdin读取, 这里就不判断输入数据是否正确了, 请输入正确的数据!
	bio := bufio.NewReader(os.Stdin)
	for l := 0; l < 3; l++ { //只读三行
		line, _ := bio.ReadString('\n')
		line = strings.TrimSpace(line)
		ls := strings.SplitN(line, " ", 3)
		for lj, s := range ls {
			initial[l][lj], _ = strconv.Atoi(s)
		}
	}
	//从这里开始计时
	begin := time.Now()

	// 初始化队列
	que = make(PQueue, 0)
	heap.Init(&que)

	// 记录已经走过的
	pass = make(map[float64]int)

	// 初始盘面状态
	is, _ := NewStep(initial)
	//fmt.Println("initial Inverse Number: ", is.InverseNumber)
	// push到队列
	heap.Push(&que, is)
	push++

	//目标盘面状态
	gs, _ := NewStep(Goal)
	//fmt.Println("goal Inverse Number: ", gs.InverseNumber)

	if gs.InverseNumber%2 != is.InverseNumber%2 { //不可解
		fmt.Println("unsolvable")
	} else {
		var as *Step // answer step
		for que.Len() > 0 {
			// 出列优先级最高的步
			as = heap.Pop(&que).(*Step)
			pop++
			if as.isGoal() { //成功
				as.Success = true
				break
			}
			// 尝试移动
			as.TryMoves()
		}

		if as != nil && as.Success {
			for _, md := range as.Journey {
				fmt.Println(md)
			}
			fmt.Printf("Total %d step!\n", len(as.Journey))
		} else {
			fmt.Println("something wrong")
		}
	}
	dura := time.Now().Sub(begin).String()
	fmt.Printf("Status: push %d, pop %d\nduration: %s\n", push, pop, dura)
}
