# Go Payment Gateway Snippets

## Table of Contents
- [Alipay](#alipay)
  - [TradeAppPay](#tradeapppay)
  - [TradePagePay](#tradepagepay)
  - [TradePrecreate (Manual Signing)](#tradeprecreate-manual-signing)
- [WeChat Pay V3](#wechat-pay-v3)
  - [H5 Prepay](#h5-prepay)
  - [App Prepay](#app-prepay)
  - [Native Prepay](#native-prepay)
  - [Notify Callback Handler](#notify-callback-handler)
  - [Notification Decryption Structure](#notification-decryption-structure)
- [ABC Bank (农行)](#abc-bank-农行)
  - [Sign Request (PKCS12 + SHA1withRSA)](#sign-request)
  - [Verify Response](#verify-response)
  - [PayReq (Full Flow)](#payreq-full-flow)

---

## Alipay

> last_verified: 2025-06 | sdk: github.com/smartwalle/alipay/v3

### TradeAppPay

```go
import (
    "os"
    "github.com/smartwalle/alipay/v3"
)

appId := os.Getenv("ALIPAY_APP_ID")

ap := alipay.TradeAppPay{}
ap.Subject = "iPhone16 Pro Max"
ap.OutTradeNo = "9876543211"
ap.TotalAmount = "0.01"
ap.ProductCode = "QUICK_MEDICAL_PAY"
ap.NotifyURL = "https://your-domain.com/notify"

ap.GoodsDetail = []*alipay.GoodsDetail{{
    GoodsId:   "Apple",
    GoodsName: "Red Apple",
    Quantity:  1,
    Price:     0.01,
}}

pk, _ := os.ReadFile("./assets/alipay_private_key.pem")
client, _ := alipay.New(appId, string(pk), true)
result, _ := client.TradeAppPay(ap)
```

### TradePagePay

```go
ap := alipay.TradePagePay{}
ap.Subject = "iPhone16 Pro Max"
ap.OutTradeNo = "9876543212"
ap.TotalAmount = "0.01"
ap.ProductCode = "FAST_INSTANT_TRADE_PAY"
ap.QRPayMode = "4"
ap.QRCodeWidth = "100"
// ... same client init as above
result, _ := client.TradePagePay(ap)
```

### TradePrecreate (Manual Signing)

Use when SDK method does not support custom parameters. Requires manual
RSA2 signature construction.

```go
import (
    "crypto"
    "crypto/rand"
    "crypto/rsa"
    "crypto/x509"
    "encoding/base64"
    "encoding/json"
    "encoding/pem"
    "fmt"
    "io"
    "net/http"
    "net/url"
    "sort"
    "strings"
)

const ALIPAY_OPENAPI_GATEWAY = "https://openapi.alipay.com/gateway.do"

bizContent, _ := json.Marshal(map[string]any{
    "out_trade_no": "987654321",
    "total_amount": "0.01",
    "subject":      "iPhone16 Pro Max",
    "product_code": "QR_CODE_OFFLINE",
})

params := map[string]string{
    "app_id":      appId,
    "method":      "alipay.trade.precreate",
    "charset":     "UTF-8",
    "sign_type":   "RSA2",
    "timestamp":   "2025-01-07 16:05:10",
    "version":     "1.0",
    "format":      "json",
    "biz_content": string(bizContent),
}

// Sort keys and build sign string
keys := make([]string, 0, len(params))
for k := range params {
    keys = append(keys, k)
}
sort.Strings(keys)

sb := strings.Builder{}
values := url.Values{}
for i, k := range keys {
    if params[k] != "" {
        if i > 0 {
            sb.WriteString("&")
        }
        sb.WriteString(k + "=" + params[k])
    }
    values.Set(k, params[k])
}

signature, _ := generateRSA2048Signature(sb.String(), string(pk))
values.Set("sign", signature)

reqUrl := fmt.Sprintf("%s?%s", ALIPAY_OPENAPI_GATEWAY, values.Encode())
resp, _ := http.Post(reqUrl, "application/x-www-form-urlencoded", bytes.NewBuffer([]byte{}))
bodyBytes, _ := io.ReadAll(resp.Body)
```

#### RSA2048 Sign Helper

```go
func generateRSA2048Signature(s string, privateKey string) (string, error) {
    block, _ := pem.Decode([]byte(privateKey))
    if block == nil {
        return "", fmt.Errorf("failed to decode private key")
    }

    var parsedKey *rsa.PrivateKey
    // Try PKCS1 first, then PKCS8
    parsedKey, err := x509.ParsePKCS1PrivateKey(block.Bytes)
    if err != nil {
        pkcs8Key, err := x509.ParsePKCS8PrivateKey(block.Bytes)
        if err != nil {
            return "", err
        }
        var ok bool
        parsedKey, ok = pkcs8Key.(*rsa.PrivateKey)
        if !ok {
            return "", fmt.Errorf("not an RSA private key")
        }
    }

    hashed := crypto.SHA256.New()
    hashed.Write([]byte(s))
    signature, err := rsa.SignPKCS1v15(rand.Reader, parsedKey, crypto.SHA256, hashed.Sum(nil))
    if err != nil {
        return "", err
    }
    return base64.StdEncoding.EncodeToString(signature), nil
}
```

#### Pitfalls
- Alipay uses **RSA2 (SHA256)** for its own APIs, but ABC Bank uses **SHA1withRSA** — do not mix them up.
- `TradePrecreate` via SDK method may not support all custom fields; fall back to manual HTTP + signature when needed.
- Test gateway and production gateway have different URLs.

---

## WeChat Pay V3

> last_verified: 2026-06 | sdk: github.com/wechatpay-apiv3/wechatpay-go@v0.2.20

### H5 Prepay

```go
import (
    "context"
    "os"
    "github.com/wechatpay-apiv3/wechatpay-go/core"
    "github.com/wechatpay-apiv3/wechatpay-go/core/option"
    "github.com/wechatpay-apiv3/wechatpay-go/services/payments/h5"
    "github.com/wechatpay-apiv3/wechatpay-go/utils"
)

appId := os.Getenv("WECHAT_PAY_APP_ID")
mchId := os.Getenv("WECHAT_PAY_MCH_ID")
serialNumber := os.Getenv("WECHAT_PAY_MCH_CERTIFICATE_SERIAL_NUMBER")
apiKey := os.Getenv("WECHAT_PAY_MCH_API_V3_KEY")

pk, _ := utils.LoadPrivateKeyWithPath("./assets/wechatpay_private_key.pem")

client, _ := core.NewClient(context.Background(),
    option.WithWechatPayAutoAuthCipher(mchId, serialNumber, pk, apiKey),
)

svc := h5.H5ApiService{Client: client}
resp, result, _ := svc.Prepay(context.Background(), h5.PrepayRequest{
    Appid:       core.String(appId),
    Mchid:       core.String(mchId),
    Description: core.String("TEST"),
    OutTradeNo:  core.String("12345678910"),
    NotifyUrl:   core.String("https://your-domain.com/notify"),
    Amount:      &h5.Amount{Total: core.Int64(1)},
    SceneInfo: &h5.SceneInfo{
        PayerClientIp: core.String("1.1.1.1"),
        H5Info:        &h5.H5Info{Type: core.String("Wap")},
    },
})
```

### App Prepay

```go
import "github.com/wechatpay-apiv3/wechatpay-go/services/payments/app"

svc := app.AppApiService{Client: client}
resp, result, _ := svc.Prepay(context.Background(), app.PrepayRequest{
    Appid:       core.String(appId),
    Mchid:       core.String(mchId),
    Description: core.String("TEST"),
    OutTradeNo:  core.String("1234567890"),
    NotifyUrl:   core.String("https://your-domain.com/notify"),
    Amount:      &app.Amount{Total: core.Int64(1)},
})
```

### Native Prepay

```go
import "github.com/wechatpay-apiv3/wechatpay-go/services/payments/native"

svc := native.NativeApiService{Client: client}
resp, result, _ := svc.Prepay(context.Background(), native.PrepayRequest{
    Appid:       core.String(appId),
    Mchid:       core.String(mchId),
    Description: core.String("TEST"),
    OutTradeNo:  core.String("001"),
    NotifyUrl:   core.String("https://your-domain.com/notify"),
    Amount:      &native.Amount{Total: core.Int64(1)},
})
```

### Notify Callback Handler

Use when the service only needs to verify and decrypt WeChat Pay V3 callback
notifications, without creating a full `core.Client`.

```go
import (
    "context"
    "fmt"
    "log"
    "net/http"
    "os"

    "github.com/wechatpay-apiv3/wechatpay-go/core/auth/verifiers"
    "github.com/wechatpay-apiv3/wechatpay-go/core/downloader"
    "github.com/wechatpay-apiv3/wechatpay-go/core/notify"
    "github.com/wechatpay-apiv3/wechatpay-go/services/payments"
    "github.com/wechatpay-apiv3/wechatpay-go/utils"
)

func newWechatPayNotifyHandler(ctx context.Context) (*notify.Handler, error) {
    merchantID := os.Getenv("WECHAT_PAY_MCH_ID")
    merchantSerial := os.Getenv("WECHAT_PAY_MCH_CERTIFICATE_SERIAL_NUMBER")
    apiV3Key := os.Getenv("WECHAT_PAY_MCH_API_V3_KEY")
    privateKeyPath := os.Getenv("WECHAT_PAY_PRIVATE_KEY_PATH")

    privateKey, err := utils.LoadPrivateKeyWithPath(privateKeyPath)
    if err != nil {
        return nil, fmt.Errorf("load merchant private key: %w", err)
    }

    err = downloader.MgrInstance().RegisterDownloaderWithPrivateKey(
        ctx,
        privateKey,
        merchantSerial,
        merchantID,
        apiV3Key,
    )
    if err != nil {
        return nil, fmt.Errorf("register certificate downloader: %w", err)
    }

    certificateVisitor := downloader.MgrInstance().GetCertificateVisitor(merchantID)
    return notify.NewNotifyHandler(
        apiV3Key,
        verifiers.NewSHA256WithRSAVerifier(certificateVisitor),
    ), nil
}

func wechatPayNotifyHTTPHandler(handler *notify.Handler) http.HandlerFunc {
    return func(responseWriter http.ResponseWriter, request *http.Request) {
        transaction := new(payments.Transaction)
        notifyRequest, err := handler.ParseNotifyRequest(request.Context(), request, transaction)
        if err != nil {
            log.Printf("wechat pay notify parse failed: %v", err)
            http.Error(responseWriter, "invalid notify", http.StatusBadRequest)
            return
        }

        log.Printf("wechat pay notify ok: summary=%s transaction_id=%v", notifyRequest.Summary, transaction.TransactionId)
        responseWriter.WriteHeader(http.StatusOK)
        _, _ = responseWriter.Write([]byte("success"))
    }
}

func main() {
    handler, err := newWechatPayNotifyHandler(context.Background())
    if err != nil {
        log.Fatalf("wechat pay notify handler init failed: %v", err)
    }
    http.HandleFunc("/api/v1/wechatpay/notify", wechatPayNotifyHTTPHandler(handler))
    log.Fatal(http.ListenAndServe(":8080", nil))
}
```

#### Pitfalls
- Do not read `request.Body` before `ParseNotifyRequest`; it is an `io.Reader`
  and signature verification will fail after the body has been consumed.
- Register the certificate downloader during service startup. Re-registering on
  every callback is unnecessary and can add avoidable latency/failure points.
- Keep `WECHAT_PAY_MCH_API_V3_KEY`, merchant ID, serial number, and private key
  path in env/config. Do not hardcode them in callback code or snippets.
- Return HTTP 200 with body `success` only after signature verification,
  decryption, and idempotent business processing succeed.

### Notification Decryption Structure

```go
type WechatPayNotification struct {
    ID           string    `json:"id"`
    CreateTime   time.Time `json:"create_time"`
    ResourceType string    `json:"resource_type"`
    EventType    string    `json:"event_type"`
    Summary      string    `json:"summary"`
    Resource     struct {
        OriginalType   string `json:"original_type"`
        Algorithm      string `json:"algorithm"`       // AEAD_AES_256_GCM
        Ciphertext     string `json:"ciphertext"`
        AssociatedData string `json:"associated_data"`
        Nonce          string `json:"nonce"`
    } `json:"resource"`
}
```

#### Pitfalls
- WeChat Pay V3 uses **AEAD_AES_256_GCM** for notification decryption, not RSA.
- `NotifyUrl` must be HTTPS and publicly accessible for production.
- The `apiKey` (APIv3 key) is different from the merchant private key.
- For standard transaction callbacks, parse decrypted content into
  `payments.Transaction`; use a custom struct or `map[string]any` only when the
  SDK has no matching model.

---

## ABC Bank (农行)

> last_verified: 2025-06 | cert format: PKCS12 (.pfx)

### Sign Request

ABC Bank requires **SHA1withRSA** signing with a PKCS12 merchant certificate.
The message body must be **GBK-encoded** before signing.

```go
import (
    "crypto"
    "crypto/rand"
    "crypto/rsa"
    "crypto/sha1"
    "encoding/base64"
    "errors"
    "os"
    "golang.org/x/text/encoding/simplifiedchinese"
    "software.sslmate.com/src/go-pkcs12"
)

func calculateSignature(p12Data []byte, password string, message []byte) (string, error) {
    pk, _, err := extractPrivateKey(p12Data, password)
    if err != nil {
        return "", err
    }
    hashed := sha1.Sum(message)
    signature, err := rsa.SignPKCS1v15(rand.Reader, pk, crypto.SHA1, hashed[:])
    if err != nil {
        return "", err
    }
    return base64.StdEncoding.EncodeToString(signature), nil
}

func extractPrivateKey(p12Data []byte, password string) (*rsa.PrivateKey, *x509.Certificate, error) {
    privKey, cert, err := pkcs12.Decode(p12Data, password)
    if err != nil {
        return nil, nil, err
    }
    rsaKey, ok := privKey.(*rsa.PrivateKey)
    if !ok {
        return nil, nil, errors.New("private key is not RSA")
    }
    return rsaKey, cert, nil
}
```

### Verify Response

```go
func verifyResponse(signatureBase64 string, message, trustPayCert []byte) (bool, error) {
    cert, err := parseX509Cert(trustPayCert)
    if err != nil {
        return false, err
    }
    pubKey, ok := cert.PublicKey.(*rsa.PublicKey)
    if !ok {
        return false, fmt.Errorf("public key is not RSA")
    }
    signature, err := base64.StdEncoding.DecodeString(signatureBase64)
    if err != nil {
        return false, err
    }

    // MUST GBK-encode the message before hashing
    gbkEncoder := simplifiedchinese.GBK.NewEncoder()
    msgBytes, err := gbkEncoder.Bytes(message)
    if err != nil {
        return false, err
    }

    hash := sha1.Sum(msgBytes)
    err = rsa.VerifyPKCS1v15(pubKey, crypto.SHA1, hash[:], signature)
    if err != nil {
        return false, nil
    }
    return true, nil
}

func parseX509Cert(data []byte) (*x509.Certificate, error) {
    block, _ := pem.Decode(data)
    if block != nil {
        return x509.ParseCertificate(block.Bytes)
    }
    return x509.ParseCertificate(data)
}
```

### PayReq (Full Flow)

```go
merchant := &Merchant{MerchantID: merchantId, ECMerchantType: "EBUS"}
order := &Order{
    PayTypeID:   "ImmediatePay",
    OrderDate:   time.Now().Format("2005/01/02"),
    OrderTime:   time.Now().Format("15:04:05"),
    OrderNo:     "TEST-20250417141600",
    OrderAmount: "0.01",
    BuyIP:       publicIP,
    OrderItems:  []*OrderItem{{ProductName: "TEST-PRODUCT"}},
}
trxRequest := &TrxRequest{
    TrxType:         "PayReq",
    PaymentType:     "1",
    PaymentLinkType: "1",
    NotifyType:      "0",
    ResultNotifyURL: "https://your-domain.com/notify",
    Order:           order,
}
message := &Message{
    Version:    "V3.0.0",
    Format:     "JSON",
    Merchant:   merchant,
    TrxRequest: trxRequest,
}

certData, _ := os.ReadFile("./assets/abc_pay_merchant_cert.pfx")
messageBytes, _ := json.Marshal(message)
signature, _ := calculateSignature(certData, password, messageBytes)

request := Request{
    SignatureAlgorithm: "SHA1withRSA",
    Message:            message,
    Signature:          signature,
}
requestBytes, _ := json.Marshal(request)

resp, _ := http.Post(
    "https://pay.test.abchina.com/ebusold/trustpay/ReceiveMerchantTrxReqServlet",
    "application/json",
    bytes.NewBuffer(requestBytes),
)
```

#### Pitfalls
- **GBK encoding is mandatory** for signature verification. UTF-8 will cause
  `VerifyPKCS1v15` to fail silently (returns error, not panic).
- ABC uses **SHA1withRSA**, not SHA256. This is different from Alipay's RSA2.
- Certificate is PKCS12 (.pfx) format — use `go-pkcs12`, not `x509.ParseCertificate`.
- The certificate password comes from env var, never hardcode it.
