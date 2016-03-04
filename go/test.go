// Package main provides ...
package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

func main() {
	bio := bufio.NewReader(os.Stdin)
	//var line string
	//var err error
	//for err != io.EOF {
	//	line, err = bio.ReadString('\n')
	//	fmt.Print(line)
	//}
	for l := 0; l < 3; l++ { //只读三行
		line, _ := bio.ReadString('\n')
		line = strings.TrimSpace(line)
		fmt.Println(line)
	}
}
