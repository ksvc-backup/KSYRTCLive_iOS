package signature

import (
  "fmt"
  "time"
  "errors"
  "net/url"
  "math/rand"
  "crypto/hmac"
	"crypto/sha1"
  "encoding/base64"
  "strings"
)

const RAND_CHAR string = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

//计算签名的参数集，duration为非必需，其他为必选项
var ARRAY_SIGN_PARAM = []string {"duration", "nonce", "uid", "uniqname"}

//获取随机字符串
func GetRandomString(length int) string {
  bytes := []byte(RAND_CHAR)
  result := []byte{}
  r := rand.New(rand.NewSource(time.Now().UnixNano()))
  for i := 0; i < length; i++ {
    result = append(result, bytes[r.Intn(len(bytes))])
  }
  return string(result)
}

//生成鉴权url，无需传入过期时间expire和随机字符串nonce
func GenAuthParams(accesskey string, secretkey string, uniqname string, uid string) (string, error) {
  expire := time.Now().Unix()
  nonce := GetRandomString(16)
  params := map[string]string {
    "nonce":nonce,
    "uid":uid,
    "uniqname":uniqname,
  }
  if signature, err := GetSignWithParams(accesskey, secretkey, expire, params); err == nil {
    qstr := fmt.Sprintf("accesskey=%s&expire=%d&nonce=%s&uid=%s&uniqname=%s&signature=%s", url.QueryEscape(accesskey), expire, nonce, uid, uniqname, url.QueryEscape(signature))
    return qstr, nil
  } else {
    return "", err
  }
}

//生成签名signature，需要传入过期时间expire和随机串nonce
func GetSignWithParams(accesskey string, secretkey string, expire int64, params map[string]string) (string, error) {
  timestamp := time.Now().Unix()
  tmp := expire - timestamp
  if tmp > 600 || tmp < -600 {
    return "", errors.New("params: invalid expire")
  }
  strToSign := fmt.Sprintf("GET\n%d\n", expire)
  for _, key := range ARRAY_SIGN_PARAM {
    value, ok := params[key]
    /*
    if v == 1 && (!ok || value == "") {
      return "", errors.New("params: invalid " + key)
    }
    */
    if !ok || value == "" {
      continue
    }
    strToSign += fmt.Sprintf("%s=%s", key, value)
    strToSign += "&"
  }
  strToSign = strings.TrimRight(strToSign, "&")
  sign := hmac.New(sha1.New, []byte (secretkey))
  sign.Write([]byte (strToSign))
  signature := base64.StdEncoding.EncodeToString(sign.Sum(nil))
  return signature, nil
}
