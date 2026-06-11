# Python Baidu Translate Snippets

> last_verified: 2026-06 | sdk: Python stdlib urllib

## Text Translate

```python
import hashlib
import json
import os
import random
import string
import time
import urllib.parse
import urllib.request

API_URL = "https://fanyi-api.baidu.com/api/trans/vip/translate"


def baidu_translate(q, from_lang="auto", to_lang="zh"):
    appid = os.environ["BAIDU_TRANSLATE_APP_ID"]
    secret = os.environ["BAIDU_TRANSLATE_SECRET"]
    salt = "".join(random.choices(string.digits + string.ascii_letters, k=10))

    # q is not URL-encoded for signing. urlencode is applied only to HTTP params.
    sign_raw = appid + q + salt + secret
    sign = hashlib.md5(sign_raw.encode("utf-8")).hexdigest()

    params = {
        "q": q,
        "from": from_lang,
        "to": to_lang,
        "appid": appid,
        "salt": salt,
        "sign": sign,
    }
    body = urllib.parse.urlencode(params).encode("utf-8")
    req = urllib.request.Request(
        API_URL,
        data=body,
        headers={"Content-Type": "application/x-www-form-urlencoded"},
    )

    with urllib.request.urlopen(req, timeout=10) as resp:
        result = json.loads(resp.read().decode("utf-8"))

    if "error_code" in result:
        raise RuntimeError(f"{result['error_code']}: {result.get('error_msg', '')}")
    return result["trans_result"]


items = [
    ("Hello, world!", "en", "zh"),
    ("你好，世界！", "zh", "en"),
    ("apple\nbanana\ncherry", "en", "zh"),
]

for i, (text, source, target) in enumerate(items):
    if i:
        time.sleep(1.2)
    print(baidu_translate(text, source, target))
```

### Pitfalls
- Sign with `MD5(appid + q + salt + secret)` using the original UTF-8 `q`.
  Do not URL encode `q` until building the HTTP request, or the API returns
  `54001 Invalid Sign`.
- The API credential is the developer "secret/key", not the Baidu account login
  password. Using a login password also returns `54001 Invalid Sign`.
- Standard tier QPS is 1. Back-to-back smoke tests can return
  `54003 Invalid Access Limit`; sleep a little over one second between calls.
- `to` cannot be `auto`. `from` may be `auto`.
- Multi-line `q` works for independent terms or paragraphs; separate items with
  real newline characters, then let `urlencode` encode the request payload.
