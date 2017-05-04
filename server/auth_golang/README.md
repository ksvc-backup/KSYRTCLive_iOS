一、鉴权需要的参数:

1.公钥
accesskey
必需
控制台颁发的accesskey/secretkey，开通连麦服务后才能使用

2.过期时间
expire
必需
过期时间戳，以秒为单位，600秒内有效

3.有效期
duration
非必需
鉴权注册的有效时间，设置为0则为注销，该参数目前可以不用设置

4.随机串
nonce
必需
随机生成的字母数字字符串

5.用户ID
uid
必需
用户ID，客户自行保证唯一性，字母数字组成

6.客户号
uniqname
必需
客户开通连麦服务时注册的用户标识，和accesskey/secretkey对应

7.签名
signature
必需


二、签名方式：

1.签名算法
对目标字符串strtosign进行HMAC-SHA1加密得到signature签名，密钥使用accesskey对应的secretkey

2.签名参数
duration:非必需
nonce:必需
uid:必需
uniqname:必需

3.签名过程
目标字符串strtosign如下拼接：
strtosign="GET\n${expire}\n${resource}"
expire即过期时间戳
resource字符串由签名参数以key=value的形式用&号连接而成，连接时以key的字典顺序排列
其中key/value均为未经过urlencode的值，形如：
resource="duration=${duration}&nonce=${nonce}&uid=${uid}&uniqname=${uniqname}"

4.strtosign示例
GET
1493866273
duration=600&nonce=1qazxsw23edc&uid=001&uniqname=apptest
