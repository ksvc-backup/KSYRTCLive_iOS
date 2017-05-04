package main

import (
	"fmt"
  "net/url"
	"crypto/tls"
	"signature"
	"github.com/astaxie/beego/httplib"
  "time"
  "os"
)

func ReqAuth(qstr string) (string, error) {
  url := "https://rtc.vcloud.ks-live.com:6001/auth?" + qstr
	fmt.Println(url)
  req := httplib.Get(url)
	req.SetTLSClientConfig(&tls.Config{InsecureSkipVerify: true})
  str, err := req.String()
  fmt.Println(str, err)
  return str, err
}

func main() {
  arr := os.Args
	ak := "D8uDWZ88ZKW48/eZHmRm"
  sk := "QtL2SMqgGy15m8WdhJx/X2/cnhMhCWGzS/KPY8z6"
  uniqname := "apptest"
  uid := arr[1]

	fmt.Println("=====================test1=======================")
  //用法一：无需传入expire nonce，返回querystring
  qstr, err := signature.GenAuthParams(ak,sk,uniqname,uid)
	fmt.Println(err)
  ReqAuth(qstr)
  
	fmt.Println("=====================test2=======================")
  //用法一：需要传入expire nonce，返回签名signature
  expire := time.Now().Unix()
  nonce := signature.GetRandomString(16)
  duration := "600"
  params := map[string]string {
    "duration":duration,
    "nonce":nonce,
    "uid":uid,
    "uniqname":uniqname,
  }
  sign, err1 := signature.GetSignWithParams(ak,sk,expire,params)
	fmt.Println(err1)
  qstr1 := fmt.Sprintf("accesskey=%s&expire=%d&duration=%s&nonce=%s&uid=%s&uniqname=%s&signature=%s", url.QueryEscape(ak), expire, duration, nonce, uid, uniqname, url.QueryEscape(sign))
  ReqAuth(qstr1)
}
