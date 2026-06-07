# Go Aliyun Snippets

> last_verified: 2025-06

## Table of Contents
- [OSS Upload](#oss-upload)
- [DirectMail (Email)](#directmail-email)

---

## OSS Upload

```go
import (
    "os"
    "github.com/aliyun/aliyun-oss-go-sdk/oss"
)

const (
    OSS_BUCKET_REGION   = "cn-hongkong"
    OSS_BUCKET_ENDPOINT = "https://oss-cn-hongkong.aliyuncs.com"
)

accessKeyId := os.Getenv("ALIYUN_OSS_ACCESS_KEY_ID")
accessKeySecret := os.Getenv("ALIYUN_OSS_ACCESS_KEY_SECRET")

provider, _ := oss.NewEnvironmentVariableCredentialsProvider()
client, _ := oss.New(
    OSS_BUCKET_ENDPOINT,
    accessKeyId,
    accessKeySecret,
    oss.SetCredentialsProvider(&provider),
    oss.Region(OSS_BUCKET_REGION),
    oss.AuthVersion(oss.AuthV4),
)

bucket, _ := client.Bucket("my-bucket")
err := bucket.PutObjectFromFile("assets/file.txt", "./local/file.txt")
```

### Pitfalls
- `AuthVersion(oss.AuthV4)` is required for newer regions (e.g. cn-hongkong).
  Omitting it causes silent auth failures.
- Endpoint must include the full URL scheme (`https://`).

---

## DirectMail (Email)

```go
import (
    "os"
    openapi "github.com/alibabacloud-go/darabonba-openapi/client"
    dm "github.com/alibabacloud-go/dm-20151123/client"
)

accessKeyId := os.Getenv("ALIYUN_EMAIL_ACCESS_KEY_ID")
accessKeySecret := os.Getenv("ALIYUN_EMAIL_ACCESS_KEY_SECRET")

endpoint := "dm.aliyuncs.com"
c, _ := dm.NewClient(&openapi.Config{
    AccessKeyId:     &accessKeyId,
    AccessKeySecret: &accessKeySecret,
    Endpoint:        &endpoint,
})

accountName := "noreply@your-domain.com"
addressType := int32(1)
replyToAddress := false

resp, _ := c.SingleSendMail(&dm.SingleSendMailRequest{
    AccountName:    &accountName,
    AddressType:    &addressType,
    ReplyToAddress: &replyToAddress,
    ToAddress:      core.String("recipient@example.com"),
    Subject:        core.String("Test Email"),
    HtmlBody:       core.String("<h1>Hello</h1>"),
})
```

### Pitfalls
- `AddressType` 1 = batch sending, 0 = triggered. Use 1 for notifications.
- `AccountName` must be a verified sender address in the DirectMail console.
