# Go WebRTC DataChannel via WebSocket

> last_verified: 2025-06 | sdk: github.com/pion/webrtc/v3 + github.com/gorilla/websocket

## WebSocket Signaling Server with DataChannel

```go
import (
    "log"
    "net/http"
    "github.com/gorilla/websocket"
    "github.com/pion/webrtc/v3"
)

var upgrader = websocket.Upgrader{
    CheckOrigin: func(r *http.Request) bool { return true },
}

func serveWs(w http.ResponseWriter, r *http.Request) {
    conn, err := upgrader.Upgrade(w, r, nil)
    if err != nil {
        log.Println("WebSocket upgrade error:", err)
        return
    }
    defer conn.Close()

    var offer webrtc.SessionDescription
    if err := conn.ReadJSON(&offer); err != nil {
        log.Println("Failed to read offer:", err)
        return
    }

    peerConnection, err := webrtc.NewPeerConnection(webrtc.Configuration{})
    if err != nil {
        log.Fatal(err)
    }

    peerConnection.OnDataChannel(func(dc *webrtc.DataChannel) {
        log.Println("New Data Channel:", dc.Label())

        dc.OnOpen(func() {
            log.Println("DataChannel opened")
            dc.SendText("Hello from Go!")
        })

        dc.OnMessage(func(msg webrtc.DataChannelMessage) {
            log.Printf("Received: %s\n", string(msg.Data))
        })
    })

    if err := peerConnection.SetRemoteDescription(offer); err != nil {
        log.Println("SetRemoteDescription error:", err)
        return
    }

    answer, err := peerConnection.CreateAnswer(nil)
    if err != nil {
        log.Println("CreateAnswer error:", err)
        return
    }
    if err := peerConnection.SetLocalDescription(answer); err != nil {
        log.Println("SetLocalDescription error:", err)
        return
    }

    // Wait for ICE gathering before sending answer
    gatherComplete := webrtc.GatheringCompletePromise(peerConnection)
    <-gatherComplete

    if err := conn.WriteJSON(peerConnection.LocalDescription()); err != nil {
        log.Println("WriteJSON error:", err)
    }
}

// Usage:
// http.HandleFunc("/ws", serveWs)
// log.Fatal(http.ListenAndServe(":8080", nil))
```

### Pitfalls
- `GatheringCompletePromise` blocks until all ICE candidates are gathered.
  Without this, the answer sent to the client may lack candidates and fail
  to connect.
- `CheckOrigin: func(r *http.Request) bool { return true }` is permissive —
  restrict in production.
- pion/webrtc v3 uses a different API surface than v4 if upgrading later.
