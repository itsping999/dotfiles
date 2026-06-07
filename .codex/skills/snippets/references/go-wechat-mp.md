# Go WeChat Official Account Template Message

> last_verified: 2025-06 | sdk: github.com/silenceper/wechat/v2

## Template Message with Miniprogram Link

```go
import (
    "os"
    "github.com/silenceper/wechat/v2"
    "github.com/silenceper/wechat/v2/cache"
    "github.com/silenceper/wechat/v2/officialaccount/config"
    "github.com/silenceper/wechat/v2/officialaccount/message"
)

appId := os.Getenv("WECHAT_OFFICIAL_ACCOUNT_APP_ID")
appSecret := os.Getenv("WECHAT_OFFICIAL_ACCOUNT_APP_SECRET")
templateId := os.Getenv("WECHAT_OFFICIAL_ACCOUNT_TEMPLATE_ID")
openId := os.Getenv("WECHAT_OFFICIAL_ACCOUNT_OPEN_ID")

client := wechat.Wechat{}
client.SetCache(cache.NewMemory())

template := client.GetOfficialAccount(&config.Config{
    AppID:     appId,
    AppSecret: appSecret,
}).GetTemplate()

data := map[string]*message.TemplateDataItem{
    "thing2": {Value: "测试测试"},
    "time4":  {Value: "2025-04-10 15:00:00"},
    "thing5": {Value: "内部变量_1.是否报警"},
    "const8": {Value: "Alert"},
}

msg := &message.TemplateMessage{
    ToUser:     openId,
    TemplateID: templateId,
    Data:       data,
}
// Optional: link to a miniprogram page instead of a URL
msg.MiniProgram.AppID = os.Getenv("WECHAT_OFFICIAL_ACCOUNT_MINIPROGRAM_APP_ID")
msg.MiniProgram.PagePath = os.Getenv("WECHAT_OFFICIAL_ACCOUNT_MINIPROGRAM_PAGE_PATH")

_, err := template.Send(msg)
```

### Pitfalls
- Template data keys (e.g. `thing2`, `time4`) are defined in the WeChat MP
  backend template — they must match exactly, including the type suffix
  (`thing` = text, `time` = date, `const` = constant).
- `openId` is per-user per-mp — cannot be hardcoded across environments.
- `cache.NewMemory()` is fine for single-request scripts; use Redis cache
  in production to avoid repeated token fetches.
